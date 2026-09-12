extends StaticBody2D
class_name SupplyCrate

var loot := "moedas"
var broken := false


func setup(p_loot: String) -> void:
	loot = p_loot
	$Sprite.texture = SpriteLib.ui("crate")
	$Sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("crates")


func take_hit(_amount: int, _knock := Vector2.ZERO) -> void:
	if broken:
		return
	broken = true
	var p := preload("res://scenes/pickup.tscn").instantiate()
	p.global_position = global_position + Vector2(0, -6)
	match loot:
		"fuzil", "doze", "sniper", "granadas", "kit", "seringa":
			p.setup(loot)
		_:
			p.setup("coin")
	get_tree().current_scene.add_child(p)
	queue_free()
