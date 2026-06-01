extends Node2D

# ──────────────────────────────────────────────
#  BeamProjectile.gd
#  Attached as a child of MP35.  Fires forward
#  along the gun's +X axis each physics frame.
#  Applies NanoBurn DoT that stacks on enemies.
# ──────────────────────────────────────────────

var tick_damage: int  = 4
var beam_range: float = 900.0

@onready var ray:       RayCast2D = $RayCast2D
@onready var tick_timer: Timer    = $TickTimer
@onready var beam_line: Line2D   = $Line2D
@onready var glow_line: Line2D   = $GlowLine

var _current_hit: Node   = null
var _hit_point: Vector2  = Vector2.ZERO
var _flicker_t: float    = 0.0


func _ready() -> void:
	ray.target_position = Vector2(beam_range, 0.0)
	ray.enabled = true
	tick_timer.wait_time = 0.1
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()


func _physics_process(delta: float) -> void:
	ray.force_raycast_update()

	var end_local: Vector2
	if ray.is_colliding():
		end_local    = to_local(ray.get_collision_point())
		_hit_point   = ray.get_collision_point()
		_current_hit = _resolve_target(ray.get_collider())
	else:
		_current_hit = null
		end_local    = Vector2(beam_range, 0.0)

	_update_lines(end_local, delta)


func _on_tick() -> void:
	if _current_hit == null:
		return
	if _current_hit.has_method("take_damage"):
		if _current_hit.get_script() and _current_hit.get_script().resource_path.contains("Vat"):
			_current_hit.take_damage(tick_damage, "beam")
		else:
			_current_hit.take_damage(tick_damage)
	if _current_hit.has_method("apply_nano_burn"):
		_current_hit.apply_nano_burn(tick_damage)
	# Small impact spark at hit point
	if _current_hit != null:
		_spawn_spark()


func _update_lines(end: Vector2, delta: float) -> void:
	# Subtle flicker on the glow line width
	_flicker_t += delta * 18.0
	var flicker := 1.0 + sin(_flicker_t) * 0.18

	if beam_line:
		beam_line.clear_points()
		beam_line.add_point(Vector2.ZERO)
		beam_line.add_point(end)

	if glow_line:
		glow_line.width = 10.0 * flicker
		glow_line.clear_points()
		glow_line.add_point(Vector2.ZERO)
		glow_line.add_point(end)


func _spawn_spark() -> void:
	var parent := get_tree().current_scene
	for i in randi_range(2, 4):
		var spark := Polygon2D.new()
		var sz    := randf_range(2.0, 5.0)
		spark.polygon        = PackedVector2Array([Vector2(0, -sz), Vector2(sz * 0.5, sz * 0.5), Vector2(-sz * 0.5, sz * 0.5)])
		spark.color          = Color(0.55, 0.92, 1.0, 0.9)
		spark.global_position = _hit_point
		spark.rotation       = randf() * TAU
		parent.add_child(spark)
		var angle := randf() * TAU
		var spd   := randf_range(30.0, 90.0)
		var dir   := Vector2(cos(angle), sin(angle))
		var tw    := spark.create_tween().set_parallel(true)
		tw.tween_property(spark, "global_position", _hit_point + dir * spd * 0.12, 0.12) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(spark, "color:a", 0.0, 0.12)
		tw.chain().tween_callback(spark.queue_free)


func _resolve_target(target: Node) -> Node:
	if target == null:
		return null
	if target.has_method("take_damage") or target.has_method("apply_nano_burn"):
		return target
	if target.get_parent() != null:
		return _resolve_target(target.get_parent())
	return target
