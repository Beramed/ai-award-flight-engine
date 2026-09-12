extends Node
## Feedback arcade (Metal Slug-style): shake, pontuação flutuante, letras de caixa.

var _shake_t := 0.0
var _shake_amt := 0.0


func _process(delta: float) -> void:
	var cam := _cam()
	if cam == null:
		return
	if _shake_t > 0.0:
		_shake_t = maxf(0.0, _shake_t - delta)
		var mag := _shake_amt * clampf(_shake_t * 6.0, 0.15, 1.0)
		cam.offset = Vector2(randf_range(-mag, mag), randf_range(-mag, mag))
	elif cam.offset != Vector2.ZERO:
		cam.offset = Vector2.ZERO


func shake(amount := 6.0, time := 0.22) -> void:
	_shake_amt = maxf(_shake_amt * 0.4, amount)
	_shake_t = maxf(_shake_t, time)


func score_pop(world_pos: Vector2, points: int, color := Color(1.0, 0.92, 0.22, 1)) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var lbl := Label.new()
	lbl.text = str(points)
	lbl.z_index = 48
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 4)
	scene.add_child(lbl)
	lbl.global_position = world_pos + Vector2(-12, -34)
	var tw := lbl.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 30.0, 0.72)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.72)
	tw.tween_callback(lbl.queue_free)


func float_text(world_pos: Vector2, text: String, color := Color(1, 0.95, 0.55, 1)) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.z_index = 48
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 3)
	scene.add_child(lbl)
	lbl.global_position = world_pos + Vector2(-18, -40)
	var tw := lbl.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 24.0, 0.9)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.tween_callback(lbl.queue_free)


func loot_letter(kind: String) -> String:
	match kind:
		"kit", "cura":
			return "H"
		"doze", "sniper":
			return "S"
		"granadas":
			return "G"
		"fuzil":
			return "R"
		"municao":
			return "M"
		"seringa", "adrenalina":
			return "A"
		"comida":
			return "!"
		_:
			return ""


func loot_color(kind: String) -> Color:
	match kind:
		"kit", "cura":
			return Color(0.95, 0.22, 0.22, 1)
		"doze", "sniper":
			return Color(1.0, 0.55, 0.12, 1)
		"granadas":
			return Color(0.25, 0.85, 0.32, 1)
		"fuzil":
			return Color(1.0, 0.9, 0.2, 1)
		"municao":
			return Color(0.35, 0.85, 1.0, 1)
		"seringa", "adrenalina":
			return Color(0.85, 0.35, 1.0, 1)
		"comida":
			return Color(1.0, 0.45, 0.7, 1)
		_:
			return Color(1, 1, 1, 1)


func attach_letter(host: Node2D, kind: String) -> void:
	var letter := loot_letter(kind)
	if letter == "":
		return
	var lbl := Label.new()
	lbl.name = "LootLetter"
	lbl.text = letter
	lbl.z_index = 6
	lbl.position = Vector2(-5, -22)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", loot_color(kind))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 4)
	host.add_child(lbl)


func _cam() -> Camera2D:
	var tree := get_tree()
	if tree == null:
		return null
	var vp := tree.root
	if vp:
		return vp.get_camera_2d()
	return null
