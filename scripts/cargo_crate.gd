extends CharacterBody2D
class_name CargoCrate

const GRAVITY := 820.0

var attached := true
var host: Node2D
var loot := ""
var sway_t := 0.0
var broken := false
var cable: Line2D
var spr: Sprite2D


func setup_attached(p_host: Node2D, p_loot: String) -> void:
	host = p_host
	loot = p_loot
	attached = true
	collision_layer = 4
	collision_mask = 0
	add_to_group("crates")
	add_to_group("breakable")
	spr = Sprite2D.new()
	spr.name = "Sprite"
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = true
	var tex := SpriteLib.fx("drone_crate")
	if tex == null:
		tex = SpriteLib.ui("crate")
	spr.texture = tex
	add_child(spr)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 14)
	col.shape = shape
	add_child(col)
	cable = Line2D.new()
	cable.width = 1.2
	cable.default_color = Color(0.55, 0.48, 0.38, 1)
	cable.z_index = -1
	add_child(cable)
	position = Vector2(0, 22)


func _physics_process(delta: float) -> void:
	if broken:
		return
	if attached and host != null and is_instance_valid(host):
		sway_t += delta
		position = Vector2(sin(sway_t * 3.2) * 3.5, 20.0 + sin(sway_t * 5.0) * 1.5)
		if cable:
			cable.points = PackedVector2Array([Vector2(0, -18), Vector2(0, -2)])
		return
	velocity.y += GRAVITY * delta
	move_and_slide()
	if is_on_floor():
		_land()


func detach(inherit_vel := Vector2.ZERO) -> void:
	if not attached:
		return
	attached = false
	var world_pos := global_position
	var parent := get_tree().current_scene
	if host and host.get_parent():
		parent = host.get_parent()
	reparent(parent)
	global_position = world_pos
	collision_mask = 1
	collision_layer = 4
	velocity = Vector2(inherit_vel.x * 0.45, 30.0)
	if cable:
		cable.queue_free()
		cable = null


func take_hit(_amount: int, knock := Vector2.ZERO) -> void:
	if broken:
		return
	if attached:
		detach(knock)
		return
	_land()


func _land() -> void:
	if broken:
		return
	broken = true
	collision_layer = 0
	collision_mask = 0
	if loot != "" and loot != "none":
		var p := preload("res://scenes/pickup.tscn").instantiate()
		p.global_position = global_position + Vector2(0, -6)
		match loot:
			"fuzil", "doze", "sniper", "granadas", "kit", "seringa", "municao":
				p.setup(loot)
			_:
				p.setup("coin")
		get_tree().current_scene.add_child(p)
	queue_free()
