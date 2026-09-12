extends Camera2D
class_name StageCamera

var lock_left := 0
var stage_right := 5600
var arena := false


func _ready() -> void:
	enabled = true
	make_current()
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	limit_top = 0
	limit_bottom = 270
	limit_left = 0
	limit_right = int(stage_right)
	drag_horizontal_enabled = true
	drag_left_margin = 0.30
	drag_right_margin = 0.60
	drag_vertical_enabled = false


func configure(width: float) -> void:
	stage_right = width
	limit_right = int(width)


func _process(_delta: float) -> void:
	if arena:
		return
	# One continuous farm: never snap to 480px screens or freeze at an edge.
	limit_left = 0
	limit_right = int(stage_right)


func lock_arena(left: float, right: float) -> void:
	arena = true
	limit_left = int(left)
	limit_right = int(right)
	lock_left = int(left)


func unlock_arena() -> void:
	arena = false
	limit_left = 0
	limit_right = int(stage_right)
	lock_left = 0
