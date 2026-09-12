extends Area2D
class_name ArcadeHitbox
## Caixa de dano (AABB). Separada da física do chão — padrão Unity hurtbox + SFML rectsOverlap.

enum Pose { STAND, CROUCH, AIR, DEAD }

@export var team := "player"
@export var stand_size := Vector2(12, 26)
@export var crouch_size := Vector2(14, 13)
@export var air_size := Vector2(11, 22)
@export var feet_y := 20.0

var pose: int = Pose.STAND
var host: Node = null
var _col: CollisionShape2D
var _shape: RectangleShape2D
var debug_draw := false


func _ready() -> void:
	monitorable = true
	monitoring = true
	collision_layer = 64 if team == "player" else 128
	collision_mask = 0
	add_to_group("hurtbox")
	add_to_group("hurtbox_%s" % team)
	z_index = 60
	_ensure_shape()
	set_pose(Pose.STAND)
	debug_draw = OS.get_environment("KIKO_HITBOX") == "1"
	queue_redraw()


func _ensure_shape() -> void:
	_col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _col == null:
		_col = CollisionShape2D.new()
		_col.name = "CollisionShape2D"
		add_child(_col)
	var existing := _col.shape as RectangleShape2D
	_shape = (existing.duplicate() if existing else RectangleShape2D.new()) as RectangleShape2D
	_col.shape = _shape


func set_pose(p_pose: int) -> void:
	pose = p_pose
	_ensure_shape()
	var size := stand_size
	match p_pose:
		Pose.CROUCH:
			size = crouch_size
		Pose.AIR:
			size = air_size
		Pose.DEAD:
			size = Vector2(18, 8)
		_:
			size = stand_size
	_shape.size = size
	# Pés ancorados: o fundo da caixa não sobe ao agachar (Unity BoxCollider2D).
	_col.position.y = feet_y - size.y * 0.5
	_col.position.x = 0.0
	queue_redraw()


func aabb() -> Rect2:
	if _shape == null or _col == null:
		return Rect2()
	var sx := absf(global_scale.x)
	var sy := absf(global_scale.y)
	var size := Vector2(_shape.size.x * sx, _shape.size.y * sy)
	var center := _col.global_position
	return Rect2(center - size * 0.5, size)


static func overlap(a: Rect2, b: Rect2) -> bool:
	return a.size.x > 0.0 and b.size.x > 0.0 and a.intersects(b)


func receive_hit(amount: int, knock := Vector2.ZERO) -> bool:
	var target: Node = host if host else get_parent()
	if target == null or not is_instance_valid(target):
		return false
	if target.get("dead") == true or target.get("locked") == true:
		return false
	if target.has_method("take_hit"):
		target.take_hit(amount, knock)
		return true
	return false


func _draw() -> void:
	if not debug_draw or _shape == null or _col == null:
		return
	var color := Color(0.2, 1.0, 0.35, 0.9) if team == "player" else Color(1.0, 0.25, 0.2, 0.9)
	var fill := Color(color.r, color.g, color.b, 0.18)
	var r := Rect2(_col.position - _shape.size * 0.5, _shape.size)
	draw_rect(r, fill, true)
	draw_rect(r, color, false, 1.0)
