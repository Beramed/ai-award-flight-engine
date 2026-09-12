extends CanvasLayer
class_name HUD

const PANEL_SCALE := 0.24
const PANEL_POS := Vector2(4, 3)
const PORTRAIT_POS := Vector2(8, 10)
const PORTRAIT_SIZE := Vector2(154, 156)

@onready var root: Control = $Root
@onready var go_label: Label = $Root/GO
@onready var stage_name: Label = $Root/Stage

var panel: TextureRect
var hp_fill: ColorRect
var lives_lbl: Label
var score_lbl: Label
var rage_back: ColorRect
var rage_fill: ColorRect
var rage_lbl: Label
var portrait: TextureRect
var weapon_slots: Array[Control] = []


func _ready() -> void:
	layer = 10
	_build()
	GameState.hp_changed.connect(_on_hp)
	GameState.weapon_changed.connect(_refresh)
	GameState.ammo_changed.connect(_ammo)
	GameState.coins_changed.connect(_refresh_coins)
	GameState.score_changed.connect(_on_score)
	GameState.rage_changed.connect(_on_rage)
	GameState.lives_changed.connect(_on_lives)
	GameState.portrait_changed.connect(_on_portrait)
	go_label.visible = false
	_on_hp(GameState.hp, GameState.MAX_HP)
	_on_rage(GameState.rage, GameState.MAX_RAGE)
	_on_lives(GameState.lives)
	_on_score(GameState.score)
	_on_portrait(GameState.portrait)
	_paint_weapons()


func set_stage_title(text: String) -> void:
	stage_name.text = text


func show_go() -> void:
	go_label.visible = true
	go_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_property(go_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): go_label.visible = false)


func _build() -> void:
	panel = TextureRect.new()
	panel.texture = SpriteLib.ui("hud_panel")
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = PANEL_POS
	panel.scale = Vector2(PANEL_SCALE, PANEL_SCALE)
	root.add_child(panel)

	portrait = TextureRect.new()
	portrait.texture = SpriteLib.ui("portrait_kiko")
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.position = PANEL_POS + PORTRAIT_POS * PANEL_SCALE
	portrait.size = PORTRAIT_SIZE * PANEL_SCALE
	root.add_child(portrait)

	var panel_w := 482.0 * PANEL_SCALE
	var col_x := PANEL_POS.x + portrait.size.x + 4.0
	var col_w := maxf(72.0, PANEL_POS.x + panel_w - col_x - 3.0)
	var cover := ColorRect.new()
	cover.color = Color(0.10, 0.30, 0.44, 1)
	cover.position = Vector2(col_x - 2.0, PANEL_POS.y + 2.0)
	cover.size = Vector2(col_w + 5.0, 62.0)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cover)

	var player_lbl := _hud_label(Vector2(col_x, PANEL_POS.y + 2.0), Vector2(col_w, 10), 8)
	player_lbl.text = "PLAYER 1"
	player_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.22, 1))

	var hp_pos := Vector2(col_x, PANEL_POS.y + 13.0)
	var hp_h := 6.0
	var track := ColorRect.new()
	track.color = Color(0.02, 0.02, 0.02, 1)
	track.position = hp_pos
	track.size = Vector2(col_w, hp_h)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(track)

	hp_fill = ColorRect.new()
	hp_fill.color = Color(0.92, 0.42, 0.12, 1)
	hp_fill.position = hp_pos
	hp_fill.size = Vector2(col_w, hp_h)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_fill)

	var rage_pos := Vector2(col_x, hp_pos.y + hp_h + 2.0)
	var rage_size := Vector2(col_w, 7.0)
	rage_back = ColorRect.new()
	rage_back.color = Color(0.05, 0.08, 0.16, 0.95)
	rage_back.position = rage_pos
	rage_back.size = rage_size
	rage_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rage_back)

	rage_fill = ColorRect.new()
	rage_fill.color = Color(0.18, 0.55, 1.0, 1)
	rage_fill.position = rage_pos
	rage_fill.size = Vector2(0, rage_size.y)
	rage_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rage_fill)

	rage_lbl = _hud_label(rage_pos, rage_size, 6)
	rage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rage_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rage_lbl.text = "RAGE"
	rage_lbl.clip_text = true
	rage_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 1))

	var text_y := rage_pos.y + rage_size.y + 6.0
	lives_lbl = _hud_label(Vector2(col_x, text_y), Vector2(col_w, 9), 7)
	score_lbl = _hud_label(Vector2(col_x, text_y + 10.0), Vector2(col_w, 9), 7)

	var weapons_bg := ColorRect.new()
	weapons_bg.color = Color(0.02, 0.04, 0.08, 0.55)
	weapons_bg.position = Vector2(0, 244)
	weapons_bg.size = Vector2(480, 26)
	weapons_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(weapons_bg)

	var weapons := HBoxContainer.new()
	weapons.position = Vector2(6, 246)
	weapons.size = Vector2(468, 22)
	weapons.add_theme_constant_override("separation", 10)
	weapons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(weapons)
	for spec in [
		{"id": "doze", "icon": "weapon_doze"},
		{"id": "pistola", "icon": "weapon_pistola"},
		{"id": "fuzil", "icon": "weapon_fuzil"},
		{"id": "granada", "icon": "weapon_grenade"},
	]:
		weapons.add_child(_make_weapon_slot(spec["id"], spec["icon"]))

	stage_name.position = Vector2(250, 4)
	stage_name.size = Vector2(226, 14)
	stage_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.move_child(go_label, -1)


