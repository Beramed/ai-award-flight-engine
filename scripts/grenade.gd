extends CharacterBody2D

var damage := 4
var life := 2.4
var exploding := false
var boom_t := 0.0
var fly_t := 0.0
var fly_frames: Array[Texture2D] = []
var boom_frames: Array[Texture2D] = []


func setup(impulse: Vector2) -> void:
	velocity = impulse
	fly_frames = SpriteLib.frames("fx", "grenade_fly", 4)
	if fly_frames.is_empty():
		var one := SpriteLib.fx("grenade")
		if one:
			fly_frames.append(one)
	boom_frames = SpriteLib.frames("fx", "explosion", 6)
	_apply_tex(fly_frames[0] if fly_frames else SpriteLib.fx("grenade"))
	$Sprite.scale = Vector2.ONE


func _physics_process(delta: float) -> void:
	if exploding:
		boom_t += delta
		var idx := int(boom_t * 11.0)
		if boom_frames.is_empty() or idx >= boom_frames.size():
			queue_free()
			return
		_apply_tex(boom_frames[idx])
		$Sprite.rotation = 0.0
		$Sprite.scale = Vector2(1.2, 1.2)
		return

	velocity.y += 620.0 * delta
	var hit := move_and_collide(velocity * delta)
	if hit:
		_explode()
		return
	life -= delta
	fly_t += delta
	if fly_frames.size() > 1:
		_apply_tex(fly_frames[int(fly_t * 10.0) % fly_frames.size()])
		rotation = 0.0
	else:
		rotation += delta * 5.5
	if life <= 0.0:
		_explode()


func _apply_tex(tex: Texture2D) -> void:
	if tex == null:
		return
	$Sprite.texture = tex
	$Sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Sprite.centered = true


func _explode() -> void:
	if exploding:
		return
	exploding = true
	velocity = Vector2.ZERO
	rotation = 0.0
	$CollisionShape2D.set_deferred("disabled", true)
	var boom := $Boom
	boom.monitoring = true
	await get_tree().process_frame
	if not is_instance_valid(self):
		return
	for body in boom.get_overlapping_bodies():
		if body.has_method("take_hit") and not body.is_in_group("player"):
			body.take_hit(damage, (body.global_position - global_position).normalized() * 160)
	boom.monitoring = false
	if boom_frames.is_empty():
		queue_free()
