extends CharacterBody2D

# ──────────────────────────────────────────────
#  EnemyBase.gd
#  Inherited by each species scene.
#  Override: _species_process(delta) for unique AI.
#
#  VFX (no external assets needed):
#   • Hurt  — all Polygon2D children flash white then
#             return to original colours over 0.12 s.
#             Enemy also does a quick knockback scale squish.
#   • Death — spawns a burst of small polygon shards
#             at the enemy's position, then frees self.
#   • Blink — used by ObinSeer; brief after-image fade
#             at the old position before teleporting.
# ──────────────────────────────────────────────

@export var species_id: String     = "unknown"
@export var max_health: int        = 30
@export var move_speed: float      = 80.0
@export var contact_damage: int    = 10
@export var contact_cooldown: float = 1.0

# Species subclasses set this colour so death shards match the enemy's palette.
var shard_color: Color = Color(0.4, 0.8, 0.5, 1)

var health: int
var dead: bool = false

# NanoBurn DoT
var nano_burn_damage: int  = 0
var nano_burn_stacks: int  = 0
const NANO_BURN_TICK      := 0.5
const NANO_BURN_DURATION  := 3.0
var _nano_burn_timer: float   = 0.0
var _nano_burn_elapsed: float = 0.0

var _contact_timer: float = 0.0
var _player_ref: Node     = null

# Cached polygon children + their original colours, populated on first hurt.
var _polygons: Array       = []
var _poly_colors: Array    = []
var _colors_cached: bool   = false
var _hurt_active: bool     = false


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	_find_player()


func _physics_process(delta: float) -> void:
	if dead:
		return
	_process_nano_burn(delta)
	_contact_timer = maxf(_contact_timer - delta, 0.0)
	_species_process(delta)
	move_and_slide()


# ── Override in subclasses ──────────────────────
func _species_process(_delta: float) -> void:
	_chase_player()


func _chase_player() -> void:
	if _player_ref == null:
		_find_player()
		return
	velocity = (_player_ref.global_position - global_position).normalized() * move_speed


func _find_player() -> void:
	_player_ref = get_tree().get_first_node_in_group("player")


# ── Damage ──────────────────────────────────────
func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	_play_hurt_vfx()
	if health <= 0:
		die()


func apply_nano_burn(dps: int) -> void:
	nano_burn_stacks += 1
	nano_burn_damage += dps
	_nano_burn_elapsed = 0.0
	_nano_burn_timer   = 0.0


func _process_nano_burn(delta: float) -> void:
	if nano_burn_stacks == 0:
		return
	_nano_burn_elapsed += delta
	_nano_burn_timer   += delta
	if _nano_burn_timer >= NANO_BURN_TICK:
		_nano_burn_timer -= NANO_BURN_TICK
		take_damage(nano_burn_damage)
	if _nano_burn_elapsed >= NANO_BURN_DURATION:
		nano_burn_stacks = 0
		nano_burn_damage = 0


func die() -> void:
	dead = true
	set_physics_process(false)
	_play_death_vfx()
	# Free after the burst animation finishes (0.35 s)
	await get_tree().create_timer(0.35).timeout
	call_deferred("queue_free")


# ── Contact damage ──────────────────────────────
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and _contact_timer <= 0.0:
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
		_contact_timer = contact_cooldown


# ═══════════════════════════════════════════════
#  VFX HELPERS
# ═══════════════════════════════════════════════

# ── Cache all Polygon2D children once ──────────
func _cache_polygons() -> void:
	if _colors_cached:
		return
	_polygons   = []
	_poly_colors = []
	for child in get_children():
		if child is Polygon2D:
			_polygons.append(child)
			_poly_colors.append(child.color)
	_colors_cached = true


# ── Hurt flash ──────────────────────────────────
# All polygons snap to white, then tween back to original colours.
# A scale squish gives physical weight to the hit.
func _play_hurt_vfx() -> void:
	if dead or _hurt_active:
		return
	_cache_polygons()
	if _polygons.is_empty():
		return
	_hurt_active = true

	# Snap all polygons to near-white
	for poly in _polygons:
		(poly as Polygon2D).color = Color(1.0, 1.0, 1.0, 1.0)

	# Scale squish: compress vertically, expand horizontally
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.3, 0.75), 0.06)
	tw.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)

	# After a short hold, restore original polygon colours
	await get_tree().create_timer(0.06).timeout
	if not is_instance_valid(self) or dead:
		return
	var restore := create_tween().set_parallel(true)
	for i in _polygons.size():
		restore.tween_property(_polygons[i], "color", _poly_colors[i], 0.10)
	await restore.finished
	if is_instance_valid(self):
		_hurt_active = false


# ── Death burst ─────────────────────────────────
# Spawns 6–8 small triangular shards that fly outward and fade.
# Uses a helper Node2D so it outlives the enemy node.
func _play_death_vfx() -> void:
	# Hide the enemy's own polygons immediately
	for child in get_children():
		if child is Polygon2D:
			child.visible = false

	var shard_count := randi_range(6, 9)
	var parent      := get_tree().current_scene

	for i in shard_count:
		var angle  := (TAU / shard_count) * i + randf_range(-0.3, 0.3)
		var speed  := randf_range(60.0, 180.0)
		var size   := randf_range(4.0, 9.0)
		var col    := shard_color.darkened(randf_range(0.0, 0.35))

		# Build a small triangle polygon
		var pts := PackedVector2Array([
			Vector2(0, -size),
			Vector2(size * 0.6,  size * 0.5),
			Vector2(-size * 0.6, size * 0.5),
		])
		var shard := Polygon2D.new()
		shard.polygon = pts
		shard.color   = col
		shard.global_position = global_position
		shard.rotation = angle
		parent.add_child(shard)

		# Fly outward and fade
		var dir := Vector2(cos(angle), sin(angle))
		var tw  := shard.create_tween().set_parallel(true)
		tw.tween_property(shard, "global_position",
				shard.global_position + dir * speed * 0.35, 0.35) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(shard, "color",
				Color(col.r, col.g, col.b, 0.0), 0.30) \
				.set_delay(0.05)
		tw.tween_property(shard, "scale",
				Vector2(0.3, 0.3), 0.35)
		tw.chain().tween_callback(shard.queue_free)


# ── Blink VFX (used by ObinSeer) ────────────────
# Call this BEFORE moving. Leaves a fading ghost at the old position.
func play_blink_vfx() -> void:
	_cache_polygons()
	var parent := get_tree().current_scene

	for i in _polygons.size():
		var poly   := _polygons[i] as Polygon2D
		var ghost  := Polygon2D.new()
		ghost.polygon        = poly.polygon.duplicate()
		ghost.color          = Color(poly.color.r, poly.color.g, poly.color.b, 0.65)
		ghost.global_position = poly.global_position
		ghost.global_rotation = poly.global_rotation
		ghost.scale          = poly.scale
		parent.add_child(ghost)

		var tw := ghost.create_tween().set_parallel(true)
		tw.tween_property(ghost, "color",
				Color(poly.color.r, poly.color.g, poly.color.b, 0.0), 0.28)
		tw.tween_property(ghost, "scale", Vector2(1.4, 1.4), 0.28)
		tw.chain().tween_callback(ghost.queue_free)
