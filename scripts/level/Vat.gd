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
@export var max_health: int = 600   # tripled from 200

# Bloom
const BLOOM_TIME      := 45.0   # seconds until vat blooms
const SPAWN_INTERVAL  := 3.0    # base seconds per spawn
const BLOOM_TWEEN_DUR := 1.5

enum Stage { ACTIVE, BLOOMED, DEAD }
var stage: Stage = Stage.ACTIVE

var health: int
var _bloom_timer: float = 0.0
var _spawn_timer: float = 0.0

@onready var light: PointLight2D  = $PointLight2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var weakpoint: Area2D = $Weakpoint   # child Area2D; has is_weakpoint = true


func _ready() -> void:
	health = max_health
	add_to_group("vats")
	GameState.register_vat(species_id)
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value     = max_health
	if weakpoint:
		weakpoint.set("is_weakpoint", true)


func _physics_process(delta: float) -> void:
	if stage == Stage.DEAD:
		return

	# Bloom progression
	if stage == Stage.ACTIVE:
		_bloom_timer += delta
		if _bloom_timer >= BLOOM_TIME:
			_bloom()

	# Spawn tick
	var interval := SPAWN_INTERVAL / (2.0 if stage == Stage.BLOOMED else 1.0)
	_spawn_timer += delta
	if _spawn_timer >= interval:
		_spawn_timer = 0.0
		_try_spawn()


func _bloom() -> void:
	stage = Stage.BLOOMED
	GameState.on_vat_bloomed(species_id)
	emit_signal("vat_bloomed", species_id)
	# Tween light from green to red
	if light:
		var tween := create_tween()
		tween.tween_property(light, "color", Color(1.0, 0.1, 0.0), BLOOM_TWEEN_DUR)


func _try_spawn() -> void:
	if not GameState.is_species_active(species_id):
		return
	if enemy_scene == null:
		return
	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	# Scatter spawn around vat
	var angle  := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * randf_range(40.0, 80.0)
	enemy.global_position = global_position + offset


func take_damage(amount: int, damage_type: String = "bullet") -> void:
	if stage == Stage.DEAD:
		return
	# Apply type modifiers
	var final_damage := amount
	if damage_type == "grenade":
		final_damage = int(amount * 0.6)   # 40% resistance to grenades
	elif damage_type == "beam":
		final_damage = int(amount * 1.6)   # 60% vulnerability to beams
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
	queue_free()
