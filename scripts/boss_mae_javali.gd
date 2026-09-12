extends EnemyBase
class_name BossMaeJavali

var phase := 0
var pattern_t := 0.0
var shock_cd := 0.0


func setup(p_id: String, p_facing: int = -1) -> void:
	super.setup(p_id, p_facing)
	kind = "boss"
	anim.play("boss_idle")
	add_to_group("boss")


func _physics_process(delta: float) -> void:
	if dead or GameState.paused_by_dialog:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	pattern_t -= delta
	shock_cd = max(0.0, shock_cd - delta)
	var player := _player()
	if player:
		facing = 1 if player.global_position.x > global_position.x else -1
		anim.flip_h = facing > 0
	if pattern_t <= 0.0:
		phase = (phase + 1) % 3
		pattern_t = 2.2 if phase != 1 else 1.4
		if phase == 1:
			velocity.y = -290
			anim.play("boss_jump")
		elif phase == 2:
			_shockwave()
			anim.play("boss_idle")
		else:
			anim.play("boss_charge")
	if phase == 0:
		velocity.x = facing * speed
		anim.play("boss_charge")
	elif phase == 1:
		velocity.x = facing * speed * 0.4
	else:
		velocity.x = move_toward(velocity.x, 0, 400 * delta)
	move_and_slide()
	_touch_player()


func _shockwave() -> void:
	if shock_cd > 0.0:
		return
	shock_cd = 1.6
	ArcadeFX.shake(8.0, 0.32)
	var wave := ColorRect.new()
	wave.color = Color(0.9, 0.85, 0.7, 0.55)
	wave.size = Vector2(40, 18)
	wave.position = global_position + Vector2(-20, 8)
	get_tree().current_scene.add_child(wave)
	var tw := wave.create_tween()
	tw.tween_property(wave, "size:x", 360, 0.35)
	tw.parallel().tween_property(wave, "position:x", global_position.x - 180, 0.35)
	tw.tween_callback(wave.queue_free)
	var player := _player()
	if player and player.is_on_floor() and abs(player.global_position.y - global_position.y) < 40:
		if player.has_method("take_hit"):
			player.take_hit(1, Vector2(facing * 200, -90))
