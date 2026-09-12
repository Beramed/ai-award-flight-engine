extends Area2D
## Tiro: deslocamento cinemático + AABB contra hurtboxes (SFML rectsOverlap / Phaser overlap).
## Colisão com o cenário continua via Area2D vs StaticBody (chão, caixas).

var dir := Vector2.RIGHT
var speed := 320.0
var damage := 1
var piercing := false
var life := 1.4
var _hit_ids: Dictionary = {}


func setup(p_dir: Vector2, p_speed: float, p_damage: int, p_piercing: bool, weapon := "pistola") -> void:
	dir = p_dir
	speed = p_speed
	damage = p_damage
	piercing = p_piercing
	rotation = dir.angle()
	if dir.y > 0.2:
		collision_mask = 5
	var spr: Sprite2D = $Sprite
	match weapon:
		"pistola":
			spr.texture = SpriteLib.fx("bullet_revolver")
			if spr.texture == null:
				spr.texture = SpriteLib.fx("bullet")
		"fuzil":
			spr.texture = SpriteLib.fx("bullet_fuzil")
			if spr.texture == null:
				spr.texture = SpriteLib.fx("bullet_heavy")
		"doze":
			spr.texture = SpriteLib.fx("pellet_doze")
			if spr.texture == null:
				spr.texture = SpriteLib.fx("bullet")
		"sniper":
			spr.texture = SpriteLib.fx("bullet_sniper")
		_:
			spr.texture = SpriteLib.fx("bullet")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func apply_scale_factor(factor: float) -> void:
	if factor <= 0.0:
		return
	$Sprite.scale = Vector2(factor, factor)
	var col := $CollisionShape2D
	var shape := col.shape as RectangleShape2D
	if shape:
		var copy := shape.duplicate() as RectangleShape2D
		copy.size = Vector2(8, 4) * max(factor, 0.8)
		col.shape = copy


func aabb() -> Rect2:
	var col := $CollisionShape2D
	var shape := col.shape as RectangleShape2D
	if shape == null:
		return Rect2(global_position, Vector2(6, 3))
	var sx := absf(global_scale.x)
	var sy := absf(global_scale.y)
	var size := Vector2(shape.size.x * sx, shape.size.y * sy)
	return Rect2(col.global_position - size * 0.5, size)


func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	_aabb_hurtboxes()


func _aabb_hurtboxes() -> void:
	var mine := aabb()
	for h in get_tree().get_nodes_in_group("hurtbox_enemy"):
		if h == null or not is_instance_valid(h):
			continue
		if _hit_ids.has(h):
			continue
		if ArcadeHitbox.overlap(mine, h.aabb()):
			_hit_ids[h] = true
			h.receive_hit(damage, dir * 80)
			if not piercing:
				queue_free()
				return


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.is_in_group("enemies"):
		return
	if body.has_method("take_hit"):
		body.take_hit(damage, dir * 80)
		if not piercing:
			queue_free()
		return
	if body is StaticBody2D and not piercing:
		queue_free()
