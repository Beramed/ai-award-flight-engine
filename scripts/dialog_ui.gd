extends CanvasLayer
class_name DialogUI

signal finished

var lines: Array = []
var index := 0
var active := false

@onready var speaker: Label = $Panel/Speaker
@onready var body: Label = $Panel/Body
@onready var hint: Label = $Panel/Hint
@onready var portrait: TextureRect = $Panel/Portrait


func _ready() -> void:
	visible = false
	layer = 20


func play(p_lines: Array) -> void:
	if p_lines.is_empty():
		finished.emit()
		return
	lines = p_lines
	index = 0
	active = true
	visible = true
	GameState.paused_by_dialog = true
	_show_line()
	await finished


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("shoot") or event.is_action_pressed("jump"):
		index += 1
		if index >= lines.size():
			_close()
		else:
			_show_line()
		get_viewport().set_input_as_handled()


func _show_line() -> void:
	var line: Dictionary = lines[index]
	var who: int = int(line.get("who", Roteiro.Speaker.NARRATOR))
	speaker.text = Roteiro.speaker_name(who)
	body.text = String(line.get("text", ""))
	hint.text = "Z / ENTER — continuar  %d/%d" % [index + 1, lines.size()]
	var portrait_name := ""
	match who:
		Roteiro.Speaker.KIKO:
			portrait_name = "portrait_kiko"
		Roteiro.Speaker.SAMURAI:
			portrait_name = "portrait_samurai"
	if portrait_name != "":
		portrait.texture = SpriteLib.ui(portrait_name)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.visible = true
	else:
		portrait.visible = false
	if index == 0 and OS.get_environment("KIKO_CAPTURE") != "":
		get_tree().create_timer(0.08).timeout.connect(_save_dialog_shot, CONNECT_ONE_SHOT)


func _save_dialog_shot() -> void:
	var cap := OS.get_environment("KIKO_CAPTURE")
	if cap == "":
		return
	get_viewport().get_texture().get_image().save_png(cap + "/dialog_samurai.png")


func _close() -> void:
	active = false
	visible = false
	GameState.paused_by_dialog = false
	finished.emit()
