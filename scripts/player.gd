extends CharacterBody2D
class_name PlayerKiko

const SPEED := 118.0
const JUMP_VELOCITY := -332.0
const GRAVITY := 820.0
const BODY_SCALE := 0.7

signal died

@export var player_index := 0

var facing := 1
var aim := Vector2.RIGHT
var invuln := 0.0
var shoot_cd := 0.0
var grenade_cd := 0.0
var grenade_t := 0.0
var grenade_spawn_armed := false
var melee_t := 0.0
var rage_t := 0.0
var crouching := false
var locked := false
var spawn_point := Vector2.ZERO
var last_ground := Vector2.ZERO
var _capture_frames := 0
var _feature_capture_done := false

@onready var anim: AnimatedSprite2D = $Anim
@onready var col: CollisionShape2D = $Collision
@onready var melee_box: Area2D = $Melee
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	add_to_group("player")
	if player_index == 0:
		add_to_group("player1")
	else:
		add_to_group("player2")
		var cam_node := get_node_or_null("Camera") as Camera2D
		if cam_node:
			cam_node.enabled = false
	spawn_point = global_position
	last_ground = global_position
	anim.sprite_frames = SpriteLib.kiko_frames()
	anim.play("idle")
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.centered = true
	z_index = 6
	scale = Vector2(BODY_SCALE, BODY_SCALE)
	if OS.get_environment("KIKO_CAPTURE") != "" or OS.get_environment("KIKO_DEMO") != "":
		Engine.max_fps = 60


func _ia(action: String) -> String:
	if player_index == 0:
		return action
	return "p2_" + action


func _physics_process(delta: float) -> void:
	if GameState.paused_by_dialog or locked:
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		if OS.get_environment("KIKO_CAPTURE") != "" or OS.get_environment("KIKO_DEMO") != "":
			_run_capture()
		return

	invuln = max(0.0, invuln - delta)
	if invuln <= 0.0 and GameState.portrait == "hurt" and rage_t <= 0.0:
		GameState.set_portrait("base")
	shoot_cd = max(0.0, shoot_cd - delta)
	grenade_cd = max(0.0, grenade_cd - delta)
	melee_t = max(0.0, melee_t - delta)
	if grenade_t > 0.0:
		grenade_t = max(0.0, grenade_t - delta)
		if grenade_spawn_armed and grenade_t <= 0.28:
			grenade_spawn_armed = false
			_spawn_grenade()
	if rage_t > 0.0:
		rage_t -= delta
		modulate = Color(1.2, 0.7, 0.7)
		if rage_t <= 0.0:
			modulate = Color(1, 1, 1)
			if GameState.portrait == "rage":
				GameState.set_portrait("base")
	else:
		modulate = Color(1, 1, 1)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		last_ground = global_position

	if global_position.y > 320.0:
		fall_in_water()
		return

	var x := Input.get_axis(_ia("move_left"), _ia("move_right"))
	var holding_down := Input.is_action_pressed(_ia("aim_down"))
	crouching = is_on_floor() and holding_down
	if crouching:
		if abs(x) < 0.1:
			x = 0.0
		else:
			x *= 0.42
		var crouch_shape := col.shape as RectangleShape2D
		if crouch_shape:
			crouch_shape.size = Vector2(18, 26)
		col.position.y = 8
	else:
		var stand_shape := col.shape as RectangleShape2D
		if stand_shape:
			stand_shape.size = Vector2(18, 42)
		col.position.y = 0

	if x != 0.0:
		facing = 1 if x > 0.0 else -1
		anim.flip_h = facing < 0
	velocity.x = x * SPEED

	if Input.is_action_just_pressed(_ia("jump")) and is_on_floor() and not crouching:
		velocity.y = JUMP_VELOCITY

	_update_aim()
	_update_muzzle()

	if Input.is_action_just_pressed("weapon_next") and player_index == 0:
		GameState.cycle_weapon()
	if Input.is_action_just_pressed(_ia("rage")):
		_try_rage()
	if Input.is_action_just_pressed("grenade") and player_index == 0:
		_throw_grenade()
	if Input.is_action_pressed(_ia("shoot")):
		_try_attack()

	_play_anim(x)
	move_and_slide()
	_clamp_camera_left()
	if OS.get_environment("KIKO_CAPTURE") != "" or OS.get_environment("KIKO_DEMO") != "":
		_run_capture()


