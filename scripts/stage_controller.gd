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
var _chunks: Dictionary = {}
const CHUNK_W := 640.0
const LAKE_LEFT := 2080.0
const LAKE_RIGHT := 2480.0
const STREAM_RADIUS := 1100.0


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
	if OS.get_environment("KIKO_MAPSHOT") == "":
		_make_rain()
	set_process(true)
	busy = true
	if OS.get_environment("KIKO_MAPSHOT") != "":
		await _save_mapshots()
		return
	await _try_start_events()
	busy = false


func _process(_delta: float) -> void:
	_stream_chunks()
	if GameState.paused_by_dialog or waiting_arena or busy:
		return
	_advance_by_x()


func _save_mapshots() -> void:
	var cap := OS.get_environment("KIKO_MAPSHOT")
	if hud:
		hud.visible = false
	if player:
		player.visible = false
	for n in get_tree().get_nodes_in_group("crates"):
		n.visible = false
	if cam:
		cam.position_smoothing_enabled = false
		cam.drag_horizontal_enabled = false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var spots := [
		[120.0, "start"],
		[1280.0, "farm"],
		[2400.0, "lake"],
		[3300.0, "fields"],
		[4300.0, "approach"],
		[5300.0, "arena"],
	]
	for spot in spots:
		if player:
			player.global_position = Vector2(float(spot[0]), ground_y - 20.0)
		if cam:
			cam.reset_smoothing()
			cam.force_update_scroll()
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/map_%s.png" % [cap, String(spot[1])])
	get_tree().quit()


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
			if OS.get_environment("KIKO_CAPTURE") != "" and OS.get_environment("KIKO_DIALOG") != "1":
				return
			if OS.get_environment("KIKO_DEMO") != "" and OS.get_environment("KIKO_DIALOG") != "1":
				return
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
	var is_boss := ev.has("chefe")
	if is_boss:
		cam.lock_arena(float(ev.get("left", 0)), float(ev.get("right", 480)))
		_spawn_blockers(float(ev.get("left", 0)), float(ev.get("right", 480)))
		await dialog.play(Roteiro.dialogo(stage_number, "chefe"))
	for onda in ev.get("ondas", []):
		_spawn_pack(onda)
		await _wait_enemies_dead()
	if is_boss:
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
		var id := String(info.get("id", "javali_investida"))
		var node: Node2D
		if bool(info.get("boss", false)) or id == "mae_javali":
			node = preload("res://scenes/boss_mae_javali.tscn").instantiate()
		else:
			node = preload("res://scenes/enemy.tscn").instantiate()
		var data := Roteiro.inimigo(id)
		var y := ground_y
		if bool(data.get("airborne", false)):
			y = ground_y - (118.0 if String(data.get("kind", "")) == "bird" else 102.0)
		node.global_position = Vector2(float(info.get("x", 400)), y)
		add_child(node)
		node.setup(id, int(info.get("facing", -1)))
		if info.has("loot"):
			node.set("loot_kind", String(info.get("loot")))


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
	player.died.connect(func(): player.spawn_point = Vector2(max(player.global_position.x, start.x), start.y))
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
	_add_parallax_layers()
	_build_ground(width)
	_build_lake_and_bridge()
	_paint_terrain(width)
	_build_farm_objects()
	for prop in data.get("props", []):
		_spawn_prop(prop)
	for box in data.get("caixas", []):
		_breakable("crate", float(box.get("x", 0)), String(box.get("loot", "moedas")))
	_left_wall()


func _chunk_node(x: float) -> Node2D:
	var i := int(floor(x / CHUNK_W))
	if _chunks.has(i):
		return _chunks[i]
	var n := Node2D.new()
	n.name = "Chunk_%d" % i
	n.position = Vector2(i * CHUNK_W, 0)
	n.add_to_group("world_chunks")
	add_child(n)
	_chunks[i] = n
	return n


func _add_world_child(node: Node, x: float, y: float) -> void:
	var chunk := _chunk_node(x)
	chunk.add_child(node)
	if node is Node2D:
		(node as Node2D).position = Vector2(x - chunk.position.x, y)


