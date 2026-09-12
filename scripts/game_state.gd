extends Node

signal lives_changed(value: int)
signal hp_changed(value: int, maximum: int)
signal weapon_changed(id: String)
signal coins_changed(value: int)
signal rage_changed(value: float, maximum: float)
signal ammo_changed(id: String, value: int)

const MAX_HP := 8
const MAX_LIVES := 3
const MAX_RAGE := 100.0

var lives: int = MAX_LIVES
var hp: int = MAX_HP
var coins: int = 0
var rage: float = 0.0
var has_vest: bool = false
var current_weapon: String = "pistola"
var grenades: int = 8
var paused_by_dialog: bool = false
var stage_cleared: bool = false

var ammo := {
	"pistola": -1,
	"fuzil": 0,
	"doze": 0,
	"sniper": 0,
}

var owned := {
	"pistola": true,
	"fuzil": false,
	"doze": false,
	"sniper": false,
}

var weapon_order := ["pistola", "fuzil", "doze", "sniper"]

var weapon_stats := {
	"pistola": {"damage": 1, "cooldown": 0.16, "speed": 320.0, "spread": 0, "pellets": 1, "piercing": false},
	"fuzil": {"damage": 1, "cooldown": 0.08, "speed": 380.0, "spread": 2, "pellets": 1, "piercing": false},
	"doze": {"damage": 1, "cooldown": 0.42, "speed": 280.0, "spread": 14, "pellets": 5, "piercing": false},
	"sniper": {"damage": 4, "cooldown": 0.55, "speed": 520.0, "spread": 0, "pellets": 1, "piercing": true},
}


func _ready() -> void:
	_bind_actions()
	reset_run()


func reset_run() -> void:
	lives = MAX_LIVES
	hp = MAX_HP
	coins = 0
	rage = 20.0
	grenades = 8
	has_vest = false
	current_weapon = "pistola"
	stage_cleared = false
	ammo = {"pistola": -1, "fuzil": 0, "doze": 0, "sniper": 0}
	owned = {"pistola": true, "fuzil": false, "doze": false, "sniper": false}
	_emit_all()


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
	rage = min(MAX_RAGE, rage + MAX_RAGE * 0.5)
	hp_changed.emit(hp, MAX_HP)
	rage_changed.emit(rage, MAX_RAGE)


func add_coins(n: int) -> void:
	coins += n
	coins_changed.emit(coins)


func add_rage(n: float) -> void:
	rage = clamp(rage + n, 0.0, MAX_RAGE)
	rage_changed.emit(rage, MAX_RAGE)


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


func hit_player(amount: int = 1) -> bool:
	if has_vest:
		has_vest = false
		return false
	hp -= amount
	hp_changed.emit(hp, MAX_HP)
	if hp <= 0:
		lose_life()
		return true
	return false


func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	hp = MAX_HP
	current_weapon = "pistola"
	hp_changed.emit(hp, MAX_HP)
	weapon_changed.emit(current_weapon)
	if lives < 0:
		lives = 0


func _emit_all() -> void:
	lives_changed.emit(lives)
	hp_changed.emit(hp, MAX_HP)
	weapon_changed.emit(current_weapon)
	coins_changed.emit(coins)
	rage_changed.emit(rage, MAX_RAGE)
	ammo_changed.emit(current_weapon, ammo[current_weapon])


func _bind_actions() -> void:
	_act("move_left", [KEY_A, KEY_LEFT])
	_act("move_right", [KEY_D, KEY_RIGHT])
	_act("aim_up", [KEY_W, KEY_UP])
	_act("aim_down", [KEY_S, KEY_DOWN])
	_act("jump", [KEY_SPACE, KEY_Z])
	_act("shoot", [KEY_J, KEY_X])
	_act("grenade", [KEY_G, KEY_C])
	_act("weapon_next", [KEY_Q, KEY_TAB])
	_act("rage", [KEY_R, KEY_SHIFT])
	_act("confirm", [KEY_ENTER, KEY_SPACE, KEY_Z, KEY_J, KEY_X])


func _act(name: String, keys: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		if not InputMap.action_has_event(name, ev):
			InputMap.action_add_event(name, ev)
