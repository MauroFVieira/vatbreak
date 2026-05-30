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
	query.collision_mask = 0b0010  # enemies layer; adjust to match your layer setup
	var results := space.intersect_shape(query, 32)
	for r in results:
		var col = r["collider"]
		if col.has_method("take_damage"):
			col.take_damage(damage)
	# TODO: spawn explosion VFX here
	queue_free()