func _run_capture() -> void:
	if OS.get_environment("KIKO_DEMO") == "1":
		_run_aim_demo()
		return
	_capture_frames += 1
	if _run_feature_capture():
		return
	var cap := OS.get_environment("KIKO_CAPTURE")
	if _capture_frames < 16:
		velocity.x = SPEED
		anim.play("walk")
		if _capture_frames == 14:
			GameState.score = 24500
			GameState.score_changed.emit(GameState.score)
			GameState.add_rage(80.0)
		if _capture_frames == 15:
			get_viewport().get_texture().get_image().save_png(cap + "/combat_walk.png")
	elif _capture_frames == 16:
		get_viewport().get_texture().get_image().save_png(cap + "/hud_arcade.png")
		get_viewport().get_texture().get_image().save_png(cap + "/combat_walk.png")
		_spawn_capture_enemy("javali_investida", Vector2(90, 0), -1)
		_spawn_capture_enemy("javali_pedra", Vector2(-70, 0), 1)
		_spawn_capture_enemy("passaro_pedra", Vector2(120, -100), -1)
		_spawn_capture_enemy("drone_carga", Vector2(40, -90), -1)
	elif _capture_frames < 22:
		GameState.set_portrait("rage")
		anim.play("rage")
	elif _capture_frames == 22:
		get_viewport().get_texture().get_image().save_png(cap + "/hud_rage_portrait.png")
		GameState.set_portrait("base")
	elif _capture_frames < 34:
		GameState.current_weapon = "pistola"
		_shoot()
		anim.play("shoot_pistola")
	elif _capture_frames == 34:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_revolver.png")
	elif _capture_frames < 52:
		GameState.current_weapon = "fuzil"
		_shoot()
		anim.play("shoot_fuzil")
	elif _capture_frames == 52:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_fuzil.png")
	elif _capture_frames < 70:
		GameState.current_weapon = "doze"
		_shoot()
		anim.play("shoot_doze")
	elif _capture_frames == 70:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_shotgun.png")
		velocity.y = JUMP_VELOCITY
	elif _capture_frames < 88:
		GameState.current_weapon = "fuzil"
		_shoot()
		anim.play("jump_shoot_fuzil")
	elif _capture_frames == 88:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_jump_shoot.png")
		GameState.current_weapon = "fuzil"
		anim.play("melee_fuzil")
	elif _capture_frames == 94:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_melee.png")
		GameState.current_weapon = "pistola"
		anim.play("melee_pistola")
	elif _capture_frames == 100:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_melee_revolver.png")
		GameState.current_weapon = "doze"
		anim.play("melee_doze")
	elif _capture_frames == 106:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_melee_shotgun.png")
		GameState.current_weapon = "fuzil"
		Input.action_press(_ia("aim_up"))
		Input.action_press(_ia("shoot"))
	elif _capture_frames == 121:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_shoot_up.png")
		Input.action_press(_ia("move_right"))
	elif _capture_frames == 137:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_shoot_diag.png")
		Input.action_release(_ia("aim_up"))
		Input.action_press(_ia("aim_down"))
	elif _capture_frames == 148:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_shoot_diag_down.png")
		Input.action_release(_ia("move_right"))
		velocity.y = JUMP_VELOCITY
	elif _capture_frames == 158:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_shoot_down.png")
		Input.action_release(_ia("aim_down"))
		Input.action_release(_ia("shoot"))
		GameState.grenades = max(GameState.grenades, 2)
		_throw_grenade()
	elif _capture_frames == 155:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_grenade_throw.png")
	elif _capture_frames == 210:
		for node in get_tree().get_nodes_in_group("grenades"):
			if node.has_method("_explode"):
				node._explode()
	elif _capture_frames == 228:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_grenade_boom.png")
		get_viewport().get_texture().get_image().save_png(cap + "/hud_grenade.png")
		GameState.rage = 80.0
		GameState.rage_changed.emit(GameState.rage, GameState.MAX_RAGE)
		invuln = 0.0
		take_hit(1, Vector2(-40, -60))
	elif _capture_frames == 238:
		get_viewport().get_texture().get_image().save_png(cap + "/hud_hurt.png")
		invuln = 0.0
		take_hit(1, Vector2(-20, -40))
	elif _capture_frames == 250:
		get_viewport().get_texture().get_image().save_png(cap + "/hud_hurt2.png")
		invuln = 0.0
		take_hit(1, Vector2(-10, -20))
	elif _capture_frames == 288:
		get_viewport().get_texture().get_image().save_png(cap + "/hud_death.png")


