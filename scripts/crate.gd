extends StaticBody2D
class_name SupplyCrate

var loot := "moedas"
var kind := "crate"
var broken := false


func setup(p_loot: String, p_kind := "crate") -> void:
	loot = p_loot
	kind = p_kind
	$Sprite.centered = true
	$Sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Sprite.z_index = 3
	z_index = 3
	var shape := $CollisionShape2D.shape as RectangleShape2D
	var copy := (shape.duplicate() if shape else RectangleShape2D.new()) as RectangleShape2D
	match kind:
		"barrel":
			$Sprite.texture = SpriteLib.tile("barrel")
			$Sprite.scale = Vector2(1.0, 1.0)
			copy.size = Vector2(14, 20)
		"hay":
			$Sprite.texture = SpriteLib.tile("hay")
			$Sprite.scale = Vector2(1.0, 1.0)
			copy.size = Vector2(24, 16)
		"fence":
			$Sprite.texture = SpriteLib.tile("fence")
			$Sprite.scale = Vector2(0.72, 0.55)
			$Sprite.z_index = 1
			z_index = 1
			copy.size = Vector2(16, 14)
		_:
			$Sprite.texture = SpriteLib.ui("crate")
			$Sprite.scale = Vector2(0.82, 0.82)
			copy.size = Vector2(14, 14)
	$CollisionShape2D.shape = copy
	add_to_group("crates")
	add_to_group("breakable")
	add_to_group("world_chunk")
	ArcadeFX.attach_letter(self, loot)


func take_hit(_amount: int, _knock := Vector2.ZERO) -> void:
	if broken:
		return
	broken = true
	collision_layer = 0
	if loot != "" and loot != "none":
		var p := preload("res://scenes/pickup.tscn").instantiate()
		p.global_position = global_position + Vector2(0, -6)
		match loot:
			"fuzil", "doze", "sniper", "granadas", "kit", "seringa", "municao", "comida":
				p.setup(loot)
			_:
				p.setup("coin")
		get_tree().current_scene.add_child(p)
	call_deferred("queue_free")
