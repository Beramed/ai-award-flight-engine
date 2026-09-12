extends Node2D

var vel := Vector2.ZERO
var spin := 10.0
var life := 0.65


func setup(tex: Texture2D, facing: int) -> void:
	$Sprite.texture = tex
	$Sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vel = Vector2(-facing * randf_range(36.0, 88.0), randf_range(-210.0, -90.0))
	spin = randf_range(8.0, 16.0) * facing


func _process(delta: float) -> void:
	vel.y += 780.0 * delta
	position += vel * delta
	rotation += spin * delta
	life -= delta
	modulate.a = clampf(life * 2.2, 0.0, 1.0)
	if life <= 0.0:
		queue_free()
