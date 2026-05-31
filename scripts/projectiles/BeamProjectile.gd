extends Node2D

# ──────────────────────────────────────────────
#  BeamProjectile.gd
#  Attached as a child of MP35.  Fires forward
#  along the gun's +X axis each physics frame.
#  Applies NanoBurn DoT that stacks on enemies.
# ──────────────────────────────────────────────

var tick_damage: int = 4
var beam_range: float = 500.0

@onready var ray: RayCast2D = $RayCast2D
@onready var tick_timer: Timer = $TickTimer
@onready var beam_line: Line2D = $Line2D   # visual line

var _current_hit: Node = null


func _ready() -> void:
	ray.target_position = Vector2(beam_range, 0.0)
	ray.enabled = true
	tick_timer.wait_time = 0.1
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()


func _physics_process(_delta: float) -> void:
	ray.force_raycast_update()
	if ray.is_colliding():
		var hit_point := to_local(ray.get_collision_point())
		_current_hit = _resolve_target(ray.get_collider())
		_update_line(hit_point)
	else:
		_current_hit = null
		_update_line(Vector2(beam_range, 0.0))


func _on_tick() -> void:
	if _current_hit == null:
		return
	if _current_hit.has_method("take_damage"):
		_current_hit.take_damage(tick_damage)
	# Apply / refresh NanoBurn stack
	if _current_hit.has_method("apply_nano_burn"):
		_current_hit.apply_nano_burn(tick_damage)


func _resolve_target(target: Node) -> Node:
	if target == null:
		return null
	if target.has_method("take_damage") or target.has_method("apply_nano_burn"):
		return target
	if target.get_parent() != null:
		return _resolve_target(target.get_parent())
	return target


func _update_line(end: Vector2) -> void:
	if beam_line:
		beam_line.clear_points()
		beam_line.add_point(Vector2.ZERO)
		beam_line.add_point(end)
