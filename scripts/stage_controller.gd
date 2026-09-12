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
var shop: Node
var shop_zone: Area2D
var shop_hint: Label
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
	if hud and OS.get_environment("KIKO_MAPSHOT") == "":
		await hud.show_banner("MISSION START")
	busy = false


func _process(_delta: float) -> void:
	_stream_chunks()
	_poll_shop_door()
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
			_spawn_pack(ev.get("inimigos", []), true)
		"arena":
			await _run_arena(ev)
		"resgate":
			_run_rescue(ev)
		"loja":
			# Door in the world: press up to enter. Do not auto-pause the stage.
			return
		"vitoria":
			if hud:
				await hud.show_banner("MISSION COMPLETE")
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
		_spawn_pack(onda, false)
		await _wait_enemies_dead()
	if is_boss:
		_clear_blockers()
		cam.unlock_arena()
	hud.show_go()
	waiting_arena = false


func _run_rescue(ev: Dictionary) -> void:
	var quem := String(ev.get("quem", "juliana"))
	_spawn_pow(quem, float(ev.get("x", player.global_position.x + 40)), String(ev.get("bonus", "fuzil")))


func _spawn_pack(pack: Array, watch_go := false) -> void:
	var spawned: Array = []
	var cam_x := 240.0
	if cam:
		cam_x = cam.get_screen_center_position().x
	var half := 240.0
	var margin := 72.0
	for i in pack.size():
		var info: Dictionary = pack[i]
		var id := String(info.get("id", "javali_investida"))
		var node: Node2D
		if bool(info.get("boss", false)) or id == "mae_javali":
			node = preload("res://scenes/boss_mae_javali.tscn").instantiate()
			var y := ground_y
			node.global_position = Vector2(float(info.get("x", cam_x + 180.0)), y)
			add_child(node)
			node.setup(id, int(info.get("facing", -1)))
			spawned.append(node)
			continue
		node = preload("res://scenes/enemy.tscn").instantiate()
		var data := Roteiro.inimigo(id)
		var airborne := bool(data.get("airborne", false))
		var kind := String(data.get("kind", ""))
		var intended_x := float(info.get("x", cam_x + 180.0))
		var from_right := intended_x >= cam_x
		if kind == "drone":
			from_right = int(info.get("facing", -1)) <= 0
		var spawn_x := cam_x + half + margin if from_right else cam_x - half - margin
		spawn_x = clampf(spawn_x + float(i) * 18.0, -48.0, 5720.0)
		if player and absf(spawn_x - player.global_position.x) < 90.0:
			spawn_x = player.global_position.x + (half + margin) * (1.0 if from_right else -1.0)
		var enter_facing := -1 if from_right else 1
		var dest := intended_x
		if from_right:
			dest = clampf(intended_x, cam_x + 36.0, cam_x + 170.0)
		else:
			dest = clampf(intended_x, cam_x - 170.0, cam_x - 36.0)
		dest += float(i) * 30.0 * float(enter_facing)
		var y := ground_y
		if airborne:
			y = ground_y - (118.0 if kind == "bird" else 102.0)
		node.global_position = Vector2(spawn_x, y)
		add_child(node)
		node.setup(id, enter_facing)
		node.set("entering", true)
		node.set("entry_target_x", dest)
		if kind == "drone":
			node.set("ferry", true)
		if info.has("loot"):
			var drop := String(info.get("loot"))
			node.set("loot_kind", drop)
			var held = node.get("cargo")
			if held:
				held.loot = drop
		spawned.append(node)
	if watch_go:
		_flash_go_when_cleared(spawned)


func _flash_go_when_cleared(pack: Array) -> void:
	_watch_pack_clear(pack)


func _watch_pack_clear(pack: Array) -> void:
	await get_tree().create_timer(0.35).timeout
	while true:
		var alive := 0
		for n in pack:
			if n != null and is_instance_valid(n) and not bool(n.get("dead")):
				alive += 1
		if alive == 0:
			if hud and not waiting_arena and not GameState.stage_cleared:
				hud.show_go()
			return
		await get_tree().create_timer(0.22).timeout


