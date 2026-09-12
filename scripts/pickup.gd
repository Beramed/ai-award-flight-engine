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
		"seringa", "adrenalina":
			spr.texture = SpriteLib.fx("syringe")
			if spr.texture == null:
				spr.texture = SpriteLib.ui("pickup_syringe")
		"granadas":
			spr.texture = SpriteLib.fx("grenade")
		"comida":
			spr.texture = SpriteLib.fx("coin")
			modulate = Color(1.2, 0.45, 0.7)
		_:
			spr.texture = SpriteLib.ui("crate")
	ArcadeFX.attach_letter(self, kind)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match kind:
		"coin":
			GameState.add_coins(5)
			GameState.add_score(100)
			ArcadeFX.score_pop(global_position, 100)
		"fuzil":
			GameState.give_weapon("fuzil", 90)
			ArcadeFX.float_text(global_position, "R", ArcadeFX.loot_color("fuzil"))
		"doze":
			GameState.give_weapon("doze", 18)
			ArcadeFX.float_text(global_position, "S", ArcadeFX.loot_color("doze"))
		"sniper":
			GameState.give_weapon("sniper", 8)
			ArcadeFX.float_text(global_position, "S", ArcadeFX.loot_color("sniper"))
		"kit", "cura":
			GameState.heal_full()
			ArcadeFX.float_text(global_position, "H", ArcadeFX.loot_color("kit"))
		"municao":
			GameState.refill_ammo()
			ArcadeFX.float_text(global_position, "M", ArcadeFX.loot_color("municao"))
		"seringa", "adrenalina":
			GameState.add_rage(55.0)
			ArcadeFX.float_text(global_position, "A", ArcadeFX.loot_color("seringa"))
		"granadas":
			GameState.grenades += 4
			GameState.ammo_changed.emit("granada", GameState.grenades)
			ArcadeFX.float_text(global_position, "G", ArcadeFX.loot_color("granadas"))
		"comida":
			GameState.add_score(500)
			ArcadeFX.score_pop(global_position, 500, ArcadeFX.loot_color("comida"))
	queue_free()
