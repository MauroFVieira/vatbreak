extends StaticBody2D

# ──────────────────────────────────────────────
#  Vat.gd
#  Stationary structure. Has bloom stage, health,
#  and continuously spawns linked species.
# ──────────────────────────────────────────────

signal vat_destroyed_signal(species_id: String)
signal vat_bloomed(species_id: String)

@export var species_id: String = "consu_crawler"
@export var enemy_scene: PackedScene
@export var max_health: int = 600
# Each vat gets a random bloom time between 30 and 60 seconds,
# assigned in _ready() so they stagger naturally across the map.
@export var bloom_time_override: float = 0.0   # set in editor to pin a specific vat; 0 = random

const SPAWN_INTERVAL  := 3.0    # base seconds per spawn
const BLOOM_TWEEN_DUR := 1.2

# Stage colours — body polygon
const COL_BODY_ACTIVE  := Color(0.18, 0.28, 0.22, 1)
const COL_BODY_BLOOMED := Color(0.32, 0.07, 0.05, 1)
# Stage colours — ring polygons
const COL_RING_ACTIVE  := Color(0.08, 0.55, 0.18, 1)
const COL_RING_BLOOMED := Color(0.85, 0.12, 0.04, 1)
# Stage colours — cap polygon
const COL_CAP_ACTIVE   := Color(0.12, 0.38, 0.18, 1)
const COL_CAP_BLOOMED  := Color(0.55, 0.06, 0.04, 1)
# Light colours
const COL_LIGHT_ACTIVE  := Color(0.1, 1.0, 0.25, 1)
const COL_LIGHT_BLOOMED := Color(1.0, 0.12, 0.04, 1)

# Human-readable display names for HUD messages
const SPECIES_NAMES := {
	"consu_crawler": "CONSU",
	"rraey_brute":   "RRAEY",
	"obin_seer":     "OBIN",
	"fnitu_drifter": "FNITU",
}

enum Stage { ACTIVE, BLOOMED, DEAD }
var stage: Stage = Stage.ACTIVE

var health: int
var _bloom_time: float = 45.0
var _bloom_timer: float = 0.0
var _spawn_timer: float = 0.0
var _pulse_timer: float = 0.0

@onready var body:             Polygon2D   = $Body
@onready var ring:             Polygon2D   = $Ring
@onready var ring2:            Polygon2D   = $Ring2
@onready var cap:              Polygon2D   = $Cap
@onready var weakpoint_marker: Polygon2D   = $WeakpointMarker
@onready var light:            PointLight2D = $PointLight2D
@onready var health_bar:       ProgressBar  = $HealthBar
@onready var weakpoint:        Area2D       = $Weakpoint


func _ready() -> void:
	health = max_health
	add_to_group("vats")
	GameState.register_vat(species_id)

	# Stagger bloom times: random between 30 and 60 seconds unless overridden
	_bloom_time = bloom_time_override if bloom_time_override > 0.0 else randf_range(30.0, 60.0)

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value     = max_health
	if weakpoint:
		weakpoint.set("is_weakpoint", true)

	# Ensure polygons start in active colours
	_apply_active_colors()

	# PointLight2D needs a texture to render; create a minimal white radial gradient
	if light and light.texture == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in range(64):
			for x in range(64):
				var dx := x - 32.0
				var dy := y - 32.0
				var d  := sqrt(dx * dx + dy * dy) / 32.0
				var a  := clampf(1.0 - d, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		light.texture = ImageTexture.create_from_image(img)


func _physics_process(delta: float) -> void:
	if stage == Stage.DEAD:
		return

	# Bloom progression
	if stage == Stage.ACTIVE:
		_bloom_timer += delta
		if _bloom_timer >= _bloom_time:
			_bloom()

	# Spawn tick
	var interval := SPAWN_INTERVAL / (2.0 if stage == Stage.BLOOMED else 1.0)
	_spawn_timer += delta
	if _spawn_timer >= interval:
		_spawn_timer = 0.0
		_try_spawn()

	# Light pulse
	_pulse_timer += delta
	var pulse_speed := 3.0 if stage == Stage.ACTIVE else 6.0
	var pulse_base  := 1.8 if stage == Stage.ACTIVE else 2.8
	var pulse_amp   := 0.4 if stage == Stage.ACTIVE else 0.9
	if light:
		light.energy = pulse_base + sin(_pulse_timer * pulse_speed) * pulse_amp


func _apply_active_colors() -> void:
	if body:  body.color = COL_BODY_ACTIVE
	if ring:  ring.color = COL_RING_ACTIVE
	if ring2: ring2.color = COL_RING_ACTIVE
	if cap:   cap.color  = COL_CAP_ACTIVE
	if light: light.color = COL_LIGHT_ACTIVE


func _bloom() -> void:
	stage = Stage.BLOOMED
	GameState.on_vat_bloomed(species_id)
	emit_signal("vat_bloomed", species_id)

	# Animate polygons from green to red
	var tw := create_tween().set_parallel(true)
	tw.tween_property(body,  "color", COL_BODY_BLOOMED, BLOOM_TWEEN_DUR)
	tw.tween_property(ring,  "color", COL_RING_BLOOMED, BLOOM_TWEEN_DUR)
	tw.tween_property(ring2, "color", COL_RING_BLOOMED, BLOOM_TWEEN_DUR)
	tw.tween_property(cap,   "color", COL_CAP_BLOOMED,  BLOOM_TWEEN_DUR)
	tw.tween_property(light, "color", COL_LIGHT_BLOOMED, BLOOM_TWEEN_DUR)

	# Scale flash on the body for visual punch
	var flash := create_tween()
	flash.tween_property(body, "scale", Vector2(1.25, 1.25), 0.15)
	flash.tween_property(body, "scale", Vector2(1.0,  1.0),  0.25)


func get_display_name() -> String:
	return SPECIES_NAMES.get(species_id, species_id.to_upper())


func _try_spawn() -> void:
	if not GameState.is_species_active(species_id):
		return
	if enemy_scene == null:
		return
	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	var angle  := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * randf_range(40.0, 80.0)
	enemy.global_position = global_position + offset


func take_damage(amount: int, damage_type: String = "bullet") -> void:
	if stage == Stage.DEAD:
		return
	var final_damage := amount
	if damage_type == "grenade":
		final_damage = int(amount * 0.6)
	elif damage_type == "beam":
		final_damage = int(amount * 1.6)
	health -= final_damage
	health = maxi(health, 0)
	if health_bar:
		health_bar.value = health
	if health <= 0:
		_destroy()


func _destroy() -> void:
	stage = Stage.DEAD
	GameState.on_vat_destroyed(species_id)
	emit_signal("vat_destroyed_signal", species_id)
	# TODO: explosion VFX
	call_deferred("queue_free")
