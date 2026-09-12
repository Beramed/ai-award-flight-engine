extends Area2D

var dir := Vector2.RIGHT
var speed := 320.0
var damage := 1
var piercing := false
var life := 1.4


func setup(p_dir: Vector2, p_speed: float, p_damage: int, p_piercing: bool, weapon := "pistola") -> void:
	dir = p_dir
	speed = p_speed
	damage = p_damage
	piercing = p_piercing
	rotation = dir.angle()
	var spr: Sprite2D = $Sprite
	match weapon:
		"fuzil":
			spr.texture = SpriteLib.fx("bullet_heavy")
		"sniper":
			spr.texture = SpriteLib.fx("bullet_sniper")
		_:
			spr.texture = SpriteLib.fx("bullet")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_hit"):
		body.take_hit(damage, dir * 80)
		if not piercing:
			queue_free()
		return
	if body is StaticBody2D and not piercing:
		queue_free()
