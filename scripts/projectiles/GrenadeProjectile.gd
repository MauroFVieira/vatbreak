extends Area2D

# ──────────────────────────────────────────────
#  GrenadeProjectile.gd
#  Slow arc; won't explode until armed (~80 px).
#  On impact, deals AOE damage in explosion_radius.
# ──────────────────────────────────────────────

var direction: Vector2 = Vector2.RIGHT
var speed: float = 280.0
var damage: int = 80
var explosion_radius: float = 96.0

const ARM_DISTANCE := 80.0
var can_explode: bool = false
var _distance_travelled: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var move := direction * speed * delta
	position += move
	_distance_travelled += move.length()
	if not can_explode and _distance_travelled >= ARM_DISTANCE:
		can_explode = true


func _on_body_entered(_body: Node) -> void:
	if not can_explode:
		return
	_explode()


func _explode() -> void:
	# AOE: find all bodies in radius and damage them
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 0b110  # enemies + vats
	var results := space.intersect_shape(query, 32)
	# Draw explosion graphic
	_draw_explosion()
	for r in results:
		var col = _resolve_damage_target(r["collider"])
		if col != null and col.has_method("take_damage"):
			# Pass damage type for vat resistance calculation
			if col.has_method("take_damage") and col.get_script() and col.get_script().resource_path.contains("Vat"):
				col.take_damage(damage, "grenade")
			else:
				col.take_damage(damage)
	# TODO: spawn explosion VFX here
	call_deferred("queue_free")


func _draw_explosion() -> void:
	# Draw a simple polygon explosion circle
	var polygon = Polygon2D.new()
	polygon.z_index = 5
	polygon.color = Color(1.0, 0.6, 0.0, 0.8)   # orange-yellow
	# Create circle points
	var points: PackedVector2Array = []
	var segments := 8
	for i in range(segments):
		var angle := (i / float(segments)) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * explosion_radius)
	polygon.polygon = points
	polygon.global_position = global_position
	get_parent().add_child(polygon)
	# Fade out the explosion
	var tween := polygon.create_tween()
	tween.tween_property(polygon, "color:a", 0.0, 0.3)
	tween.tween_callback(polygon.queue_free)

func _resolve_damage_target(target: Node) -> Node:
	if target == null:
		return null
	if target.has_method("take_damage"):
		return target
	if target.get_parent() != null:
		return _resolve_damage_target(target.get_parent())
	return null
