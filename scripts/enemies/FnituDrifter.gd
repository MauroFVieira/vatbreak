extends "res://scripts/enemies/EnemyBase.gd"

# ──────────────────────────────────────────────
#  FnituDrifter.gd  —  Mid-range acid shooter
# ──────────────────────────────────────────────

@export var acid_glob_scene: PackedScene

const PREFERRED_RANGE  := 220.0
const SHOOT_INTERVAL   := 2.2
const GLOB_SPEED       := 160.0
const GLOB_DAMAGE      := 14

var _shoot_timer: float = SHOOT_INTERVAL


func _ready() -> void:
	species_id      = "fnitu_drifter"
	max_health      = 40
	move_speed      = 70.0
	contact_damage  = 8
	contact_cooldown = 1.2
	super._ready()


func _species_process(delta: float) -> void:
	_shoot_timer -= delta
	if _player_ref == null:
		return

	var dist := global_position.distance_to(_player_ref.global_position)

	# Maintain preferred range
	var to_player:Vector2 = (_player_ref.global_position - global_position).normalized()
	if dist > PREFERRED_RANGE + 40.0:
		velocity = to_player * move_speed
	elif dist < PREFERRED_RANGE - 40.0:
		velocity = -to_player * move_speed
	else:
		velocity = Vector2.ZERO

	if _shoot_timer <= 0.0 and dist <= PREFERRED_RANGE + 60.0:
		_shoot_timer = SHOOT_INTERVAL
		_fire_glob()


func _fire_glob() -> void:
	if acid_glob_scene == null or _player_ref == null:
		return
	var glob = acid_glob_scene.instantiate()
	get_tree().current_scene.add_child(glob)
	glob.global_position = global_position
	glob.direction = ((_player_ref.global_position - global_position).normalized())
	glob.speed  = GLOB_SPEED
	glob.damage = GLOB_DAMAGE
