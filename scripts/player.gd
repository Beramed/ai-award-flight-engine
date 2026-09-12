extends CharacterBody2D
class_name PlayerKiko

const SPEED := 118.0
const JUMP_VELOCITY := -332.0
const GRAVITY := 820.0

signal died

@export var player_index := 0

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
var _capture_frames := 0

@onready var anim: AnimatedSprite2D = $Anim
@onready var col: CollisionShape2D = $Collision
@onready var melee_box: Area2D = $Melee
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	add_to_group("player")
	if player_index == 0:
		add_to_group("player1")
	else:
		add_to_group("player2")
		var cam_node := get_node_or_null("Camera") as Camera2D
		if cam_node:
			cam_node.enabled = false
	spawn_point = global_position
	anim.sprite_frames = SpriteLib.kiko_frames()
	anim.play("idle")
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _ia(action: String) -> String:
	if player_index == 0:
		return action
	return "p2_" + action


func _physics_process(delta: float) -> void:
	if GameState.paused_by_dialog or locked:
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		if OS.get_environment("KIKO_CAPTURE") != "":
			_run_capture()
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

	var x := Input.get_axis(_ia("move_left"), _ia("move_right"))
	crouching = is_on_floor() and Input.is_action_pressed(_ia("aim_down"))
	if crouching:
		x = 0.0
		var crouch_shape := col.shape as RectangleShape2D
		if crouch_shape:
			crouch_shape.size = Vector2(18, 26)
		col.position.y = 8
	else:
		var stand_shape := col.shape as RectangleShape2D
		if stand_shape:
			stand_shape.size = Vector2(18, 42)
		col.position.y = 0

	if x != 0.0:
		facing = 1 if x > 0.0 else -1
		anim.flip_h = facing < 0
	velocity.x = x * SPEED

	if Input.is_action_just_pressed(_ia("jump")) and is_on_floor() and not crouching:
		velocity.y = JUMP_VELOCITY

	_update_aim()

	if Input.is_action_just_pressed("weapon_next") and player_index == 0:
		GameState.cycle_weapon()
	if Input.is_action_just_pressed(_ia("rage")):
		_try_rage()
	if Input.is_action_just_pressed("grenade") and player_index == 0:
		_throw_grenade()
	if Input.is_action_pressed(_ia("shoot")):
		_try_attack()

	_play_anim(x)
	move_and_slide()
	_clamp_camera_left()
	muzzle.position = Vector2(36 * facing, -20 if not crouching else -14)
	if aim.y < -0.4:
		muzzle.position = Vector2(12 * facing, -36)
	if not is_on_floor():
		muzzle.position = Vector2(36 * facing, -22)
	$Melee/CollisionShape2D.position.x = 24 * facing
	$Melee/CollisionShape2D.position.y = -8
	if OS.get_environment("KIKO_CAPTURE") != "":
		_run_capture()


func _run_capture() -> void:
	_capture_frames += 1
	var cap := OS.get_environment("KIKO_CAPTURE")
	if _capture_frames == 10:
		GameState.score = 24500
		GameState.score_changed.emit(GameState.score)
		GameState.add_rage(80.0)
		get_viewport().get_texture().get_image().save_png(cap + "/hud_arcade.png")
	elif _capture_frames < 16:
		velocity.x = SPEED
		anim.play("walk")
	elif _capture_frames == 16:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_walk.png")
	elif _capture_frames < 34:
		GameState.current_weapon = "pistola"
		_shoot()
		anim.play("shoot_pistola")
	elif _capture_frames == 34:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_revolver.png")
	elif _capture_frames < 52:
		GameState.current_weapon = "fuzil"
		_shoot()
		anim.play("shoot_fuzil")
	elif _capture_frames == 52:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_fuzil.png")
	elif _capture_frames < 70:
		GameState.current_weapon = "doze"
		_shoot()
		anim.play("shoot_doze")
	elif _capture_frames == 70:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_shotgun.png")
		velocity.y = JUMP_VELOCITY
	elif _capture_frames < 88:
		GameState.current_weapon = "fuzil"
		_shoot()
		anim.play("jump_shoot_fuzil")
	elif _capture_frames == 88:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_jump_shoot.png")
		GameState.current_weapon = "fuzil"
		anim.play("melee_fuzil")
	elif _capture_frames == 94:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_melee.png")
		GameState.current_weapon = "pistola"
		anim.play("melee_pistola")
	elif _capture_frames == 100:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_melee_revolver.png")
		GameState.current_weapon = "doze"
		anim.play("melee_doze")
	elif _capture_frames == 106:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_melee_shotgun.png")
		_throw_grenade()
	elif _capture_frames == 118:
		get_viewport().get_texture().get_image().save_png(cap + "/hud_grenade.png")
		GameState.rage = 80.0
		GameState.rage_changed.emit(GameState.rage, GameState.MAX_RAGE)
		invuln = 0.0
		take_hit(1, Vector2(-40, -60))
	elif _capture_frames == 128:
		get_viewport().get_texture().get_image().save_png(cap + "/hud_hurt.png")
		invuln = 0.0
		take_hit(1, Vector2(-20, -40))
	elif _capture_frames == 140:
		get_viewport().get_texture().get_image().save_png(cap + "/hud_hurt2.png")
		invuln = 0.0
		take_hit(1, Vector2(-10, -20))
	elif _capture_frames == 158:
		get_viewport().get_texture().get_image().save_png(cap + "/hud_death.png")


