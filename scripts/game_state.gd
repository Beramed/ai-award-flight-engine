extends Node

signal lives_changed(value: int)
signal hp_changed(value: int, maximum: int)
signal weapon_changed(id: String)
signal coins_changed(value: int)
signal score_changed(value: int)
signal rage_changed(value: float, maximum: float)
signal ammo_changed(id: String, value: int)
signal portrait_changed(kind: String)

enum Difficulty { EASY, MEDIUM, HARD }

const MAX_HP := 3
const MAX_RAGE := 100.0
const RAGE_PER_KILL := 20.0
const RAGE_PER_BOSS := 50.0

var difficulty: int = Difficulty.MEDIUM
var starting_lives: int = 3
var max_continues: int = 3
var continues_left: int = 3
var player_count: int = 1

var lives: int = 3
var hp: int = MAX_HP
var coins: int = 0
var score: int = 0
var rage: float = 0.0
var portrait := "base"
var has_vest: bool = false
var current_weapon: String = "pistola"
var grenades: int = 8
var paused_by_dialog: bool = false
var stage_cleared: bool = false
var waiting_rebind: String = ""

var ammo := {
	"pistola": -1,
	"fuzil": 180,
	"doze": 24,
	"sniper": 0,
}

var owned := {
	"pistola": true,
	"fuzil": true,
	"doze": true,
	"sniper": false,
}

var weapon_order := ["pistola", "fuzil", "doze", "sniper"]

var weapon_stats := {
	"pistola": {
		"damage": 3, "cooldown": 0.48, "speed": 390.0, "spread": 1, "pellets": 1,
		"piercing": false, "life": 1.7, "scale": 1.15, "label": "REVOLVER",
	},
	"fuzil": {
		"damage": 1, "cooldown": 0.07, "speed": 420.0, "spread": 3, "pellets": 1,
		"piercing": false, "life": 1.15, "scale": 1.0, "label": "METRALHADORA",
	},
	"doze": {
		"damage": 1, "cooldown": 0.58, "speed": 250.0, "spread": 20, "pellets": 7,
		"piercing": false, "life": 0.28, "scale": 1.0, "label": "ESPINGARDA",
	},
	"sniper": {
		"damage": 4, "cooldown": 0.55, "speed": 520.0, "spread": 0, "pellets": 1,
		"piercing": true, "life": 2.0, "scale": 1.2, "label": "SNIPER",
	},
}


func _ready() -> void:
	_bind_actions()
	reset_run()


func reset_run() -> void:
	lives = starting_lives
	continues_left = max_continues
	hp = MAX_HP
	coins = 0
	score = 0
	rage = 0.0
	portrait = "base"
	grenades = 8
	has_vest = false
	current_weapon = "pistola"
	stage_cleared = false
	waiting_rebind = ""
	ammo = {"pistola": -1, "fuzil": 180, "doze": 24, "sniper": 0}
	owned = {"pistola": true, "fuzil": true, "doze": true, "sniper": false}
	_emit_all()


func difficulty_name() -> String:
	match difficulty:
		Difficulty.EASY:
			return "EASY"
		Difficulty.HARD:
			return "HARD"
		_:
			return "MEDIUM"


func hp_scale() -> float:
	match difficulty:
		Difficulty.EASY:
			return 0.7
		Difficulty.HARD:
			return 1.45
		_:
			return 1.0


func speed_scale() -> float:
	match difficulty:
		Difficulty.EASY:
			return 0.82
		Difficulty.HARD:
			return 1.22
		_:
			return 1.0


func use_continue() -> bool:
	if continues_left <= 0:
		return false
	continues_left -= 1
	lives = starting_lives
	hp = MAX_HP
	lives_changed.emit(lives)
	hp_changed.emit(hp, MAX_HP)
	return true


func action_key_name(action: String) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string((ev as InputEventKey).physical_keycode)
	return "?"


func rebind(action: String, event: InputEventKey) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var copy := event.duplicate() as InputEventKey
	copy.pressed = false
	InputMap.action_add_event(action, copy)
	waiting_rebind = ""


func give_weapon(id: String, extra_ammo: int = 0) -> void:
	if not owned.has(id):
		return
	owned[id] = true
	if ammo[id] >= 0:
		ammo[id] += extra_ammo
	current_weapon = id
	weapon_changed.emit(id)
	ammo_changed.emit(id, ammo[id])


