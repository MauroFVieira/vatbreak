extends CharacterBody2D

# ──────────────────────────────────────────────
#  Player.gd
# ──────────────────────────────────────────────

const SPEED := 230.0

@export var max_health: int = 100

var health: int
var dead: bool = false
var _speed_multiplier: float = 1.0
var _slow_timer: float = 0.0

# VFX state
var _polygons: Array      = []
var _poly_colors: Array   = []
var _colors_cached: bool  = false
var _hurt_active: bool    = false

@onready var gun_pivot: Node2D = $GunPivot


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	if dead:
		return
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_speed_multiplier = 1.0
	_handle_movement()
	_handle_aim()
	move_and_slide()


func _handle_movement() -> void:
	var dir := Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")
	velocity = dir.normalized() * SPEED * _speed_multiplier


func apply_slow(factor: float, duration: float) -> void:
	_speed_multiplier = factor
	_slow_timer = duration


func _handle_aim() -> void:
	gun_pivot.look_at(get_global_mouse_position())


func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	health = maxi(health, 0)
	emit_signal("health_changed", health, max_health)
	_play_hurt_vfx()
	if health <= 0:
		die()


func die() -> void:
	dead = true
	set_physics_process(false)
	_play_death_vfx()
	GameState.on_player_died()


signal health_changed(current: int, maximum: int)


# ═══════════════════════════════════════════════
#  VFX
# ═══════════════════════════════════════════════

func _cache_polygons() -> void:
	if _colors_cached:
		return
	_polygons    = []
	_poly_colors = []
	for child in get_children():
		if child is Polygon2D:
			_polygons.append(child)
			_poly_colors.append(child.color)
	_colors_cached = true


func _play_hurt_vfx() -> void:
	if dead or _hurt_active:
		return
	_cache_polygons()
	if _polygons.is_empty():
		return
	_hurt_active = true

	# Flash red-white (player tint, different from enemy white flash)
	for poly in _polygons:
		(poly as Polygon2D).color = Color(1.0, 0.3, 0.3, 1.0)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.2, 0.85), 0.06)
	tw.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)

	await get_tree().create_timer(0.06).timeout
	if not is_instance_valid(self) or dead:
		return
	var restore := create_tween().set_parallel(true)
	for i in _polygons.size():
		restore.tween_property(_polygons[i], "color", _poly_colors[i], 0.12)
	await restore.finished
	if is_instance_valid(self):
		_hurt_active = false


func _play_death_vfx() -> void:
	# Hide body polygons
	for child in get_children():
		if child is Polygon2D:
			child.visible = false

	var shard_count := 8
	var parent      := get_tree().current_scene

	for i in shard_count:
		var angle := (TAU / shard_count) * i + randf_range(-0.25, 0.25)
		var spd   := randf_range(80.0, 200.0)
		var size  := randf_range(5.0, 11.0)
		var col   := Color(0.2, 0.75, 0.35, 1.0).darkened(randf_range(0.0, 0.3))

		var pts := PackedVector2Array([
			Vector2(0, -size),
			Vector2(size * 0.6,  size * 0.5),
			Vector2(-size * 0.6, size * 0.5),
		])
		var shard := Polygon2D.new()
		shard.polygon        = pts
		shard.color          = col
		shard.global_position = global_position
		shard.rotation       = angle
		parent.add_child(shard)

		var dir := Vector2(cos(angle), sin(angle))
		var stw := shard.create_tween().set_parallel(true)
		stw.tween_property(shard, "global_position",
				shard.global_position + dir * spd * 0.4, 0.4) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		stw.tween_property(shard, "color",
				Color(col.r, col.g, col.b, 0.0), 0.35).set_delay(0.05)
		stw.tween_property(shard, "scale", Vector2(0.2, 0.2), 0.4)
		stw.chain().tween_callback(shard.queue_free)
