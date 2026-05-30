extends Area2D

# ──────────────────────────────────────────────
#  AcidGlobProjectile.gd
#  Slow arcing projectile fired by FnituDrifter.
#  Applies a brief slow on hit in addition to damage.
# ──────────────────────────────────────────────

var direction: Vector2 = Vector2.RIGHT
var speed: float = 160.0
var damage: int = 14

const MAX_RANGE_PX := 600.0
const SLOW_FACTOR  := 0.5
const SLOW_DURATION := 1.5

var _distance_travelled: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var move := direction * speed * delta
	position += move
	_distance_travelled += move.length()
	if _distance_travelled >= MAX_RANGE_PX:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	if body.has_method("apply_slow"):
		body.apply_slow(SLOW_FACTOR, SLOW_DURATION)
	# TODO: acid splat VFX
	queue_free()
