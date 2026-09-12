extends CharacterBody2D

var damage := 4
var life := 2.4
var exploding := false


func setup(impulse: Vector2) -> void:
	velocity = impulse
	$Sprite.texture = SpriteLib.fx("grenade")
	$Sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _physics_process(delta: float) -> void:
	if exploding:
		return
	velocity.y += 620.0 * delta
	var hit := move_and_collide(velocity * delta)
	if hit:
		_explode()
		return
	life -= delta
	rotation += delta * 10.0
	if life <= 0.0:
		_explode()


func _explode() -> void:
	if exploding:
		return
	exploding = true
	velocity = Vector2.ZERO
	var boom := $Boom
	boom.monitoring = true
	await get_tree().process_frame
	for body in boom.get_overlapping_bodies():
		if body.has_method("take_hit") and not body.is_in_group("player"):
			body.take_hit(damage, (body.global_position - global_position).normalized() * 160)
	queue_free()
