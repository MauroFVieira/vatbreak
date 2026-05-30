extends "res://scripts/enemies/EnemyBase.gd"

# ──────────────────────────────────────────────
#  ObinSeer.gd  —  Elite: teleports, spawns adds
#  The Obin: emotionless, collective emergence.
# ──────────────────────────────────────────────

@export var add_scene: PackedScene   # set to ConsuCrawler in editor

const TELEPORT_INTERVAL := 4.0
const TELEPORT_RANGE    := 200.0
const ADD_COUNT         := 2
const AGGRO_RANGE       := 350.0

var _teleport_timer: float = TELEPORT_INTERVAL


func _ready() -> void:
	species_id      = "obin_seer"
	max_health      = 120
	move_speed      = 65.0
	contact_damage  = 14
	contact_cooldown = 1.0
	super._ready()


func _species_process(delta: float) -> void:
	_teleport_timer -= delta
	if _teleport_timer <= 0.0:
		_teleport_timer = TELEPORT_INTERVAL
		_do_teleport()
		_spawn_adds()
	else:
		# Orbit the player loosely
		if _player_ref:
			var to_player:Vector2 = _player_ref.global_position - global_position
			if to_player.length() > AGGRO_RANGE * 0.5:
				velocity = to_player.normalized() * move_speed
			else:
				velocity = Vector2.ZERO


func _do_teleport() -> void:
	var angle := randf() * TAU
	var dist  := randf_range(80.0, TELEPORT_RANGE)
	var offset := Vector2(cos(angle), sin(angle)) * dist
	global_position += offset
	# TODO: blink VFX


func _spawn_adds() -> void:
	if add_scene == null or not GameState.is_species_active("consu_crawler"):
		return
	for i in ADD_COUNT:
		var add = add_scene.instantiate()
		get_tree().current_scene.add_child(add)
		add.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