func _run_feature_capture() -> bool:
	if _feature_capture_done:
		return false
	var cap := OS.get_environment("KIKO_CAPTURE")
	if cap == "":
		_feature_capture_done = true
		return false
	var f := _capture_frames
	if f == 2:
		global_position = Vector2(1280, ground_y_ref())
		last_ground = global_position
		velocity = Vector2.ZERO
		GameState.coins = 240
		GameState.coins_changed.emit(GameState.coins)
		z_index = 6
		var stage := get_parent()
		if stage:
			stage.set("busy", true)
			stage.set("event_i", 999)
		for node in get_tree().get_nodes_in_group("enemies"):
			node.queue_free()
	elif f == 14:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_house_front.png")
		Input.action_press(_ia("aim_down"))
		Input.action_press(_ia("shoot"))
		GameState.current_weapon = "pistola"
	elif f == 18:
		get_viewport().get_texture().get_image().save_png(cap + "/combat_shoot_down.png")
	elif f == 24:
		Input.action_release(_ia("aim_down"))
		Input.action_release(_ia("shoot"))
		var shop := get_tree().get_first_node_in_group("shop_ui")
		if shop and shop.has_method("force_open"):
			shop.force_open()
	elif f == 40:
		get_viewport().get_texture().get_image().save_png(cap + "/shop_mineiro.png")
		var shop2 := get_tree().get_first_node_in_group("shop_ui")
		if shop2 and shop2.has_method("close"):
			shop2.close()
		global_position = spawn_point
		_feature_capture_done = true
		_capture_frames = 0
	return not _feature_capture_done or f <= 40


func ground_y_ref() -> float:
	var stage := get_parent()
	if stage and stage.get("ground_y") != null:
		return float(stage.ground_y) - 20.0
	return 216.0


func _run_aim_demo() -> void:
	_capture_frames += 1
	if _capture_frames == 2:
		GameState.current_weapon = "fuzil"
		GameState.grenades = max(GameState.grenades, 4)
		DisplayServer.window_set_size(Vector2i(1440, 810))
	if _capture_frames < 24:
		velocity.x = SPEED
		return
	if _capture_frames == 24:
		Input.action_press(_ia("aim_up"))
		Input.action_press(_ia("shoot"))
	elif _capture_frames == 120:
		Input.action_press(_ia("move_right"))
	elif _capture_frames == 220:
		Input.action_release(_ia("aim_up"))
		Input.action_release(_ia("shoot"))
		Input.action_release(_ia("move_right"))
		_throw_grenade()
	elif _capture_frames == 300:
		for node in get_tree().get_nodes_in_group("grenades"):
			if node.has_method("_explode"):
				node._explode()


func _spawn_capture_enemy(id: String, offset: Vector2, face: int) -> void:
	var e := preload("res://scenes/enemy.tscn").instantiate()
	e.global_position = global_position + offset
	get_tree().current_scene.add_child(e)
	e.setup(id, face)


func _update_muzzle() -> void:
	muzzle.position = Vector2(36 * facing, -20 if not crouching else -10)
	if not is_on_floor():
		muzzle.position = Vector2(36 * facing, -22)
	if aim.y < -0.85:
		muzzle.position = Vector2(2 * facing, -42)
	elif aim.y < -0.25:
		muzzle.position = Vector2(24 * facing, -34)
	elif aim.y > 0.85:
		muzzle.position = Vector2(4 * facing, 22 if crouching or is_on_floor() else 16)
	elif aim.y > 0.25:
		muzzle.position = Vector2(22 * facing, 8)
	$Melee/CollisionShape2D.position.x = 24 * facing
	$Melee/CollisionShape2D.position.y = -8