func _hud_label(pos: Vector2, size: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = size
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 2)
	root.add_child(lbl)
	return lbl


func _make_weapon_slot(id: String, icon_name: String) -> Control:
	var slot := HBoxContainer.new()
	slot.add_theme_constant_override("separation", 3)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ammo := Label.new()
	ammo.name = "Ammo"
	ammo.custom_minimum_size = Vector2(28, 18)
	ammo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ammo.add_theme_font_size_override("font_size", 10)
	ammo.add_theme_color_override("font_color", Color(1, 0.92, 0.35, 1))
	ammo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	ammo.add_theme_constant_override("outline_size", 4)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = SpriteLib.ui(icon_name)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(40, 18)
	slot.add_child(ammo)
	slot.add_child(icon)
	slot.set_meta("weapon_id", id)
	weapon_slots.append(slot)
	return slot


func _on_hp(value: int, maximum: int) -> void:
	var ratio := 0.0 if maximum <= 0 else clampf(float(value) / float(maximum), 0.0, 1.0)
	hp_fill.size.x = rage_back.size.x * ratio
	hp_fill.color = Color(0.92, 0.42, 0.12, 1) if value > 1 else Color(0.85, 0.15, 0.1, 1)


func _on_portrait(kind: String) -> void:
	var tex_name := "portrait_kiko"
	if kind == "hurt":
		tex_name = "portrait_kiko_hurt"
	elif kind == "rage":
		tex_name = "portrait_kiko_rage"
	portrait.texture = SpriteLib.ui(tex_name)


func _on_lives(value: int) -> void:
	lives_lbl.text = "LIVES: %d" % max(value, 0)


func _on_score(value: int) -> void:
	score_lbl.text = "SCORE: %s" % _format_score(value)


func _on_rage(value: float, maximum: float) -> void:
	var ratio := 0.0 if maximum <= 0.0 else clampf(value / maximum, 0.0, 1.0)
	rage_fill.size.x = rage_back.size.x * ratio


func _refresh(_id: String) -> void:
	_paint_weapons()


func _ammo(_id: String, _v: int) -> void:
	_paint_weapons()


func _refresh_coins(_v: int) -> void:
	pass


func _paint_weapons() -> void:
	for slot in weapon_slots:
		var id := String(slot.get_meta("weapon_id"))
		var ammo: Label = slot.get_node("Ammo")
		if id == "granada":
			ammo.text = str(GameState.grenades)
			slot.modulate = Color(1, 1, 1, 1)
			continue
		var ammo_val: int = int(GameState.ammo.get(id, 0))
		ammo.text = "INF" if ammo_val < 0 else str(ammo_val)
		slot.modulate = Color(1, 1, 1, 1) if id == GameState.current_weapon else Color(0.55, 0.55, 0.62, 0.85)


func _format_score(value: int) -> String:
	var raw := str(max(value, 0))
	var out := ""
	var count := 0
	for i in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = raw[i] + out
		count += 1
	return out
