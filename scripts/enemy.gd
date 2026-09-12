extends CharacterBody2D
class_name EnemyBase

const GRAVITY := 820.0

var enemy_id := "javali_corredor"
var hp := 3
var speed := 70.0
var facing := -1
var kind := "charger"
var dead := false
var attack_cd := 0.0
var armored := false
var airborne := false
var ai_phase := "move"
var ai_t := 0.0
var hover_y := 0.0
var touch_dmg := 1

@onready var anim: AnimatedSprite2D = $Anim
@onready var col: CollisionShape2D = $Collision


func setup(p_id: String, p_facing: int = -1) -> void:
	enemy_id = p_id
	facing = p_facing
	var data := Roteiro.inimigo(p_id)
	hp = int(round(float(data.get("hp", 3)) * GameState.hp_scale()))
	speed = float(data.get("speed", 70)) * GameState.speed_scale()
	kind = String(data.get("kind", "charger"))
	armored = bool(data.get("armor", false))
	airborne = bool(data.get("airborne", false))
	touch_dmg = int(data.get("touch", 1))
	scale = Vector2.ONE * float(data.get("scale", 1.0))
	match kind:
		"bird":
			anim.sprite_frames = SpriteLib.passaro_frames()
		"drone":
			anim.sprite_frames = SpriteLib.drone_frames()
		_:
			anim.sprite_frames = SpriteLib.javali_frames()
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.flip_h = facing < 0
	add_to_group("enemies")
	var shape := col.shape as RectangleShape2D
	if airborne:
		collision_mask = 0
		if shape:
			shape.size = Vector2(22, 16)
		col.position.y = 0
		hover_y = global_position.y
		anim.play("fly")
	elif kind == "thrower":
		anim.play("throw")
	elif kind == "armored":
		anim.play("blindado")
		modulate = Color(0.75, 0.8, 0.9)
	else:
		anim.play("charge")


func _physics_process(delta: float) -> void:
	if dead or GameState.paused_by_dialog:
		return
	attack_cd = max(0.0, attack_cd - delta)
	ai_t = max(0.0, ai_t - delta)
	if airborne:
		_ai_air(delta)
		move_and_slide()
		_touch_distance()
		if global_position.x < -80.0 or global_position.x > 5800.0:
			queue_free()
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	match kind:
		"thrower":
			_ai_thrower()
		"jumper":
			_ai_jumper()
		"armored":
			_ai_armored()
		_:
			_ai_charger()
	move_and_slide()
	_touch_player()
	if global_position.y > 420:
		queue_free()


func _ai_charger() -> void:
	var player := _player()
	if player:
		facing = 1 if player.global_position.x > global_position.x else -1
	anim.flip_h = facing < 0
	if ai_phase == "charge":
		velocity.x = facing * speed * 2.35
		anim.play("charge")
		if ai_t <= 0.0:
			ai_phase = "recover"
			ai_t = 0.45
		return
	if ai_phase == "recover":
		velocity.x = facing * speed * 0.35
		if ai_t <= 0.0:
			ai_phase = "move"
		return
	velocity.x = facing * speed
	anim.play("run" if anim.sprite_frames.has_animation("run") else "charge")
	if player and abs(player.global_position.x - global_position.x) < 110.0 and attack_cd <= 0.0:
		ai_phase = "charge"
		ai_t = 0.48
		attack_cd = 1.35


func _ai_thrower() -> void:
	var player := _player()
	if player:
		facing = 1 if player.global_position.x > global_position.x else -1
	anim.flip_h = facing < 0
	if ai_phase == "throw":
		velocity.x = 0.0
		anim.play("throw")
		if ai_t <= 0.22 and attack_cd <= 0.05:
			_spawn_rock(Vector2(facing * 120.0, -210.0))
			attack_cd = 1.6
		if ai_t <= 0.0:
			ai_phase = "move"
		return
	var dist := 999.0
	if player:
		dist = abs(player.global_position.x - global_position.x)
	if dist < 100.0:
		velocity.x = -facing * speed
	elif dist > 190.0:
		velocity.x = facing * speed * 0.85
	else:
		velocity.x = 0.0
		if attack_cd <= 0.0:
			ai_phase = "throw"
			ai_t = 0.55
	if velocity.x != 0.0:
		anim.play("throw")