func _wait_enemies_dead() -> void:
	await get_tree().process_frame
	while not get_tree().get_nodes_in_group("enemies").is_empty():
		await get_tree().create_timer(0.2).timeout


func _spawn_player() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	var start: Vector2 = data.get("player_start", Vector2(72, 200))
	player.global_position = start
	player.z_index = 6
	add_child(player)
	cam = player.get_node("Camera")
	cam.configure(float(data.get("largura", 5600)))
	player.spawn_point = start
	player.died.connect(func(): player.spawn_point = Vector2(max(player.global_position.x, start.x), start.y))
	if GameState.player_count >= 2:
		var p2: PlayerKiko = preload("res://scenes/player.tscn").instantiate()
		p2.player_index = 1
		p2.global_position = start + Vector2(28, 0)
		p2.z_index = 6
		add_child(p2)
		p2.spawn_point = p2.global_position
		p2.modulate = Color(1.15, 0.92, 0.75)


func _spawn_hud() -> void:
	hud = preload("res://scenes/hud.tscn").instantiate()
	add_child(hud)
	hud.set_stage_title("FASE %d — %s" % [stage_number, String(data.get("nome", ""))])
	dialog = preload("res://scenes/dialog.tscn").instantiate()
	add_child(dialog)
	shop = preload("res://scenes/shop.tscn").instantiate()
	add_child(shop)


func _build_world() -> void:
	var width := float(data.get("largura", 5600))
	_add_sky_parallax()
	_add_panorama(width)
	_build_ground(width)
	_build_lake_and_bridge()
	_build_farm_objects()
	for prop in data.get("props", []):
		var tipo := String(prop.get("tipo", ""))
		# Barns, houses, corn and long fences are already painted in the panorama.
		if tipo in ["celeiro", "celeiro_fogo", "milho", "cerca", "silo"]:
			continue
		_spawn_prop(prop)
	for box in data.get("caixas", []):
		_breakable("crate", float(box.get("x", 0)), String(box.get("loot", "moedas")))
	_spawn_shop_door(2580.0)
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


func _add_sky_parallax() -> void:
	var sky_tex := SpriteLib.tile("fazenda_sky")
	if sky_tex == null:
		return
	var pb := ParallaxBackground.new()
	var far := ParallaxLayer.new()
	far.motion_scale = Vector2(0.14, 0.0)
	far.motion_mirroring = Vector2(float(sky_tex.get_width()), 0)
	var sky := Sprite2D.new()
	sky.texture = sky_tex
	sky.centered = false
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	far.add_child(sky)
	pb.add_child(far)
	add_child(pb)


func _add_panorama(width: float) -> void:
	var panorama := SpriteLib.tile("fazenda_panorama")
	if panorama == null:
		return
	var bg := Sprite2D.new()
	bg.name = "FazendaPanorama"
	bg.texture = panorama
	bg.centered = false
	bg.position = Vector2.ZERO
	bg.z_index = -8
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex_w := float(panorama.get_width())
	var tex_h := float(panorama.get_height())
	if tex_w > 0.0 and tex_h > 0.0:
		bg.scale = Vector2(width / tex_w, 270.0 / tex_h)
	add_child(bg)


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
	var bridge_x := LAKE_LEFT - 24.0
	var bridge_w := lake_w + 48.0
	_static_rect(Rect2(bridge_x, ground_y, bridge_w, 12))


func _on_water_body(body: Node) -> void:
	if body is PlayerKiko:
		(body as PlayerKiko).call_deferred("fall_in_water")
	elif body.is_in_group("enemies"):
		if body.has_method("take_hit"):
			body.call_deferred("take_hit", 99, Vector2.ZERO)
		else:
			body.call_deferred("queue_free")


