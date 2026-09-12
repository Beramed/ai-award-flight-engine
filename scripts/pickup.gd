extends Area2D
class_name PickupDrop

var kind := "coin"


func setup(p_kind: String) -> void:
	kind = p_kind
	var spr: Sprite2D = $Sprite
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	match kind:
		"coin":
			spr.texture = SpriteLib.fx("coin")
		"fuzil", "doze", "sniper":
			spr.texture = SpriteLib.fx("bullet_heavy")
			modulate = Color(1.1, 0.8, 0.3)
		_:
			spr.texture = SpriteLib.ui("crate")


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match kind:
		"coin":
			GameState.add_coins(5)
		"fuzil":
			GameState.give_weapon("fuzil", 90)
		"doze":
			GameState.give_weapon("doze", 18)
		"sniper":
			GameState.give_weapon("sniper", 8)
		"granadas":
			GameState.grenades += 4
		"kit", "cura":
			GameState.heal_full()
		"municao":
			GameState.refill_ammo()
	queue_free()
