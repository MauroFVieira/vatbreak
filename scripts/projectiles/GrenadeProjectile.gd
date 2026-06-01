extends Area2D

# ──────────────────────────────────────────────
#  GrenadeProjectile.gd
#  Slow projectile; won't explode until armed (ARM_DISTANCE px).
#  While unarmed the grenade is translucent — a clear visual cue
#  that it won't detonate yet.  Fizzles harmlessly at MAX_RANGE.
# ──────────────────────────────────────────────

var direction: Vector2      = Vector2.RIGHT
var speed: float            = 280.0
var damage: int             = 80
var explosion_radius: float = 96.0

const ARM_DISTANCE := 80.0
const MAX_RANGE    := 560.0

var can_explode: bool         = false
var _distance_travelled: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Start translucent — unarmed state
	modulate.a = 0.35


func _physics_process(delta: float) -> void:
	var move := direction * speed * delta
	position += move
	_distance_travelled += move.length()

	# Tumble in flight
	rotation += delta * 3.5

	if not can_explode:
		# Fade in smoothly as the grenade travels toward arm distance
		modulate.a = lerpf(0.35, 1.0, _distance_travelled / ARM_DISTANCE)
		if _distance_travelled >= ARM_DISTANCE:
			can_explode = true
			modulate.a  = 1.0

	if _distance_travelled >= MAX_RANGE:
		_fizzle()


func _on_body_entered(_body: Node) -> void:
	if not can_explode:
		return
	_explode()


func _explode() -> void:
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius    = explosion_radius
	query.shape     = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 0b110
	var results := space.intersect_shape(query, 32)

	_draw_explosion(true)

	for r in results:
		var col = _resolve_damage_target(r["collider"])
		if col == null or not col.has_method("take_damage"):
			continue
		if col.get_script() and col.get_script().resource_path.contains("Vat"):
			col.take_damage(damage, "grenade")
		else:
			col.take_damage(damage)

	call_deferred("queue_free")


func _fizzle() -> void:
	_draw_explosion(false)
	call_deferred("queue_free")


func _draw_explosion(full: bool) -> void:
	var radius    := explosion_radius if full else explosion_radius * 0.3
	var col_inner := Color(1.0, 0.88, 0.3, 0.9)  if full else Color(0.6, 0.6, 0.55, 0.5)
	var col_outer := Color(1.0, 0.45, 0.05, 0.7) if full else Color(0.4, 0.4, 0.38, 0.3)

	var outer := Polygon2D.new()
	outer.z_index = 5
	outer.color   = col_outer
	var pts_outer := PackedVector2Array()
	for i in 12:
		var a := (i / 12.0) * TAU
		pts_outer.append(Vector2(cos(a), sin(a)) * radius)
	outer.polygon         = pts_outer
	outer.global_position = global_position
	get_parent().add_child(outer)

	var inner := Polygon2D.new()
	inner.z_index = 6
	inner.color   = col_inner
	var pts_inner := PackedVector2Array()
	for i in 10:
		var a := (i / 10.0) * TAU
		pts_inner.append(Vector2(cos(a), sin(a)) * radius * 0.45)
	inner.polygon         = pts_inner
	inner.global_position = global_position
	get_parent().add_child(inner)

	var tw := outer.create_tween().set_parallel(true)
	tw.tween_property(outer, "scale",   Vector2(1.3, 1.3), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(outer, "color:a", 0.0, 0.28)
	tw.tween_property(inner, "color:a", 0.0, 0.18).set_delay(0.06)
	tw.tween_property(inner, "scale",   Vector2(0.5, 0.5), 0.24)
	tw.chain().tween_callback(outer.queue_free)
	tw.chain().tween_callback(inner.queue_free)


func _resolve_damage_target(target: Node) -> Node:
	if target == null:
		return null
	if target.has_method("take_damage"):
		return target
	if target.get_parent() != null:
		return _resolve_damage_target(target.get_parent())
	return null
