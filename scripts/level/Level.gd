extends Node2D

# ──────────────────────────────────────────────
#  Level.gd
#  Populates the map on load:
#    • Adds Player to "player" group
#    • Adds all Vats to "vats" group
#    • Spawns initial enemy spread so the map is
#      already swarming from frame one
# ──────────────────────────────────────────────

@export var consu_scene:  PackedScene
@export var rraey_scene:  PackedScene
@export var obin_scene:   PackedScene
@export var fnitu_scene:  PackedScene

# How many of each species to pre-place at start
const INITIAL_COUNTS := {
	"consu":  15,
	"rraey":  5,
	"obin":   3,
	"fnitu":  6,
}

# Rough spread regions (centre, half-extents)
# Adjust once the real tilemap is authored
const SPREAD_REGIONS := [
	Vector2(640,  360),   # centre-ish
	Vector2(200,  200),   # top-left corridor
	Vector2(1100, 200),   # top-right corridor
	Vector2(200,  520),   # bottom-left
	Vector2(1100, 520),   # bottom-right
]

const MAP_HALF := Vector2(580, 300)   # scatter half-extent


func _ready() -> void:
	# Register player group
	var player := $Player
	if player:
		player.add_to_group("player")

	# Register vats
	for vat in get_tree().get_nodes_in_group("vats"):
		pass  # vats self-register in their own _ready via GameState.register_vat

	# Force all Vat children to register (they may not be in group yet)
	for child in get_children():
		if child.has_method("_ready") and child.is_in_group("vats"):
			pass  # already handled

	# Pre-populate the map with enemies
	_spawn_initial(consu_scene, INITIAL_COUNTS["consu"])
	_spawn_initial(rraey_scene, INITIAL_COUNTS["rraey"])
	_spawn_initial(obin_scene,  INITIAL_COUNTS["obin"])
	_spawn_initial(fnitu_scene, INITIAL_COUNTS["fnitu"])


func _spawn_initial(scene: PackedScene, count: int) -> void:
	if scene == null:
		return
	for i in count:
		var enemy = scene.instantiate()
		add_child(enemy)
		# Scatter randomly across the full map
		enemy.global_position = Vector2(
			randf_range(80.0, 1200.0),
			randf_range(80.0, 640.0)
		)
