extends Area2D

# ──────────────────────────────────────────────
#  BulletProjectile.gd
#  Fast, single-target. Double damage vs Vat weakpoint.
# ──────────────────────────────────────────────

var direction: Vector2 = Vector2.RIGHT
var speed: float = 800.0
var damage: int = 12
var is_vat_shot: bool = false   # set externally if aimed at weakpoint; vat checks this

const MAX_RANGE_PX := 1200.0
var _distance_travelled: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	var move := direction * speed * delta
	position += move
	_distance_travelled += move.length()
	if _distance_travelled >= MAX_RANGE_PX:
		queue_free()


func _on_body_entered(body: Node) -> void:
	_hit(body)


func _on_area_entered(area: Node) -> void:
	_hit(area)


func _hit(target: Node) -> void:
	var resolved := _resolve_damage_target(target)
	if resolved == null:
		queue_free()
		return
	var dmg := damage
	if resolved.get("is_weakpoint"):
		dmg *= 2
	resolved.take_damage(dmg)
	queue_free()


func _resolve_damage_target(target: Node) -> Node:
	if target == null:
		return null
	if target.has_method("take_damage"):
		return target
	if target.get_parent() != null:
		return _resolve_damage_target(target.get_parent())
	return null
