extends Node

# ──────────────────────────────────────────────
#  GameState.gd  —  Autoload singleton
#  Tracks vats, species spawning flags, and
#  win/lose conditions for the whole session.
# ──────────────────────────────────────────────

signal vat_destroyed(species_id: String)
signal all_vats_destroyed()
signal player_died()

# Maps species_id → bool (true = still spawning)
var species_active: Dictionary = {}

# Total vats remaining
var vats_remaining: int = 0

# Elapsed time for end-screen stat
var elapsed_time: float = 0.0
var timer_running: bool = false


func _process(delta: float) -> void:
	if timer_running:
		elapsed_time += delta


func reset() -> void:
	species_active.clear()
	vats_remaining = 0
	elapsed_time = 0.0
	timer_running = false


func register_vat(species_id: String) -> void:
	species_active[species_id] = true
	vats_remaining += 1


func is_species_active(species_id: String) -> bool:
	return species_active.get(species_id, false)


func on_vat_destroyed(species_id: String) -> void:
	if species_active.has(species_id):
		species_active[species_id] = false
	vats_remaining = maxi(vats_remaining - 1, 0)
	emit_signal("vat_destroyed", species_id)
	if vats_remaining == 0:
		timer_running = false
		emit_signal("all_vats_destroyed")


func on_player_died() -> void:
	timer_running = false
	emit_signal("player_died")


func start_timer() -> void:
	timer_running = true


func get_elapsed_formatted() -> String:
	var minutes := int(elapsed_time / 60)
	var seconds := int(elapsed_time) % 60
	return "%02d:%02d" % [minutes, seconds]
