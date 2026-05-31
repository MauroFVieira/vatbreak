extends Area2D

# ──────────────────────────────────────────────
#  BulletProjectile.gd
#  Fast, single-target. Double damage vs Vat weakpoint.
# ──────────────────────────────────────────────

var direction: Vector2 = Vector2.RIGHT
var speed: float = 800.0
var damage: int = 12

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
		call_deferred("queue_free")


func _on_body_entered(body: Node) -> void:
	_hit(body)


func _on_area_entered(area: Node) -> void:
	_hit(area)


func _hit(target: Node) -> void:
	# Capture the weakpoint flag BEFORE walking up to the parent that has take_damage.
	# resolved.get("is_weakpoint") would always return null because the flag lives on
	# the Weakpoint Area2D child, not on the Vat StaticBody2D that receives the damage.
	var is_weak: bool = target.get("is_weakpoint") == true
	var resolved := _resolve_damage_target(target)
	if resolved == null:
		call_deferred("queue_free")
		return
	var dmg := damage * (2 if is_weak else 1)
	resolved.take_damage(dmg)
	call_deferred("queue_free")


func _resolve_damage_target(target: Node) -> Node:
	if target == null:
		return null
	if target.has_method("take_damage"):
		return target
	if target.get_parent() != null:
		return _resolve_damage_target(target.get_parent())
	return null
