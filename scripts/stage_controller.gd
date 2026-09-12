extends Node2D
class_name StageController

signal boss_defeated
signal stage_cleared

@export var stage_number := 1

var data: Dictionary = {}
var events: Array = []
var event_i := 0
var waiting_arena := false
var busy := false

var player: PlayerKiko
var cam: StageCamera
var hud: HUD
var dialog: DialogUI
var ground_y := 236.0


func boot(numero: int) -> void:
	stage_number = numero
	data = Roteiro.fase(numero)
	events = data.get("eventos", [])
	event_i = 0
	ground_y = float(data.get("chao_y", 236))
	GameState.stage_cleared = false
	_build_world()
	_spawn_player()
	_spawn_hud()
	_make_rain()
	set_process(true)
	busy = true
	await _try_start_events()
	busy = false


func _process(_delta: float) -> void:
	if GameState.paused_by_dialog or waiting_arena or busy:
		return
	_advance_by_x()


func _try_start_events() -> void:
	await _pump_while(["start"])


func _advance_by_x() -> void:
	if player == null or event_i >= events.size() or busy:
		return
	var ev: Dictionary = events[event_i]
	if String(ev.get("quando", "")) != "x":
		return
	if player.global_position.x >= float(ev.get("x", 0)):
		_consume_current_and_followups()


func _consume_current_and_followups() -> void:
	busy = true
	await _run_event(events[event_i])
	event_i += 1
	await _pump_while(["start", "clear"])
	busy = false


func _pump_while(whens: Array) -> void:
	while event_i < events.size():
		var ev: Dictionary = events[event_i]
		if not whens.has(String(ev.get("quando", ""))):
			break
		await _run_event(ev)
		event_i += 1


func _run_event(ev: Dictionary) -> void:
	var tipo := String(ev.get("tipo", ""))
	match tipo:
		"dialogo":
			await dialog.play(Roteiro.dialogo(stage_number, String(ev.get("chave", ""))))
		"spawn":
			_spawn_pack(ev.get("inimigos", []))
		"arena":
			await _run_arena(ev)
		"resgate":
			await _run_rescue(ev)
		"vitoria":
			GameState.stage_cleared = true
			stage_cleared.emit()


func _run_arena(ev: Dictionary) -> void:
	waiting_arena = true
	cam.lock_arena(float(ev.get("left", 0)), float(ev.get("right", 480)))
	_spawn_blockers(float(ev.get("left", 0)), float(ev.get("right", 480)))
	if ev.has("chefe"):
		await dialog.play(Roteiro.dialogo(stage_number, "chefe"))
	for onda in ev.get("ondas", []):
		_spawn_pack(onda)
		await _wait_enemies_dead()
	_clear_blockers()
	cam.unlock_arena()
	hud.show_go()
	waiting_arena = false


func _run_rescue(ev: Dictionary) -> void:
	var quem := String(ev.get("quem", "juliana"))
	_spawn_npc(quem, float(ev.get("x", player.global_position.x + 40)))
	await dialog.play(Roteiro.dialogo(stage_number, String(ev.get("chave", quem))))
	match String(ev.get("bonus", "")):
		"fuzil":
			GameState.give_weapon("fuzil", 90)
		"municao":
			GameState.refill_ammo()
			GameState.add_coins(25)
		"cura":
			GameState.heal_full()


func _spawn_pack(pack: Array) -> void:
	for item in pack:
		var info: Dictionary = item
		var id := String(info.get("id", "javali_corredor"))
		var node: Node2D
		if bool(info.get("boss", false)) or id == "mae_javali":
			node = preload("res://scenes/boss_mae_javali.tscn").instantiate()
		else:
			node = preload("res://scenes/enemy.tscn").instantiate()
		node.global_position = Vector2(float(info.get("x", 400)), ground_y - 18)
		add_child(node)
		node.setup(id, int(info.get("facing", -1)))


func _wait_enemies_dead() -> void:
	await get_tree().process_frame
	while not get_tree().get_nodes_in_group("enemies").is_empty():
		await get_tree().create_timer(0.2).timeout


func _spawn_player() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	var start: Vector2 = data.get("player_start", Vector2(72, 200))
	player.global_position = start
	add_child(player)
	cam = player.get_node("Camera")
	cam.configure(float(data.get("largura", 5600)))
	player.spawn_point = start
	player.died.connect(func(): player.spawn_point = Vector2(max(cam.lock_left + 48, start.x), start.y))
	if GameState.player_count >= 2:
		var p2: PlayerKiko = preload("res://scenes/player.tscn").instantiate()
		p2.player_index = 1
		p2.global_position = start + Vector2(28, 0)
		add_child(p2)
		p2.spawn_point = p2.global_position
		p2.modulate = Color(1.15, 0.92, 0.75)


func _spawn_hud() -> void:
	hud = preload("res://scenes/hud.tscn").instantiate()
	add_child(hud)
	hud.set_stage_title("FASE %d — %s" % [stage_number, String(data.get("nome", ""))])
	dialog = preload("res://scenes/dialog.tscn").instantiate()
	add_child(dialog)