func _stream_chunks() -> void:
	if cam == null or _chunks.is_empty():
		return
	var cx := cam.get_screen_center_position().x
	for i in _chunks.keys():
		var n: Node2D = _chunks[i]
		var mid := float(i) * CHUNK_W + CHUNK_W * 0.5
		n.visible = absf(mid - cx) < STREAM_RADIUS


func _add_parallax_layers() -> void:
	var pb := ParallaxBackground.new()
	var sky_tex := SpriteLib.tile("fazenda_sky")
	if sky_tex:
		var far := ParallaxLayer.new()
		far.motion_scale = Vector2(0.12, 0.0)
		far.motion_mirroring = Vector2(float(sky_tex.get_width()), 0)
		var sky := Sprite2D.new()
		sky.texture = sky_tex
		sky.centered = false
		sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		far.add_child(sky)
		pb.add_child(far)
	var hill_tex := SpriteLib.tile("hills")
	if hill_tex:
		var mid := ParallaxLayer.new()
		mid.motion_scale = Vector2(0.38, 0.0)
		mid.motion_mirroring = Vector2(float(hill_tex.get_width()), 0)
		var hills := Sprite2D.new()
		hills.texture = hill_tex
		hills.centered = false
		hills.position.y = 168
		hills.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hills.modulate = Color(0.55, 0.48, 0.42, 0.85)
		mid.add_child(hills)
		pb.add_child(mid)
	var fg_tex := SpriteLib.tile("grass_fg")
	if fg_tex:
		var fg := ParallaxLayer.new()
		fg.motion_scale = Vector2(1.18, 0.0)
		fg.motion_mirroring = Vector2(float(fg_tex.get_width()), 0)
		var grass := Sprite2D.new()
		grass.texture = fg_tex
		grass.centered = false
		grass.position.y = 252
		grass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		grass.z_index = 8
		fg.add_child(grass)
		pb.add_child(fg)
	add_child(pb)


func _build_ground(width: float) -> void:
	_static_rect(Rect2(0, ground_y, LAKE_LEFT, 48))
	_static_rect(Rect2(LAKE_RIGHT, ground_y, width - LAKE_RIGHT, 48))


func _build_lake_and_bridge() -> void:
	var lake_w := LAKE_RIGHT - LAKE_LEFT
	var water := Area2D.new()
	water.name = "Lake"
	water.collision_layer = 0
	water.collision_mask = 6
	water.monitoring = true
	var wcol := CollisionShape2D.new()
	var wshape := RectangleShape2D.new()
	wshape.size = Vector2(lake_w, 40)
	wcol.shape = wshape
	wcol.position = Vector2(LAKE_LEFT + lake_w * 0.5, ground_y + 22)
	water.add_child(wcol)
	add_child(water)
	water.body_entered.connect(_on_water_body)
	var wx := LAKE_LEFT
	while wx < LAKE_RIGHT:
		_deco_sprite("water", wx, ground_y - 4, 1.0, -4)
		wx += 32.0
	var bridge_x := LAKE_LEFT - 24.0
	var bridge_w := lake_w + 48.0
	_static_rect(Rect2(bridge_x, ground_y, bridge_w, 12))
	var bx := bridge_x
	while bx < bridge_x + bridge_w:
		_deco_sprite("bridge", bx, ground_y - 4, 1.0, -1)
		bx += 32.0


func _on_water_body(body: Node) -> void:
	if body is PlayerKiko:
		(body as PlayerKiko).call_deferred("fall_in_water")
	elif body.is_in_group("enemies"):
		if body.has_method("take_hit"):
			body.call_deferred("take_hit", 99, Vector2.ZERO)
		else:
			body.call_deferred("queue_free")


func _paint_terrain(width: float) -> void:
	var x := 0.0
	while x < width:
		if x >= LAKE_LEFT and x < LAKE_RIGHT:
			x += 32.0
			continue
		var dirt_zone := x >= 4300.0 or (x >= LAKE_LEFT - 80.0 and x <= LAKE_RIGHT + 80.0)
		_deco_sprite("dirt_road" if dirt_zone else "grass", x, ground_y, 1.0, -2)
		_deco_sprite("dirt", x, ground_y + 16, 1.0, -3)
		x += 32.0


