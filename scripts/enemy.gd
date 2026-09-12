extends CharacterBody2D
class_name EnemyBase

const GRAVITY := 820.0

var enemy_id := "javali_corredor"
var hp := 3
var speed := 70.0
var facing := -1
var kind := "runner"
var dead := false
var attack_cd := 0.0
var armored := false

@onready var anim: AnimatedSprite2D = $Anim


func setup(p_id: String, p_facing: int = -1) -> void:
	enemy_id = p_id
	facing = p_facing
	var data := Roteiro.inimigo(p_id)
	hp = int(round(float(data.get("hp", 3)) * GameState.hp_scale()))
	speed = float(data.get("speed", 70)) * GameState.speed_scale()
	kind = String(data.get("kind", "runner"))
	armored = bool(data.get("armor", false))
	scale = Vector2.ONE * float(data.get("scale", 1.0))
	anim.sprite_frames = SpriteLib.javali_frames()
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.flip_h = facing > 0
	if kind == "armored":
		anim.play("blindado")
		modulate = Color(0.75, 0.8, 0.9)
	else:
		anim.play("run")
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if dead or GameState.paused_by_dialog:
		return
	attack_cd = max(0.0, attack_cd - delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	match kind:
		"jumper":
			_ai_jumper()
		"armored":
			_ai_armored()
		_:
			_ai_runner()
	move_and_slide()
	_touch_player()
	if global_position.y > 420:
		queue_free()


func _ai_runner() -> void:
	var player := _player()
	if player:
		facing = 1 if player.global_position.x > global_position.x else -1
	velocity.x = facing * speed
	anim.flip_h = facing > 0
	anim.play("run")


func _ai_jumper() -> void:
	var player := _player()
	if player:
		facing = 1 if player.global_position.x > global_position.x else -1
	velocity.x = facing * speed
	anim.flip_h = facing > 0
	if is_on_floor() and attack_cd <= 0.0:
		velocity.y = -240
		attack_cd = 1.4
		anim.play("jump")
	elif is_on_floor():
		anim.play("run")


func _ai_armored() -> void:
	var player := _player()
	if player:
		facing = 1 if player.global_position.x > global_position.x else -1
	velocity.x = facing * (speed * 0.7)
	anim.flip_h = facing > 0
	anim.play("blindado")


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
	anim.play("die")
	GameState.add_coins(5)
	GameState.add_rage(6.0)
	collision_layer = 0
	collision_mask = 1
	await get_tree().create_timer(0.35).timeout
	_drop_coin()
	queue_free()


func _drop_coin() -> void:
	var p := preload("res://scenes/pickup.tscn").instantiate()
	p.global_position = global_position + Vector2(0, -8)
	p.setup("coin")
	get_tree().current_scene.add_child(p)


func _touch_player() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var n := col.get_collider()
		if n and n.is_in_group("player") and n.has_method("take_hit"):
			n.take_hit(1, Vector2(-facing * 140, -80))


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")
