extends StageController
## Fase 1 — A Fazenda Tomada. Consome Roteiro.fase(1).

func _ready() -> void:
	stage_cleared.connect(_on_stage_cleared)
	await boot(1)


func _on_stage_cleared() -> void:
	await get_tree().create_timer(1.6).timeout
	get_tree().change_scene_to_file("res://scenes/title.tscn")
