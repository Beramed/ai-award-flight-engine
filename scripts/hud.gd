extends CanvasLayer
class_name HUD

const PANEL_SCALE := 0.48
const PANEL_POS := Vector2(4, 3)
const SRC_SIZE := Vector2(482, 178)
const BAR_POS := Vector2(168, 65)
const BAR_SIZE := Vector2(278, 16)

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
	go_label.visible = false
	_on_hp(GameState.hp, GameState.MAX_HP)
	_on_rage(GameState.rage, GameState.MAX_RAGE)
	_on_lives(GameState.lives)
	_on_score(GameState.score)
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

	var bar_origin := PANEL_POS + BAR_POS * PANEL_SCALE
	var track := ColorRect.new()
	track.color = Color(0.02, 0.02, 0.02, 1)
	track.position = bar_origin
	track.size = BAR_SIZE * PANEL_SCALE
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(track)

	hp_fill = ColorRect.new()
	hp_fill.color = Color(0.92, 0.42, 0.12, 1)
	hp_fill.position = bar_origin
	hp_fill.size = BAR_SIZE * PANEL_SCALE
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_fill)

	lives_lbl = _hud_label(PANEL_POS + Vector2(168, 100) * PANEL_SCALE, Vector2(140, 16), 10)
	score_lbl = _hud_label(PANEL_POS + Vector2(168, 132) * PANEL_SCALE, Vector2(140, 16), 10)

	var panel_h := SRC_SIZE.y * PANEL_SCALE
	var rage_pos := Vector2(bar_origin.x, PANEL_POS.y + panel_h + 3.0)
	var rage_size := Vector2(BAR_SIZE.x * PANEL_SCALE, 12.0)
	rage_back = ColorRect.new()
	rage_back.color = Color(0.05, 0.08, 0.16, 0.92)
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

	rage_lbl = _hud_label(rage_pos, rage_size, 10)
	rage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rage_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rage_lbl.text = "RAGE"
	rage_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 1))

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
	lbl.add_theme_constant_override("outline_size", 4)
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
	hp_fill.size.x = BAR_SIZE.x * PANEL_SCALE * ratio
	hp_fill.color = Color(0.92, 0.42, 0.12, 1) if value > 1 else Color(0.85, 0.15, 0.1, 1)


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
