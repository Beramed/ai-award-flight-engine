extends Area2D
class_name PowHostage
## Refém estilo POW: encosta, solta caixa, +1000 e corre para fora.

var quem := "juliana"
var bonus := "fuzil"
var rescued := false
var run_dir := -1.0
var run_speed := 96.0
var spr: AnimatedSprite2D
var tag: Label
var help: Label
var blink_t := 0.0


func setup(p_quem: String, p_bonus: String) -> void:
	quem = p_quem
	bonus = p_bonus
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	z_index = 5
	add_to_group("pow")
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = SpriteLib.kiko_frames()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = true
	spr.scale = Vector2(0.48, 0.48)
	spr.play("crouch" if spr.sprite_frames.has_animation("crouch") else "idle")
	match quem:
		"juliana":
			spr.modulate = Color(1.05, 0.72, 0.88)
		"fernanda":
			spr.modulate = Color(0.72, 0.88, 1.08)
		"raquel":
			spr.modulate = Color(1.05, 0.88, 0.58)
		_:
			spr.modulate = Color(0.95, 0.92, 0.7)
	add_child(spr)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(22, 28)
	col.shape = shape
	add_child(col)
	tag = Label.new()
	tag.text = "POW"
	tag.position = Vector2(-14, -38)
	tag.add_theme_font_size_override("font_size", 8)
	tag.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15, 1))
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	tag.add_theme_constant_override("outline_size", 3)
	add_child(tag)
	help = Label.new()
	help.text = "HELP!"
	help.position = Vector2(-16, -50)
	help.add_theme_font_size_override("font_size", 7)
	help.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25, 1))
	help.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	help.add_theme_constant_override("outline_size", 3)
	add_child(help)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if rescued:
		position.x += run_dir * run_speed * delta
		if spr and spr.sprite_frames.has_animation("run"):
			spr.play("run")
		elif spr:
			spr.play("walk")
		if absf(position.x) > 80.0 and (global_position.x < -40.0 or global_position.x > 5800.0):
			queue_free()
		elif global_position.x < -40.0 or global_position.x > 5800.0:
			queue_free()
		return
	blink_t += delta
	if help:
		help.modulate.a = 1.0 if fmod(blink_t, 0.7) < 0.4 else 0.15


func _on_body_entered(body: Node) -> void:
	if rescued or body == null or not body.is_in_group("player"):
		return
	_rescue(body as Node2D)


func _rescue(player: Node2D) -> void:
	rescued = true
	monitoring = false
	if help:
		help.visible = false
	if tag:
		tag.text = "OK!"
	GameState.rescue_pow()
	GameState.add_score(1000)
	ArcadeFX.score_pop(global_position, 1000, Color(1.0, 0.95, 0.35, 1))
	ArcadeFX.float_text(global_position + Vector2(0, -8), "OBRIGADO!", Color(1.0, 0.82, 0.35, 1))
	_apply_bonus()
	_drop_crate()
	run_dir = -1.0
	if player:
		run_dir = -1.0 if player.global_position.x >= global_position.x else 1.0
	if spr:
		spr.flip_h = run_dir < 0.0
	var tw := create_tween()
	tw.tween_interval(2.4)
	tw.tween_callback(queue_free)


func _apply_bonus() -> void:
	match bonus:
		"fuzil":
			pass
		"municao":
			GameState.refill_ammo()
			GameState.add_coins(25)
		"cura":
			GameState.heal_full()
		_:
			pass


func _drop_crate() -> void:
	var loot := "fuzil"
	match bonus:
		"fuzil":
			loot = "fuzil"
		"municao":
			loot = "municao"
		"cura":
			loot = "kit"
		_:
			loot = bonus if bonus != "" else "moedas"
	var crate := preload("res://scenes/crate.tscn").instantiate()
	var parent := get_parent()
	if parent == null:
		parent = get_tree().current_scene
	parent.add_child(crate)
	crate.global_position = global_position + Vector2(14.0 * -run_dir, 10.0)
	crate.setup(loot, "crate")
