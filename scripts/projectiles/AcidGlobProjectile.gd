extends Area2D

# ──────────────────────────────────────────────
#  AcidGlobProjectile.gd
#  Slow arcing projectile fired by FnituDrifter.
#  Applies a brief slow on hit in addition to damage.
# ──────────────────────────────────────────────

var direction: Vector2 = Vector2.RIGHT
var speed: float       = 160.0
var damage: int        = 14

const MAX_RANGE_PX  := 600.0
const SLOW_FACTOR   := 0.5
const SLOW_DURATION := 1.5

var _distance_travelled: float = 0.0
var _bob_t: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var move := direction * speed * delta
	position += move
	_distance_travelled += move.length()

	# Slow undulating bob perpendicular to travel
	_bob_t += delta * 4.0
	var perp := Vector2(-direction.y, direction.x)
	position += perp * sin(_bob_t) * 0.8

	if _distance_travelled >= MAX_RANGE_PX:
		_splat(null)


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	if body.has_method("apply_slow"):
		body.apply_slow(SLOW_FACTOR, SLOW_DURATION)
	_splat(body)


func _splat(_body) -> void:
	var parent := get_tree().current_scene
	var pos    := global_position

	# Central splat pool
	var pool := Polygon2D.new()
	pool.z_index = 2
	pool.color   = Color(0.35, 0.78, 0.1, 0.75)
	var pts := PackedVector2Array()
	for i in 10:
		var a   := (i / 10.0) * TAU
		var r   := randf_range(8.0, 16.0)
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	pool.polygon        = pts
	pool.global_position = pos
	parent.add_child(pool)

	# Droplet sprays
	for i in randi_range(4, 7):
		var drop := Polygon2D.new()
		var sz   := randf_range(3.0, 7.0)
		drop.color   = Color(0.45, 0.88, 0.12, 0.8)
		drop.polygon = PackedVector2Array([
			Vector2(0, -sz), Vector2(sz * 0.5, sz * 0.4), Vector2(-sz * 0.5, sz * 0.4)
		])
		var a := randf() * TAU
		var d := randf_range(10.0, 30.0)
		drop.global_position = pos + Vector2(cos(a), sin(a)) * d
		drop.rotation        = a
		parent.add_child(drop)
		var tw1 := drop.create_tween()
		tw1.tween_property(drop, "color:a", 0.0, 0.5).set_delay(0.2)
		tw1.tween_callback(drop.queue_free)

	# Fade and free the pool
	var tw2 := pool.create_tween()
	tw2.tween_property(pool, "color:a", 0.0, 0.6).set_delay(0.3)
	tw2.tween_callback(pool.queue_free)

	call_deferred("queue_free")
