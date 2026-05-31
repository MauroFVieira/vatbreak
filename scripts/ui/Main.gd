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
	if _player == null and level:
		_player = level.get_node_or_null("Player")

	_mp35 = get_tree().get_first_node_in_group("mp35")
	if _mp35 == null and _player:
		_mp35 = _player.get_node_or_null("GunPivot/MP35")

	_vats   = get_tree().get_nodes_in_group("vats")

	if hud and _player and _mp35:
		hud.init(_player, _mp35, _vats)

	GameState.all_vats_destroyed.connect(_on_win)
	GameState.player_died.connect(_on_lose)

	GameState.start_timer()


func _on_win() -> void:
	# Defer scene change to avoid removing CollisionObjects during physics callbacks
	call_deferred("_on_win_deferred")


func _on_lose() -> void:
	# Defer the lose flow so it's not executed during a physics callback
	call_deferred("_on_lose_deferred")


func _on_win_deferred() -> void:
	# Show win screen or end screen scene (deferred)
	get_tree().change_scene_to_file("res://scenes/ui/EndScreen.tscn")


func _on_lose_deferred() -> void:
	# Brief pause then back to title (deferred)
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