func _update_aim() -> void:
	var up := Input.is_action_pressed(_ia("aim_up"))
	var down := Input.is_action_pressed(_ia("aim_down"))
	var left := Input.is_action_pressed(_ia("move_left"))
	var right := Input.is_action_pressed(_ia("move_right"))
	var shooting := Input.is_action_pressed(_ia("shoot"))
	aim = Vector2(facing, 0)
	if up and not down:
		if left or right:
			aim = Vector2(facing, -1).normalized()
		else:
			aim = Vector2(0, -1)
	elif down:
		if left or right:
			aim = Vector2(facing, 1).normalized()
		elif shooting or not is_on_floor():
			aim = Vector2(0, 1)
		else:
			aim = Vector2(facing, 0)


func _try_attack() -> void:
	if melee_t > 0.0 or grenade_t > 0.0:
		return
	if aim.y > 0.7:
		_shoot()
		return
	if rage_t > 0.0 or _enemy_in_melee():
		_do_melee()
		return
	_shoot()


func _enemy_in_melee() -> bool:
	for body in melee_box.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			var dx: float = body.global_position.x - global_position.x
			if sign(dx) == facing or abs(dx) < 18.0:
				return true
	return false


func _do_melee() -> void:
	melee_t = 0.34
	if rage_t > 0.0:
		anim.play("rage")
	else:
		var key := "melee_%s" % GameState.current_weapon
		anim.play(key if anim.sprite_frames.has_animation(key) else "melee")
	for body in melee_box.get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(4 if rage_t > 0.0 else 3, Vector2(facing * 200, -50))


func _shoot() -> void:
	var stats: Dictionary = GameState.weapon_stats[GameState.current_weapon]
	if shoot_cd > 0.0:
		return
	if not GameState.consume_shot():
		return
	shoot_cd = stats["cooldown"]
	anim.play(_shoot_anim_name())
	_spawn_muzzle_fx()
	if GameState.current_weapon in ["pistola", "doze"] or randf() < 0.35:
		_spawn_casing()
	var pellets: int = stats["pellets"]
	var straight_down: bool = aim.y > 0.85 and absf(aim.x) < 0.15
	for i in pellets:
		var dir: Vector2 = Vector2(0, 1) if straight_down else aim.rotated(deg_to_rad(float(stats["spread"])) * (i - (pellets - 1) / 2.0))
		if dir == Vector2.ZERO:
			dir = Vector2(facing, 0)
		_spawn_bullet(dir.normalized(), stats)


func _shoot_anim_name() -> String:
	if aim.y > 0.7:
		if anim.sprite_frames.has_animation("shoot_down_fire") and Input.is_action_pressed(_ia("shoot")):
			return "shoot_down"
		return "shoot_down" if anim.sprite_frames.has_animation("shoot_down") else "crouch"
	if aim.y > 0.25:
		return "shoot_diag_down" if anim.sprite_frames.has_animation("shoot_diag_down") else "crouch"
	if crouching:
		return "crouch_shoot" if anim.sprite_frames.has_animation("crouch_shoot") else "crouch"
	if aim.y < -0.7:
		return "shoot_up"
	if aim.y < -0.25:
		return "shoot_diag"
	var weapon := GameState.current_weapon
	var air := not is_on_floor()
	if air:
		if weapon == "fuzil":
			return "jump_shoot_fuzil"
		return "jump_shoot"
	if weapon == "pistola":
		return "shoot_pistola"
	if weapon == "fuzil":
		return "shoot_fuzil"
	if weapon == "doze":
		return "shoot_doze"
	return "shoot"


func _spawn_bullet(dir: Vector2, stats: Dictionary) -> void:
	var b := preload("res://scenes/bullet.tscn").instantiate()
	b.global_position = muzzle.global_position
	b.setup(dir, stats["speed"], stats["damage"], stats["piercing"], GameState.current_weapon)
	b.life = float(stats.get("life", 1.4))
	b.apply_scale_factor(float(stats.get("scale", 1.0)))
	get_tree().current_scene.add_child(b)


func _spawn_muzzle_fx() -> void:
	var tex_name := ""
	match GameState.current_weapon:
		"pistola":
			tex_name = "muzzle_revolver"
		"fuzil":
			tex_name = "muzzle_fuzil"
		"doze":
			tex_name = "shotgun_blast"
		_:
			return
	var tex := SpriteLib.fx(tex_name)
	if tex == null:
		return
	var flash := Sprite2D.new()
	flash.texture = tex
	flash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flash.centered = true
	flash.position = muzzle.position + Vector2(10 * facing, 0)
	flash.flip_h = facing < 0
	if abs(aim.y) > 0.2:
		flash.position = muzzle.position
		flash.rotation = aim.angle()
		flash.flip_h = false
	match GameState.current_weapon:
		"doze":
			flash.scale = Vector2(0.42, 0.42)
		"fuzil":
			flash.scale = Vector2(0.32, 0.32)
		_:
			flash.scale = Vector2(0.58, 0.58)
	if aim.y > 0.85:
		flash.scale *= 1.45
	add_child(flash)
	var tw := create_tween()
	tw.tween_interval(0.06)
	tw.tween_property(flash, "modulate:a", 0.0, 0.08)
	tw.tween_callback(flash.queue_free)