func _update_aim() -> void:
	var up := Input.is_action_pressed(_ia("aim_up"))
	var down := Input.is_action_pressed(_ia("aim_down"))
	var left := Input.is_action_pressed(_ia("move_left"))
	var right := Input.is_action_pressed(_ia("move_right"))
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
			if sign(dx) == facing or abs(dx) < 18.0:
				return true
	return false


func _do_melee() -> void:
	melee_t = 0.34
	if rage_t > 0.0:
		anim.play("rage")
	else:
		var key := "melee_%s" % GameState.current_weapon
		anim.play(key if anim.sprite_frames.has_animation(key) else "melee")
	for body in melee_box.get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(4 if rage_t > 0.0 else 3, Vector2(facing * 200, -50))


func _shoot() -> void:
	var stats: Dictionary = GameState.weapon_stats[GameState.current_weapon]
	if shoot_cd > 0.0:
		return
	if not GameState.consume_shot():
		return
	shoot_cd = stats["cooldown"]
	anim.play(_shoot_anim_name())
	_spawn_muzzle_fx()
	if GameState.current_weapon in ["pistola", "doze"] or randf() < 0.35:
		_spawn_casing()
	var pellets: int = stats["pellets"]
	for i in pellets:
		var spread := deg_to_rad(stats["spread"]) * (i - (pellets - 1) / 2.0)
		var dir := aim.rotated(spread)
		if dir == Vector2.ZERO:
			dir = Vector2(facing, 0)
		_spawn_bullet(dir.normalized(), stats)


func _shoot_anim_name() -> String:
	var weapon := GameState.current_weapon
	var air := not is_on_floor()
	if air:
		if weapon == "fuzil":
			return "jump_shoot_fuzil"
		return "jump_shoot"
	if weapon == "pistola":
		return "shoot_pistola"
	if weapon == "fuzil":
		return "shoot_fuzil"
	if weapon == "doze":
		return "shoot_doze"
	if aim.y < -0.5:
		return "shoot_up"
	return "shoot"


func _spawn_bullet(dir: Vector2, stats: Dictionary) -> void:
	var b := preload("res://scenes/bullet.tscn").instantiate()
	b.global_position = muzzle.global_position
	b.setup(dir, stats["speed"], stats["damage"], stats["piercing"], GameState.current_weapon)
	b.life = float(stats.get("life", 1.4))
	b.apply_scale_factor(float(stats.get("scale", 1.0)))
	get_tree().current_scene.add_child(b)


func _spawn_muzzle_fx() -> void:
	var tex_name := ""
	match GameState.current_weapon:
		"pistola":
			tex_name = "muzzle_revolver"
		"fuzil":
			tex_name = "muzzle_fuzil"
		"doze":
			tex_name = "shotgun_blast"
		_:
			return
	var tex := SpriteLib.fx(tex_name)
	if tex == null:
		return
	var flash := Sprite2D.new()
	flash.texture = tex
	flash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flash.centered = true
	flash.position = muzzle.position + Vector2(10 * facing, 0)
	flash.flip_h = facing < 0
	match GameState.current_weapon:
		"doze":
			flash.scale = Vector2(0.42, 0.42)
		"fuzil":
			flash.scale = Vector2(0.32, 0.32)
		_:
			flash.scale = Vector2(0.58, 0.58)
	add_child(flash)
	var tw := create_tween()
	tw.tween_interval(0.06)
	tw.tween_property(flash, "modulate:a", 0.0, 0.08)
	tw.tween_callback(flash.queue_free)


func _spawn_casing() -> void:
	var tex := SpriteLib.fx("casing")
	if tex == null:
		return
	var casing := preload("res://scenes/casing.tscn").instantiate()
	casing.global_position = global_position + Vector2(facing * 4, -16)
	casing.setup(tex, facing)
	get_tree().current_scene.add_child(casing)


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


func take_hit(_amount: int = 1, knock := Vector2.ZERO) -> void:
	if invuln > 0.0 or rage_t > 0.0:
		return
	invuln = 1.1
	velocity += knock
	var dead := GameState.hit_player(1)
	if dead:
		_die()
	else:
		anim.play("hurt")


func _die() -> void:
	locked = true
	anim.play("death")
	died.emit()
	await get_tree().create_timer(1.25).timeout
	GameState.lose_life()
	if GameState.lives <= 0:
		if GameState.use_continue():
			global_position = spawn_point
			locked = false
			invuln = 1.5
			return
		get_tree().change_scene_to_file("res://scenes/title.tscn")
		return
	global_position = spawn_point
	locked = false
	invuln = 1.5


func _play_anim(x: float) -> void:
	if melee_t > 0.0 or (anim.animation in ["hurt", "death"] and anim.is_playing()):
		return
	if rage_t > 0.0 and Input.is_action_pressed(_ia("shoot")):
		anim.play("rage")
		return
	if Input.is_action_pressed(_ia("shoot")):
		anim.play(_shoot_anim_name())
	elif not is_on_floor():
		anim.play("jump")
	elif crouching:
		anim.play("crouch")
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
