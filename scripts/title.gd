extends Control

enum Screen { PRESS_START, MAIN_MENU, OPTIONS }

var screen: int = Screen.PRESS_START
var blink := 0.0
var menu_index := 0
var waiting_bind := ""

@onready var poster: TextureRect = $Poster
@onready var press_start: Label = $PressStart
@onready var menu: VBoxContainer = $Menu
@onready var options: Control = $Options
@onready var crest: TextureRect = $Options/Crest
@onready var btn_1p: Button = $Menu/Btn1P
@onready var btn_2p: Button = $Menu/Btn2P
@onready var btn_opt: Button = $Menu/BtnOpt
@onready var diff_easy: Button = $Options/Panel/DiffRow/Easy
@onready var diff_med: Button = $Options/Panel/DiffRow/Medium
@onready var diff_hard: Button = $Options/Panel/DiffRow/Hard
@onready var lives_label: Label = $Options/Panel/LivesRow/Value
@onready var continues_label: Label = $Options/Panel/ContinuesRow/Value
@onready var shoot_btn: Button = $Options/Panel/Binds/Shoot
@onready var jump_btn: Button = $Options/Panel/Binds/Jump
@onready var special_btn: Button = $Options/Panel/Binds/Special
@onready var bind_hint: Label = $Options/Panel/BindHint


func _ready() -> void:
	GameState.waiting_rebind = ""
	poster.texture = load("res://assets/ui/title_poster.png")
	crest.texture = load("res://assets/ui/options_crest.jpg")
	btn_1p.pressed.connect(func(): _start_game(1))
	btn_2p.pressed.connect(func(): _start_game(2))
	btn_opt.pressed.connect(_open_options)
	$Options/Panel/Back.pressed.connect(_close_options)
	diff_easy.pressed.connect(func(): _set_diff(GameState.Difficulty.EASY))
	diff_med.pressed.connect(func(): _set_diff(GameState.Difficulty.MEDIUM))
	diff_hard.pressed.connect(func(): _set_diff(GameState.Difficulty.HARD))
	$Options/Panel/LivesRow/Minus.pressed.connect(func(): _nudge_lives(-1))
	$Options/Panel/LivesRow/Plus.pressed.connect(func(): _nudge_lives(1))
	$Options/Panel/ContinuesRow/Minus.pressed.connect(func(): _nudge_continues(-1))
	$Options/Panel/ContinuesRow/Plus.pressed.connect(func(): _nudge_continues(1))
	shoot_btn.pressed.connect(func(): _begin_bind("shoot"))
	jump_btn.pressed.connect(func(): _begin_bind("jump"))
	special_btn.pressed.connect(func(): _begin_bind("rage"))
	$PressCatch.pressed.connect(_on_press_start)
	_show(Screen.PRESS_START)
	_refresh_options()
	if OS.get_environment("KIKO_CAPTURE") != "":
		await RenderingServer.frame_post_draw
		await get_tree().create_timer(0.25).timeout
		get_viewport().get_texture().get_image().save_png(
			OS.get_environment("KIKO_CAPTURE") + "/title_full_poster.png"
		)


func _process(delta: float) -> void:
	if screen != Screen.PRESS_START:
		press_start.modulate.a = 1.0
		return
	blink += delta
	press_start.modulate.a = 1.0 if fmod(blink, 0.9) < 0.55 else 0.12


func _unhandled_input(event: InputEvent) -> void:
	if GameState.waiting_rebind != "" and event is InputEventKey and event.pressed and not event.echo:
		GameState.rebind(GameState.waiting_rebind, event)
		_refresh_options()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
		if screen == Screen.OPTIONS:
			_close_options()
		elif screen == Screen.MAIN_MENU:
			_show(Screen.PRESS_START)
		get_viewport().set_input_as_handled()
		return
	if screen == Screen.PRESS_START and (event.is_action_pressed("ui_start") or event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept")):
		_on_press_start()
		get_viewport().set_input_as_handled()
		return
	if screen == Screen.MAIN_MENU:
		if event.is_action_pressed("ui_start") or event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept"):
			_activate_menu()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down") or event.is_action_pressed("aim_down"):
			menu_index = (menu_index + 1) % 3
			_highlight_menu()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up") or event.is_action_pressed("aim_up"):
			menu_index = (menu_index + 2) % 3
			_highlight_menu()
			get_viewport().set_input_as_handled()


func _on_press_start() -> void:
	if screen != Screen.PRESS_START:
		return
	_show(Screen.MAIN_MENU)


func _show(which: int) -> void:
	screen = which
	press_start.visible = which == Screen.PRESS_START
	$PressCatch.visible = which == Screen.PRESS_START
	menu.visible = which == Screen.MAIN_MENU
	options.visible = which == Screen.OPTIONS
	poster.visible = which != Screen.OPTIONS
	if which == Screen.MAIN_MENU:
		menu_index = 0
		_highlight_menu()
	if which == Screen.OPTIONS:
		_refresh_options()


func _highlight_menu() -> void:
	var buttons := [btn_1p, btn_2p, btn_opt]
	for i in buttons.size():
		buttons[i].modulate = Color(1.15, 0.95, 0.35) if i == menu_index else Color.WHITE


func _activate_menu() -> void:
	match menu_index:
		0:
			_start_game(1)
		1:
			_start_game(2)
		2:
			_open_options()


func _start_game(count: int) -> void:
	GameState.player_count = count
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/stage_1.tscn")


func _open_options() -> void:
	_show(Screen.OPTIONS)


func _close_options() -> void:
	_show(Screen.MAIN_MENU)


func _set_diff(value: int) -> void:
	GameState.difficulty = value
	_refresh_options()


func _nudge_lives(delta: int) -> void:
	GameState.starting_lives = clampi(GameState.starting_lives + delta, 3, 7)
	_refresh_options()


func _nudge_continues(delta: int) -> void:
	GameState.max_continues = clampi(GameState.max_continues + delta, 1, 5)
	_refresh_options()


func _begin_bind(action: String) -> void:
	GameState.waiting_rebind = action
	bind_hint.text = "PRESSIONE A TECLA PARA %s..." % action.to_upper()
	_refresh_options()


func _refresh_options() -> void:
	_paint_diff(diff_easy, GameState.difficulty == GameState.Difficulty.EASY)
	_paint_diff(diff_med, GameState.difficulty == GameState.Difficulty.MEDIUM)
	_paint_diff(diff_hard, GameState.difficulty == GameState.Difficulty.HARD)
	lives_label.text = str(GameState.starting_lives)
	continues_label.text = str(GameState.max_continues)
	var shoot_txt := "..." if GameState.waiting_rebind == "shoot" else GameState.action_key_name("shoot")
	var jump_txt := "..." if GameState.waiting_rebind == "jump" else GameState.action_key_name("jump")
	var spec_txt := "..." if GameState.waiting_rebind == "rage" else GameState.action_key_name("rage")
	shoot_btn.text = "TIRO  [%s]" % shoot_txt
	jump_btn.text = "PULO  [%s]" % jump_txt
	special_btn.text = "ESPECIAL  [%s]" % spec_txt
	if GameState.waiting_rebind == "":
		bind_hint.text = "Clique no botão e pressione a tecla nova"


func _paint_diff(btn: Button, on: bool) -> void:
	btn.modulate = Color(1.2, 0.85, 0.2) if on else Color(0.75, 0.75, 0.7)