func _build_farm_objects() -> void:
	_solid_prop("gate", 18.0, 1.0, Vector2(0.28, 0.9))
	_breakable("fence", 120.0, "none")
	_breakable("fence", 138.0, "none")
	_breakable("fence", 156.0, "none")
	_breakable("barrel", 188.0, "moedas")
	_breakable("hay", 310.0, "none")
	_breakable("hay", 338.0, "none")
	_solid_prop("rock_block", 250.0)
	_solid_prop("tree", 470.0, 1.2, Vector2(0.32, 0.82))
	_solid_prop("tree", 640.0, 1.2, Vector2(0.32, 0.82))
	_breakable("fence", 700.0, "none")
	_breakable("fence", 718.0, "none")
	_breakable("barrel", 760.0, "granadas")
	_solid_prop("house", 880.0, 1.4)
	_solid_prop("barn_big", 1120.0, 1.45)
	_solid_prop("tree", 1380.0, 1.15, Vector2(0.32, 0.82))
	_solid_prop("house", 1500.0, 1.35)
	_breakable("hay", 1720.0, "none")
	_breakable("crate", 1800.0, "moedas")
	_solid_prop("rock_block", 1920.0)
	_solid_prop("tree", 2000.0, 1.0, Vector2(0.32, 0.82))
	_solid_prop("tree", 2520.0, 1.0, Vector2(0.32, 0.82))
	_breakable("barrel", 2620.0, "municao")
	_solid_prop("house", 2840.0, 1.35)
	_solid_prop("tree", 3180.0, 1.15, Vector2(0.32, 0.82))
	_solid_prop("tree", 3340.0, 1.15, Vector2(0.32, 0.82))
	_breakable("hay", 3460.0, "none")
	_breakable("fence", 3600.0, "none")
	_breakable("fence", 3618.0, "none")
	_solid_prop("shed", 3860.0, 1.4)
	_solid_prop("tree", 4040.0, 1.0, Vector2(0.32, 0.82))
	_breakable("barrel", 4180.0, "kit")
	_solid_prop("rock_block", 4420.0)
	_solid_prop("rock_block", 4560.0)
	_solid_prop("rock_block", 5340.0)


func _solid_prop(tex_name: String, x: float, scl := 1.0, col_scale := Vector2(0.86, 0.92)) -> void:
	var tex := SpriteLib.tile(tex_name)
	if tex == null:
		return
	var w := float(tex.get_width()) * scl
	var h := float(tex.get_height()) * scl
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.scale = Vector2(scl, scl)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = -1
	body.add_child(spr)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w * col_scale.x, h * col_scale.y)
	col.shape = shape
	col.position = Vector2(w * 0.5, h - shape.size.y * 0.5)
	body.add_child(col)
	_add_world_child(body, x, ground_y - h)


func _deco_sprite(tex_name: String, x: float, y: float, scl := 1.0, z := -2) -> void:
	var tex := SpriteLib.tile(tex_name)
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = Vector2.ZERO
	s.scale = Vector2(scl, scl)
	s.z_index = z
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.add_to_group("world_chunk")
	_add_world_child(s, x, y)


func _breakable(kind: String, x: float, loot := "moedas") -> void:
	var crate := preload("res://scenes/crate.tscn").instantiate()
	_add_world_child(crate, x, ground_y - 10.0)
	crate.setup(loot, kind)


func _spawn_prop(prop: Dictionary) -> void:
	var tipo := String(prop.get("tipo", ""))
	var x := float(prop.get("x", 0))
	match tipo:
		"celeiro":
			_solid_prop("barn_big", x, 1.45)
		"celeiro_fogo":
			_solid_prop("shed", x, 1.4)
			_deco_sprite("fire", x + 10.0, ground_y - 28.0, 1.1, 1)
		"milho":
			var w := int(prop.get("w", 160))
			for i in range(0, w, 14):
				_deco_sprite("corn", x + float(i), ground_y - 18.0, 1.1, -1)
		"cerca":
			var w2 := int(prop.get("w", 120))
			for i in range(0, w2, 18):
				_breakable("fence", x + float(i), "none")
		"silo":
			_static_rect(Rect2(x, ground_y - 52, 16, 52), SpriteLib.tile("metal"))
		"plataforma":
			var y := float(prop.get("y", 160))
			var w3 := float(prop.get("w", 120))
			_static_rect(Rect2(x, y, w3, 16), SpriteLib.tile("wood"))


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
