extends CanvasLayer
class_name ShopUI

signal closed

const ART_W := 590.0
const ART_H := 562.0

var active := false
var _art: TextureRect
var _coins: Label
var _hint: Label
var _exit: Button
var _status: Label

var catalog := [
	{"id": "municao", "cost": 10, "x": 300.0, "y": 70.0, "w": 272.0, "h": 50.0},
	{"id": "sniper", "cost": 45, "x": 300.0, "y": 120.0, "w": 272.0, "h": 50.0},
	{"id": "granadas", "cost": 18, "x": 300.0, "y": 170.0, "w": 272.0, "h": 50.0},
	{"id": "boné", "cost": 22, "x": 300.0, "y": 220.0, "w": 272.0, "h": 50.0},
	{"id": "carregador", "cost": 12, "x": 300.0, "y": 270.0, "w": 272.0, "h": 50.0},
	{"id": "kit", "cost": 16, "x": 300.0, "y": 322.0, "w": 272.0, "h": 52.0},
]


func _ready() -> void:
	layer = 25
	visible = false
	add_to_group("shop_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	GameState.coins_changed.connect(func(_v): _refresh())


func open() -> void:
	_show()
	await closed


func force_open() -> void:
	_show()


func _show() -> void:
	active = true
	visible = true
	GameState.paused_by_dialog = true
	_refresh()
	_status.text = "ESC / ENTER"
	_exit.grab_focus()


func close() -> void:
	if not active:
		return
	active = false
	visible = false
	GameState.paused_by_dialog = false
	closed.emit()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var tex: Texture2D = SpriteLib.ui("shop_mineiro")
	var sc: float = minf(470.0 / ART_W, 248.0 / ART_H)
	var dw: float = ART_W * sc
	var dh: float = ART_H * sc
	_art = TextureRect.new()
	_art.texture = tex
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.position = Vector2((480.0 - dw) * 0.5, (270.0 - dh) * 0.5)
	_art.size = Vector2(dw, dh)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)

	for i in catalog.size():
		var item: Dictionary = catalog[i]
		var btn := Button.new()
		btn.flat = true
		btn.position = _art.position + Vector2(float(item["x"]) * sc, float(item["y"]) * sc)
		btn.size = Vector2(float(item["w"]) * sc, float(item["h"]) * sc)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.modulate = Color(1, 1, 1, 0.01)
		btn.pressed.connect(_buy.bind(String(item["id"]), int(item["cost"])))
		btn.set_meta("item_id", String(item["id"]))
		add_child(btn)

	var coins_pos := _art.position + Vector2(300.0 * sc, 376.0 * sc)
	var coins_bg := ColorRect.new()
	coins_bg.color = Color(0.05, 0.07, 0.1, 0.92)
	coins_bg.position = coins_pos
	coins_bg.size = Vector2(272.0 * sc, 34.0 * sc)
	add_child(coins_bg)

	_coins = Label.new()
	_coins.position = coins_pos
	_coins.size = Vector2(272.0 * sc, 34.0 * sc)
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_coins.add_theme_font_size_override("font_size", 11)
	_coins.add_theme_color_override("font_color", Color(1.0, 0.92, 0.28, 1))
	_coins.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_coins.add_theme_constant_override("outline_size", 4)
	add_child(_coins)

	# EXIT sits BELOW the coins, covering the art's lower prompt box.
	var exit_bg := ColorRect.new()
	exit_bg.color = Color(0.08, 0.07, 0.06, 0.96)
	exit_bg.position = _art.position + Vector2(300.0 * sc, 414.0 * sc)
	exit_bg.size = Vector2(272.0 * sc, 92.0 * sc)
	add_child(exit_bg)
	_exit = Button.new()
	_exit.text = "EXIT"
	_exit.flat = true
	_exit.position = exit_bg.position + Vector2(8, 6)
	_exit.size = Vector2(exit_bg.size.x - 16, 34)
	_exit.add_theme_font_size_override("font_size", 16)
	_exit.add_theme_color_override("font_color", Color(1.0, 0.86, 0.2, 1))
	_exit.pressed.connect(close)
	add_child(_exit)

	_status = Label.new()
	_status.position = exit_bg.position + Vector2(8, 42)
	_status.size = Vector2(exit_bg.size.x - 16, 44)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 8)
	_status.add_theme_color_override("font_color", Color(0.92, 0.93, 0.88, 1))
	_status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_status.add_theme_constant_override("outline_size", 3)
	add_child(_status)

	_hint = Label.new()
	_hint.position = Vector2(8, 254)
	_hint.size = Vector2(464, 14)
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8, 1))
	_hint.text = "1-6 comprar   ESC / ENTER sair"
	add_child(_hint)


func _refresh() -> void:
	if _coins:
		_coins.text = "DINHEIRO G-$: %d" % GameState.coins


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("confirm") or event.is_action_pressed("ui_start"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx := -1
		match event.physical_keycode:
			KEY_1: idx = 0
			KEY_2: idx = 1
			KEY_3: idx = 2
			KEY_4: idx = 3
			KEY_5: idx = 4
			KEY_6: idx = 5
			KEY_ESCAPE:
				close()
				get_viewport().set_input_as_handled()
				return
		if idx >= 0 and idx < catalog.size():
			var item: Dictionary = catalog[idx]
			_buy(String(item["id"]), int(item["cost"]))
			get_viewport().set_input_as_handled()


func _buy(id: String, cost: int) -> void:
	if not active:
		return
	if not GameState.spend_coins(cost):
		_status.text = "SEM G-$ O SUFICIENTE"
		_coins.modulate = Color(1.0, 0.35, 0.3, 1)
		var tw := create_tween()
		tw.tween_property(_coins, "modulate", Color(1, 1, 1, 1), 0.35)
		return
	match id:
		"municao":
			GameState.refill_ammo()
			if GameState.ammo["fuzil"] >= 0:
				GameState.ammo["fuzil"] += 40
			GameState.ammo_changed.emit(GameState.current_weapon, GameState.ammo[GameState.current_weapon])
			_status.text = "MUNIÇÃO REABASTECIDA"
		"sniper":
			GameState.give_weapon("sniper", 8)
			_status.text = "SNIPER EQUIPADA"
		"granadas":
			GameState.grenades += 4
			GameState.ammo_changed.emit("granada", GameState.grenades)
			_status.text = "GRANADAS +4"
		"boné":
			GameState.has_vest = true
			_status.text = "COLETE / BONÉ EQUIPADO"
		"carregador":
			GameState.refill_ammo()
			_status.text = "CARREGADOR CHEIO"
		"kit":
			GameState.heal_full()
			_status.text = "KIT USADO — VIDA CHEIA"
		_:
			_status.text = "COMPRADO"
	_refresh()
