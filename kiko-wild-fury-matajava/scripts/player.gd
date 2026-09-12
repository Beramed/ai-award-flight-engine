extends CharacterBody2D
class_name PlayerKiko

const SPEED := 118.0
const JUMP_VELOCITY := -332.0
const GRAVITY := 820.0

signal died

var facing := 1
var aim := Vector2.RIGHT
var invuln := 0.0
var shoot_cd := 0.0
var grenade_cd := 0.0
var melee_t := 0.0
var rage_t := 0.0
var crouching := false
var locked := false
var spawn_point := Vector2.ZERO

@onready var anim: AnimatedSprite2D = $Anim
@onready var col: CollisionShape2D = $Collision
@onready var melee_box: Area2D = $Melee
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	add_to_group("player")
	spawn_point = global_position
	anim.sprite_frames = SpriteLib.kiko_frames()
	anim.play("idle")
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _physics_process(delta: float) -> void:
	if GameState.paused_by_dialog or locked:
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	invuln = max(0.0, invuln - delta)
	shoot_cd = max(0.0, shoot_cd - delta)
	grenade_cd = max(0.0, grenade_cd - delta)
	melee_t = max(0.0, melee_t - delta)
	if rage_t > 0.0:
		rage_t -= delta
		modulate = Color(1.2, 0.7, 0.7)
	else:
		modulate = Color(1, 1, 1)

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var x := Input.get_axis("move_left", "move_right")
	crouching = is_on_floor() and Input.is_action_pressed("aim_down")
	if crouching:
		x = 0.0
		var crouch_shape := col.shape as RectangleShape2D
		if crouch_shape:
			crouch_shape.size = Vector2(14, 22)
		col.position.y = 5
	else:
		var stand_shape := col.shape as RectangleShape2D
		if stand_shape:
			stand_shape.size = Vector2(14, 32)
		col.position.y = 0

	if x != 0.0:
		facing = 1 if x > 0.0 else -1
		anim.flip_h = facing < 0
	velocity.x = x * SPEED

	if Input.is_action_just_pressed("jump") and is_on_floor() and not crouching:
		velocity.y = JUMP_VELOCITY

	_update_aim()

	if Input.is_action_just_pressed("weapon_next"):
		GameState.cycle_weapon()
	if Input.is_action_just_pressed("rage"):
		_try_rage()
	if Input.is_action_just_pressed("grenade"):
		_throw_grenade()
	if Input.is_action_pressed("shoot"):
		_try_attack()

	_play_anim(x)
	move_and_slide()
	_clamp_camera_left()
	muzzle.position = Vector2(16 * facing, -6 if not crouching else 4)
	if aim.y < -0.4:
		muzzle.position = Vector2(4 * facing, -20)
	$Melee/CollisionShape2D.position.x = 16 * facing


func _update_aim() -> void:
	var up := Input.is_action_pressed("aim_up")
	var down := Input.is_action_pressed("aim_down")
	var left := Input.is_action_pressed("move_left")
	var right := Input.is_action_pressed("move_right")
	aim = Vector2(facing, 0)
	if up and not down:
		if left or right:
			aim = Vector2(facing, -1).normalized()
		else:
			aim = Vector2(0, -1)
	elif down and not is_on_floor():
		if left or right:
			aim = Vector2(facing, 1).normalized()
		else:
			aim = Vector2(0, 1)
	elif crouching:
		aim = Vector2(facing, 0)


func _try_attack() -> void:
	if melee_t > 0.0:
		return
	if rage_t > 0.0 or _enemy_in_melee():
		_do_melee()
		return
	_shoot()


func _enemy_in_melee() -> bool:
	for body in melee_box.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			var dx: float = body.global_position.x - global_position.x
			if sign(dx) == facing or abs(dx) < 12.0:
				return true
	return false


func _do_melee() -> void:
	melee_t = 0.22
	anim.play("rage" if rage_t > 0.0 else "melee")
	for body in melee_box.get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(3 if rage_t > 0.0 else 2, Vector2(facing * 180, -40))
	GameState.add_rage(2.0)


func _shoot() -> void:
	var stats: Dictionary = GameState.weapon_stats[GameState.current_weapon]
	if shoot_cd > 0.0:
		return
	if not GameState.consume_shot():
		return
	shoot_cd = stats["cooldown"]
	anim.play("shoot_up" if aim.y < -0.5 else "shoot")
	var pellets: int = stats["pellets"]
	for i in pellets:
		var spread := deg_to_rad(stats["spread"]) * (i - (pellets - 1) / 2.0)
		var dir := aim.rotated(spread)
		if dir == Vector2.ZERO:
			dir = Vector2(facing, 0)
		_spawn_bullet(dir.normalized(), stats)
	GameState.add_rage(0.4)


func _spawn_bullet(dir: Vector2, stats: Dictionary) -> void:
	var b := preload("res://scenes/bullet.tscn").instantiate()
	b.global_position = muzzle.global_position
	b.setup(dir, stats["speed"], stats["damage"], stats["piercing"], GameState.current_weapon)
	get_tree().current_scene.add_child(b)


func _throw_grenade() -> void:
	if grenade_cd > 0.0:
		return
	if not GameState.consume_grenade():
		return
	grenade_cd = 0.55
	var g := preload("res://scenes/grenade.tscn").instantiate()
	g.global_position = global_position + Vector2(facing * 10, -10)
	g.setup(Vector2(facing * 190, -230))
	get_tree().current_scene.add_child(g)


func _try_rage() -> void:
	if rage_t > 0.0:
		return
	if GameState.rage < 60.0:
		return
	GameState.rage = 0.0
	GameState.rage_changed.emit(0.0, GameState.MAX_RAGE)
	rage_t = 10.0
	invuln = 10.0


func take_hit(amount: int = 1, knock := Vector2.ZERO) -> void:
	if invuln > 0.0 or rage_t > 0.0:
		return
	invuln = 1.1
	velocity += knock
	anim.play("hurt")
	var dead := GameState.hit_player(amount)
	if dead:
		_die()


func _die() -> void:
	locked = true
	anim.play("death")
	died.emit()
	await get_tree().create_timer(1.1).timeout
	if GameState.lives <= 0:
		get_tree().reload_current_scene()
		return
	global_position = spawn_point
	locked = false
	invuln = 1.5
	GameState.hp = GameState.MAX_HP
	GameState.hp_changed.emit(GameState.hp, GameState.MAX_HP)


func _play_anim(x: float) -> void:
	if melee_t > 0.0 or anim.animation in ["hurt", "death"] and anim.is_playing():
		return
	if rage_t > 0.0 and Input.is_action_pressed("shoot"):
		anim.play("rage")
		return
	if not is_on_floor():
		anim.play("jump")
	elif crouching:
		anim.play("crouch")
	elif Input.is_action_pressed("shoot"):
		anim.play("shoot_up" if aim.y < -0.5 else "shoot")
	elif abs(x) > 0.1:
		anim.play("walk")
	else:
		anim.play("idle")
	anim.flip_h = facing < 0


func _clamp_camera_left() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var left := cam.limit_left + 16
	if global_position.x < left:
		global_position.x = left
		velocity.x = max(velocity.x, 0.0)
