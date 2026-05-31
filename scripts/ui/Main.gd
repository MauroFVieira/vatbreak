extends Node

# ──────────────────────────────────────────────
#  Main.gd
#  Root scene. Wires HUD ↔ Player ↔ Vats.
#  Listens for win / lose signals from GameState.
# ──────────────────────────────────────────────

@onready var hud:   CanvasLayer = $HUD
@onready var level: Node        = $Level

# Populated after level is ready
var _player: Node = null
var _mp35:   Node = null
var _vats:   Array = []


func _ready() -> void:
	# Let Level finish instantiating
	await get_tree().process_frame

	_player = get_tree().get_first_node_in_group("player")
	_mp35   = get_tree().get_first_node_in_group("mp35")
	_vats   = get_tree().get_nodes_in_group("vats")

	if hud and _player and _mp35:
		hud.init(_player, _mp35, _vats)

	GameState.all_vats_destroyed.connect(_on_win)
	GameState.player_died.connect(_on_lose)

	GameState.start_timer()


func _on_win() -> void:
	# Show win screen or end screen scene
	get_tree().change_scene_to_file("res://scenes/ui/EndScreen.tscn")


func _on_lose() -> void:
	# Brief pause then back to title
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
