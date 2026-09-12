extends Camera2D
class_name StageCamera

var lock_left := 0
var stage_right := 5600
var arena := false


func _ready() -> void:
	enabled = true
	make_current()
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
	limit_top = 0
	limit_bottom = 270
	limit_left = 0
	limit_right = int(stage_right)
	drag_horizontal_enabled = true
	drag_left_margin = 0.18
	drag_right_margin = 0.18


func configure(width: float) -> void:
	stage_right = width
	limit_right = int(width)


func _process(_delta: float) -> void:
	if arena:
		return
	var center := get_screen_center_position().x
	var new_left := int(center - 240)
	if new_left > lock_left:
		lock_left = new_left
	limit_left = lock_left
	limit_right = int(stage_right)


func lock_arena(left: float, right: float) -> void:
	arena = true
	limit_left = int(left)
	limit_right = int(right)
	lock_left = int(left)


func unlock_arena() -> void:
	arena = false
	limit_right = int(stage_right)
