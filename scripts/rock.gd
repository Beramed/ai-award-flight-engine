extends CharacterBody2D

var damage := 1
var life := 2.2
var hit := false


func setup(impulse: Vector2) -> void:
	velocity = impulse
	var tex := SpriteLib.fx("rock")
	if tex:
		$Sprite.texture = tex
	$Sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _physics_process(delta: float) -> void:
	velocity.y += 640.0 * delta
	rotation += delta * 8.0
	var col := move_and_collide(velocity * delta)
	life -= delta
	if col or life <= 0.0:
		queue_free()


func _on_hurt_body_entered(body: Node) -> void:
	if hit:
		return
	if body.is_in_group("player") and body.has_method("take_hit"):
		hit = true
		body.take_hit(1, Vector2(sign(velocity.x) * 90, -40))
		queue_free()
