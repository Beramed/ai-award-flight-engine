extends Control

func _ready() -> void:
	GameState.reset_run()
	var art := get_node_or_null("Art") as TextureRect
	if art:
		var sheet := SpriteLib.sheet("kiko_sheet")
		if sheet:
			art.texture = sheet
			art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm") or event.is_action_pressed("jump") or event.is_action_pressed("shoot"):
		get_tree().change_scene_to_file("res://scenes/stage_1.tscn")