func _ai_jumper() -> void:
	var player := _player()
	if player:
		facing = 1 if player.global_position.x > global_position.x else -1
	velocity.x = facing * speed
	anim.flip_h = facing < 0
	if is_on_floor() and attack_cd <= 0.0:
		velocity.y = -240
		attack_cd = 1.4
		anim.play("jump" if anim.sprite_frames.has_animation("jump") else "charge")
	elif is_on_floor():
		anim.play("run")


func _ai_armored() -> void:
	var player := _player()
	if player:
		facing = 1 if player.global_position.x > global_position.x else -1
	velocity.x = facing * (speed * 0.7)
	anim.flip_h = facing < 0
	anim.play("blindado")


func _ai_air(delta: float) -> void:
	var player := _player()
	if player and kind == "drone":
		facing = 1 if player.global_position.x > global_position.x else -1
	velocity.x = facing * speed
	global_position.y = lerp(global_position.y, hover_y + sin(Time.get_ticks_msec() * 0.004) * 6.0, 0.2)
	velocity.y = 0.0
	anim.flip_h = facing < 0
	if ai_phase == "drop":
		anim.play("drop")
		if ai_t <= 0.18 and attack_cd <= 0.04:
			if kind == "bird":
				_spawn_rock(Vector2(0.0, 40.0))
			attack_cd = 1.7
		if ai_t <= 0.0:
			ai_phase = "move"
		return
	anim.play("fly")
	if kind == "bird" and attack_cd <= 0.0:
		ai_phase = "drop"
		ai_t = 0.5


func _spawn_rock(impulse: Vector2) -> void:
	var rock := preload("res://scenes/rock.tscn").instantiate()
	rock.global_position = global_position + Vector2(facing * 8, -6 if not airborne else 10)
	get_tree().current_scene.add_child(rock)
	rock.setup(impulse)


func take_hit(amount: int, knock := Vector2.ZERO) -> void:
	if dead:
		return
	if armored and amount < 2:
		modulate = Color(1.4, 1.4, 1.6)
		await get_tree().create_timer(0.08).timeout
		modulate = Color(0.75, 0.8, 0.9)
		return
	hp -= amount
	velocity += knock * 0.35
	if hp <= 0:
		_die()


func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	var death := "die_forward"
	if kind == "bird" or kind == "drone":
		death = "drop" if anim.sprite_frames.has_animation("drop") else "fly"
	elif randf() < 0.5 and anim.sprite_frames.has_animation("die_flip"):
		death = "die_flip"
	elif anim.sprite_frames.has_animation("die_forward"):
		death = "die_forward"
	elif anim.sprite_frames.has_animation("die"):
		death = "die"
	anim.play(death)
	var data := Roteiro.inimigo(enemy_id)
	GameState.add_score(int(data.get("score", 100)))
	GameState.add_kill_rage(is_in_group("boss"))
	GameState.add_coins(5)
	collision_layer = 0
	collision_mask = 0
	if kind == "drone":
		_drop_loot()
	await get_tree().create_timer(0.85 if not airborne else 0.45).timeout
	if kind != "drone":
		_drop_coin()
	queue_free()


func _drop_loot() -> void:
	var kinds := ["municao", "granadas", "seringa"]
	var p := preload("res://scenes/pickup.tscn").instantiate()
	p.global_position = global_position + Vector2(0, 8)
	p.setup(kinds[randi() % kinds.size()])
	get_tree().current_scene.add_child(p)


func _drop_coin() -> void:
	var p := preload("res://scenes/pickup.tscn").instantiate()
	p.global_position = global_position + Vector2(0, -8)
	p.setup("coin")
	get_tree().current_scene.add_child(p)


func _touch_player() -> void:
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var n := hit.get_collider()
		if n and n.is_in_group("player") and n.has_method("take_hit"):
			n.take_hit(touch_dmg, Vector2(-facing * 140, -80))


func _touch_distance() -> void:
	var player := _player()
	if player and player.has_method("take_hit") and global_position.distance_to(player.global_position) < 18.0:
		player.take_hit(touch_dmg, Vector2(0, 40))


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")