func _spawn_casing() -> void:
	var tex := SpriteLib.fx("casing")
	if tex == null:
		return
	var casing := preload("res://scenes/casing.tscn").instantiate()
	casing.global_position = global_position + Vector2(facing * 4, -16)
	casing.setup(tex, facing)
	get_tree().current_scene.add_child(casing)


func _throw_grenade() -> void:
	if grenade_cd > 0.0 or grenade_t > 0.0 or melee_t > 0.0:
		return
	if not GameState.consume_grenade():
		return
	grenade_cd = 0.72
	grenade_t = 0.48
	grenade_spawn_armed = true
	anim.play("throw_grenade")
	anim.flip_h = facing < 0


func _spawn_grenade() -> void:
	var g := preload("res://scenes/grenade.tscn").instantiate()
	g.global_position = global_position + Vector2(facing * 14, -18)
	g.setup(Vector2(facing * 196, -248))
	get_tree().current_scene.add_child(g)


func _try_rage() -> void:
	if rage_t > 0.0:
		return
	if GameState.rage < 60.0:
		return
	GameState.rage = 0.0
	GameState.rage_changed.emit(0.0, GameState.MAX_RAGE)
	rage_t = 10.0
	invuln = 10.0
	GameState.set_portrait("rage")


func fall_in_water() -> void:
	var safe := last_ground if last_ground != Vector2.ZERO else spawn_point
	global_position = safe
	velocity = Vector2.ZERO
	take_hit(1, Vector2(0, -90))


func take_hit(_amount: int = 1, knock := Vector2.ZERO) -> void:
	if invuln > 0.0 or rage_t > 0.0:
		return
	invuln = 1.1
	velocity += knock
	var dead := GameState.hit_player(1)
	if dead:
		_die()
	else:
		anim.play("hurt")
		GameState.set_portrait("hurt")


func _die() -> void:
	locked = true
	anim.play("death")
	GameState.lose_life()
	died.emit()
	await get_tree().create_timer(1.25).timeout
	if GameState.lives <= 0:
		if GameState.use_continue():
			global_position = spawn_point
			locked = false
			invuln = 1.5
			return
		get_tree().change_scene_to_file("res://scenes/title.tscn")
		return
	global_position = spawn_point
	locked = false
	invuln = 1.5
	GameState.refill_hp()


func _play_anim(x: float) -> void:
	if grenade_t > 0.0 or melee_t > 0.0 or (anim.animation in ["hurt", "death"] and anim.is_playing()):
		return
	if rage_t > 0.0 and Input.is_action_pressed(_ia("shoot")):
		anim.play("rage")
		return
	if Input.is_action_pressed(_ia("shoot")):
		anim.play(_shoot_anim_name())
	elif aim.y > 0.7:
		anim.play("shoot_down" if anim.sprite_frames.has_animation("shoot_down") else "crouch")
		anim.frame = 0
		anim.pause()
	elif aim.y > 0.25:
		anim.play("shoot_diag_down" if anim.sprite_frames.has_animation("shoot_diag_down") else "crouch")
		anim.frame = 0
		anim.pause()
	elif aim.y < -0.7:
		anim.play("shoot_up")
		anim.frame = 0
		anim.pause()
	elif aim.y < -0.25:
		anim.play("shoot_diag")
		anim.frame = 0
		anim.pause()
	elif not is_on_floor():
		anim.play("jump")
	elif crouching:
		anim.play("crouch")
	elif abs(x) > 0.1:
		anim.play("walk")
	else:
		anim.play("idle")
	anim.flip_h = facing < 0


func _clamp_camera_left() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var left := cam.limit_left + 16
	if global_position.x < left:
		global_position.x = left
		velocity.x = max(velocity.x, 0.0)