func _build_world() -> void:
	var width := float(data.get("largura", 5600))
	var sky := Sprite2D.new()
	sky.texture = SpriteLib.tile("sky")
	sky.centered = false
	sky.position = Vector2.ZERO
	sky.z_index = -20
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sky)
	var sky2 := sky.duplicate()
	sky2.position.x = 480
	add_child(sky2)

	_static_rect(Rect2(0, ground_y, width, 40), SpriteLib.tile("grass"))
	for x in range(0, int(width), 32):
		var g := Sprite2D.new()
		g.texture = SpriteLib.tile("grass")
		g.centered = false
		g.position = Vector2(x, ground_y)
		g.z_index = -2
		g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(g)
		var d := Sprite2D.new()
		d.texture = SpriteLib.tile("dirt")
		d.centered = false
		d.position = Vector2(x, ground_y + 32)
		d.z_index = -3
		d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(d)

	for prop in data.get("props", []):
		_spawn_prop(prop)
	for box in data.get("caixas", []):
		var crate := preload("res://scenes/crate.tscn").instantiate()
		crate.global_position = Vector2(float(box.get("x", 0)), ground_y - 16)
		add_child(crate)
		crate.setup(String(box.get("loot", "moedas")))
	_left_wall()


func _spawn_prop(prop: Dictionary) -> void:
	var tipo := String(prop.get("tipo", ""))
	var x := float(prop.get("x", 0))
	match tipo:
		"celeiro", "celeiro_fogo":
			_sprite_prop(SpriteLib.tile("barn"), Vector2(x, ground_y - 64), Vector2(4, 4))
			if tipo == "celeiro_fogo":
				_sprite_prop(SpriteLib.tile("fire"), Vector2(x + 20, ground_y - 48), Vector2(2, 2))
		"milho":
			var w := int(prop.get("w", 160))
			for i in range(0, w, 18):
				_sprite_prop(SpriteLib.tile("corn"), Vector2(x + i, ground_y - 32), Vector2(2, 2))
		"cerca":
			var w2 := int(prop.get("w", 120))
			for i in range(0, w2, 32):
				_sprite_prop(SpriteLib.tile("fence"), Vector2(x + i, ground_y - 32), Vector2(2, 2))
		"silo":
			_static_rect(Rect2(x, ground_y - 96, 28, 96), SpriteLib.tile("metal"))
		"plataforma":
			var y := float(prop.get("y", 160))
			var w3 := float(prop.get("w", 120))
			_static_rect(Rect2(x, y, w3, 16), SpriteLib.tile("wood"))


func _sprite_prop(tex: Texture2D, pos: Vector2, scl: Vector2) -> void:
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	s.scale = scl
	s.z_index = -1
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(s)


func _static_rect(rect: Rect2, tex: Texture2D = null) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.position
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	col.position = rect.size / 2.0
	body.add_child(col)
	if tex:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body.add_child(s)
	add_child(body)


func _left_wall() -> void:
	_static_rect(Rect2(-24, 0, 24, 270))
	_static_rect(Rect2(float(data.get("largura", 5600)), 0, 24, 270))


func _spawn_blockers(left: float, right: float) -> void:
	var a := StaticBody2D.new()
	a.name = "ArenaWallL"
	a.position = Vector2(left - 8, 0)
	var ca := CollisionShape2D.new()
	var sa := RectangleShape2D.new()
	sa.size = Vector2(16, 270)
	ca.shape = sa
	ca.position = Vector2(8, 135)
	a.add_child(ca)
	add_child(a)
	var b := a.duplicate()
	b.name = "ArenaWallR"
	b.position = Vector2(right - 8, 0)
	add_child(b)


func _clear_blockers() -> void:
	var l := get_node_or_null("ArenaWallL")
	var r := get_node_or_null("ArenaWallR")
	if l:
		l.queue_free()
	if r:
		r.queue_free()


func _spawn_npc(quem: String, x: float) -> void:
	var npc := Sprite2D.new()
	npc.position = Vector2(x, ground_y - 24)
	npc.texture = SpriteLib.ui("portrait_kiko")
	npc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	match quem:
		"juliana":
			npc.modulate = Color(1.0, 0.75, 0.85)
		"fernanda":
			npc.modulate = Color(0.75, 0.9, 1.0)
		"raquel":
			npc.modulate = Color(1.0, 0.85, 0.55)
	add_child(npc)


func _make_rain() -> void:
	var rain := CPUParticles2D.new()
	rain.name = "Rain"
	rain.amount = 180
	rain.lifetime = 1.1
	rain.direction = Vector2(-0.2, 1)
	rain.spread = 8.0
	rain.gravity = Vector2.ZERO
	rain.initial_velocity_min = 220.0
	rain.initial_velocity_max = 280.0
	rain.emitting = true
	rain.z_index = 40
	rain.color = Color(0.65, 0.75, 0.9, 0.55)
	rain.local_coords = false
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(280, 8)
	add_child(rain)
	var t := Timer.new()
	t.wait_time = 0.05
	t.autostart = true
	add_child(t)
	t.timeout.connect(func():
		if cam:
			rain.global_position = Vector2(cam.get_screen_center_position().x, 0)
	)
