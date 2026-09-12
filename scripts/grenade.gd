extends CharacterBody2D

var damage := 4
var life := 2.4
var exploding := false
var boom_t := 0.0
var fly_t := 0.0
var fly_frames: Array[Texture2D] = []
var boom_frames: Array[Texture2D] = []
var boom_hits: Dictionary = {}
var ground_blast := false
const GROUND_BOOM_FRAMES := 2.0
const BOOM_FPS := 11.0


func setup(impulse: Vector2) -> void:
	add_to_group("grenades")
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
		var idx := int(boom_t * BOOM_FPS)
		if boom_frames.is_empty() or idx >= boom_frames.size():
			queue_free()
			return
		_apply_tex(boom_frames[idx])
		$Sprite.rotation = 0.0
		$Sprite.scale = Vector2(1.35, 1.15) if ground_blast else Vector2(1.2, 1.2)
		_hurt_in_blast()
		if boom_t >= GROUND_BOOM_FRAMES / BOOM_FPS:
			$Boom.monitoring = false
		return

	velocity.y += 620.0 * delta
	var hit := move_and_collide(velocity * delta)
	if hit:
		var n := hit.get_normal()
		_explode(n.y < -0.35)
		return
	life -= delta
	fly_t += delta
	if fly_frames.size() > 1:
		_apply_tex(fly_frames[int(fly_t * 10.0) % fly_frames.size()])
		rotation = 0.0
	else:
		rotation += delta * 5.5
	if life <= 0.0:
		_explode(false)


func _apply_tex(tex: Texture2D) -> void:
	if tex == null:
		return
	$Sprite.texture = tex
	$Sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Sprite.centered = true


func _explode(on_ground: bool = false) -> void:
	if exploding:
		return
	exploding = true
	ground_blast = on_ground
	velocity = Vector2.ZERO
	rotation = 0.0
	$CollisionShape2D.set_deferred("disabled", true)
	var boom_shape := $Boom/CollisionShape2D.shape as CircleShape2D
	if boom_shape:
		var copy := boom_shape.duplicate() as CircleShape2D
		# At least two Kiko-frame-widths of ground reach when it lands.
		copy.radius = 72.0 if on_ground else 42.0
		$Boom/CollisionShape2D.shape = copy
		if on_ground:
			$Boom/CollisionShape2D.position = Vector2(0, 6)
	$Boom.monitoring = true
	boom_hits.clear()
	_hurt_in_blast()


func _hurt_in_blast() -> void:
	if not $Boom.monitoring:
		return
	for body in $Boom.get_overlapping_bodies():
		if boom_hits.has(body):
			continue
		if body.has_method("take_hit") and not body.is_in_group("player"):
			boom_hits[body] = true
			body.take_hit(damage, (body.global_position - global_position).normalized() * 160)
