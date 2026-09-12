extends CanvasLayer
class_name HUD

@onready var hp_box: HBoxContainer = $Root/Hp
@onready var info: Label = $Root/Info
@onready var go_label: Label = $Root/GO
@onready var stage_name: Label = $Root/Stage


func _ready() -> void:
	layer = 10
	GameState.hp_changed.connect(_on_hp)
	GameState.weapon_changed.connect(_refresh)
	GameState.ammo_changed.connect(_ammo)
	GameState.coins_changed.connect(_refresh_coins)
	GameState.rage_changed.connect(_refresh_rage)
	GameState.lives_changed.connect(_refresh_lives)
	go_label.visible = false
	_on_hp(GameState.hp, GameState.MAX_HP)
	_refresh(GameState.current_weapon)


func set_stage_title(text: String) -> void:
	stage_name.text = text


func show_go() -> void:
	go_label.visible = true
	go_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_property(go_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): go_label.visible = false)


func _on_hp(value: int, _maximum: int) -> void:
	for c in hp_box.get_children():
		c.queue_free()
	for i in range(GameState.MAX_HP):
		var spr := TextureRect.new()
		spr.texture = SpriteLib.ui("heart")
		spr.modulate = Color.WHITE if i < value else Color(0.2, 0.2, 0.2, 0.6)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.custom_minimum_size = Vector2(16, 14)
		spr.stretch_mode = TextureRect.STRETCH_KEEP
		hp_box.add_child(spr)


func _refresh(_id: String) -> void:
	_paint()


func _ammo(_id: String, _v: int) -> void:
	_paint()


func _refresh_coins(_v: int) -> void:
	_paint()


func _refresh_rage(_v: float, _m: float) -> void:
	_paint()


func _refresh_lives(_v: int) -> void:
	_paint()


func _paint() -> void:
	var ammo_val = GameState.ammo[GameState.current_weapon]
	var ammo_txt := "INF" if ammo_val < 0 else str(ammo_val)
	info.text = "VIDAS %d   ARMA %s  MUN %s   GRANADAS %d   MOEDAS %d   RAGE %d%%" % [
		max(GameState.lives, 0),
		String(GameState.weapon_stats[GameState.current_weapon].get("label", GameState.current_weapon)).to_upper(),
		ammo_txt,
		GameState.grenades,
		GameState.coins,
		int(GameState.rage),
	]