func _build_farm_objects() -> void:
	# Interactive low props only. Houses, barns and trees stay in the panorama.
	_breakable("fence", 120.0, "none")
	_breakable("fence", 138.0, "none")
	_breakable("barrel", 188.0, "moedas")
	_breakable("hay", 310.0, "none")
	_breakable("hay", 338.0, "none")
	_low_rock(250.0)
	_breakable("fence", 700.0, "none")
	_breakable("barrel", 760.0, "granadas")
	_breakable("hay", 1720.0, "none")
	_breakable("crate", 1800.0, "comida")
	_low_rock(1920.0)
	_breakable("barrel", 2620.0, "municao")
	_breakable("hay", 3460.0, "none")
	_breakable("fence", 3600.0, "none")
	_breakable("barrel", 4180.0, "kit")
	_breakable("crate", 4280.0, "comida")
	_low_rock(4420.0)
	_low_rock(4560.0)
	_low_rock(5340.0)


func _low_rock(x: float) -> void:
	var tex := SpriteLib.tile("rock_block")
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var w := 24.0
	var h := 14.0
	var spr_h := h
	if tex:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.modulate = Color(0.62, 0.48, 0.32, 1)
		spr.z_index = 1
		body.add_child(spr)
		w = float(tex.get_width())
		spr_h = float(tex.get_height())
		h = minf(spr_h, 16.0)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	col.shape = shape
	col.position = Vector2(w * 0.5, spr_h - h * 0.5)
	body.add_child(col)
	_add_world_child(body, x, ground_y - spr_h)


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
		"plataforma":
			var y := float(prop.get("y", 160))
			var w3 := float(prop.get("w", 120))
			_static_rect(Rect2(x, y, w3, 12), SpriteLib.tile("wood"))
		_:
			pass


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


func _spawn_shop_door(x: float) -> void:
	var zone := Area2D.new()
	zone.name = "ShopDoor"
	zone.collision_layer = 0
	zone.collision_mask = 2
	zone.monitoring = true
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(86, 90)
	col.shape = shape
	col.position = Vector2(x, ground_y - 40)
	zone.add_child(col)
	add_child(zone)
	shop_zone = zone

	var board := ColorRect.new()
	board.color = Color(0.18, 0.11, 0.06, 0.95)
	board.size = Vector2(52, 18)
	board.position = Vector2(x - 26, ground_y - 78)
	board.z_index = 11
	add_child(board)
	var title := Label.new()
	title.text = "LOJA"
	title.position = Vector2(x - 24, ground_y - 80)
	title.z_index = 12
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25, 1))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 4)
	add_child(title)

	shop_hint = Label.new()
	shop_hint.text = "W / CIMA : ENTRAR"
	shop_hint.position = Vector2(x - 48, ground_y - 96)
	shop_hint.z_index = 12
	shop_hint.visible = false
	shop_hint.add_theme_font_size_override("font_size", 8)
	shop_hint.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55, 1))
	shop_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	shop_hint.add_theme_constant_override("outline_size", 3)
	add_child(shop_hint)


func _poll_shop_door() -> void:
	if shop == null or shop_zone == null:
		return
	if bool(shop.get("active")):
		if shop_hint:
			shop_hint.visible = false
		return
	var inside := false
	for b in shop_zone.get_overlapping_bodies():
		if b.is_in_group("player"):
			inside = true
			break
	if shop_hint:
		shop_hint.visible = inside
	if inside and Input.is_action_just_pressed("aim_up"):
		shop.call("force_open")


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


func _spawn_pow(quem: String, x: float, bonus: String) -> void:
	var pow := preload("res://scenes/pow_hostage.tscn").instantiate()
	add_child(pow)
	pow.global_position = Vector2(x, ground_y - 18.0)
	pow.setup(quem, bonus)


func _spawn_npc(quem: String, x: float) -> void:
	_spawn_pow(quem, x, "fuzil")


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