func refill_ammo() -> void:
	if owned["fuzil"]:
		ammo["fuzil"] = max(ammo["fuzil"], 120)
	if owned["doze"]:
		ammo["doze"] = max(ammo["doze"], 24)
	if owned["sniper"]:
		ammo["sniper"] = max(ammo["sniper"], 12)
	grenades = max(grenades, 8)
	ammo_changed.emit(current_weapon, ammo[current_weapon])


func heal_full() -> void:
	hp = MAX_HP
	hp_changed.emit(hp, MAX_HP)


func add_coins(n: int) -> void:
	coins += n
	coins_changed.emit(coins)


func add_score(n: int) -> void:
	score += n
	score_changed.emit(score)


func add_rage(n: float) -> void:
	rage = clamp(rage + n, 0.0, MAX_RAGE)
	rage_changed.emit(rage, MAX_RAGE)


func clear_rage() -> void:
	if rage == 0.0:
		rage_changed.emit(rage, MAX_RAGE)
		return
	rage = 0.0
	rage_changed.emit(rage, MAX_RAGE)


func add_kill_rage(boss: bool = false) -> void:
	add_rage(RAGE_PER_BOSS if boss else RAGE_PER_KILL)


func set_portrait(kind: String) -> void:
	if portrait == kind:
		return
	portrait = kind
	portrait_changed.emit(kind)


func cycle_weapon() -> void:
	var idx := weapon_order.find(current_weapon)
	for i in range(1, weapon_order.size() + 1):
		var nxt: String = weapon_order[(idx + i) % weapon_order.size()]
		if owned[nxt] and (ammo[nxt] != 0):
			current_weapon = nxt
			weapon_changed.emit(current_weapon)
			ammo_changed.emit(current_weapon, ammo[current_weapon])
			return


func consume_shot() -> bool:
	if ammo[current_weapon] < 0:
		return true
	if ammo[current_weapon] <= 0:
		current_weapon = "pistola"
		weapon_changed.emit(current_weapon)
		return true
	ammo[current_weapon] -= 1
	ammo_changed.emit(current_weapon, ammo[current_weapon])
	if ammo[current_weapon] <= 0:
		current_weapon = "pistola"
		weapon_changed.emit(current_weapon)
	return true


func consume_grenade() -> bool:
	if grenades <= 0:
		return false
	grenades -= 1
	ammo_changed.emit("granada", grenades)
	return true


func hit_player(_amount: int = 1) -> bool:
	if has_vest:
		has_vest = false
		return false
	clear_rage()
	hp = max(0, hp - 1)
	hp_changed.emit(hp, MAX_HP)
	return hp <= 0


func lose_life() -> void:
	lives -= 1
	if lives < 0:
		lives = 0
	lives_changed.emit(lives)
	current_weapon = "pistola"
	weapon_changed.emit(current_weapon)


func refill_hp() -> void:
	hp = MAX_HP
	hp_changed.emit(hp, MAX_HP)


func _emit_all() -> void:
	lives_changed.emit(lives)
	hp_changed.emit(hp, MAX_HP)
	weapon_changed.emit(current_weapon)
	coins_changed.emit(coins)
	score_changed.emit(score)
	rage_changed.emit(rage, MAX_RAGE)
	ammo_changed.emit(current_weapon, ammo[current_weapon])
	portrait_changed.emit(portrait)


func _bind_actions() -> void:
	_act("move_left", [KEY_A])
	_act("move_right", [KEY_D])
	_act("aim_up", [KEY_W])
	_act("aim_down", [KEY_S])
	_act("jump", [KEY_SPACE, KEY_Z])
	_act("shoot", [KEY_J, KEY_X])
	_act("grenade", [KEY_G, KEY_C])
	_act("weapon_next", [KEY_Q, KEY_TAB])
	_act("rage", [KEY_R, KEY_SHIFT])
	_act("confirm", [KEY_ENTER, KEY_SPACE, KEY_Z])
	_act("ui_start", [KEY_ENTER, KEY_SPACE])
	_act("p2_move_left", [KEY_LEFT])
	_act("p2_move_right", [KEY_RIGHT])
	_act("p2_aim_up", [KEY_UP])
	_act("p2_aim_down", [KEY_DOWN])
	_act("p2_jump", [KEY_L])
	_act("p2_shoot", [KEY_K])
	_act("p2_rage", [KEY_I])


func _act(name: String, keys: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		if not InputMap.action_has_event(name, ev):
			InputMap.action_add_event(name, ev)
