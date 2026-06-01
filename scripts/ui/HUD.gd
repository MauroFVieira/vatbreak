extends CanvasLayer

# ──────────────────────────────────────────────
#  HUD.gd
#  Health bar (top-left) — percentage bar only, no text
#  Ammo mode indicator (bottom-centre)
#  Vat status row (top-right): species-coloured → red (bloomed) → grey (dead)
# ──────────────────────────────────────────────

@onready var health_bar:     ProgressBar   = $TopLeft/HealthBar
@onready var mode_label:     Label         = $BottomCentre/ModeLabel
@onready var center_message: Label         = $CenterMessage
@onready var vat_status_row: HBoxContainer = $TopRight/VatRow

# Species → active-state icon colour (matches enemy body palette)
const SPECIES_COLORS := {
	"consu_crawler": Color(0.18, 0.72, 0.55, 1),   # teal
	"fnitu_drifter": Color(0.62, 0.72, 0.12, 1),   # bile-green
	"rraey_brute":   Color(0.75, 0.12, 0.08, 1),   # blood-red
	"obin_seer":     Color(0.55, 0.15, 0.90, 1),   # purple
}
const COL_BLOOMED  := Color(1.0, 0.20, 0.04, 1)
const COL_DEAD     := Color(0.28, 0.28, 0.28, 1)

var _connections: Array = []

var _message_queue: Array[String] = []
var _message_busy:  bool          = false


func init(player: Node, mp35: Node, vats: Array) -> void:
	# Health bar
	player.health_changed.connect(_on_health_changed)
	_connections.append([player, "health_changed", Callable(self, "_on_health_changed")])
	health_bar.max_value = player.max_health
	health_bar.value     = player.health

	# Ammo mode
	mp35.mode_changed.connect(_on_mode_changed)
	_connections.append([mp35, "mode_changed", Callable(self, "_on_mode_changed")])
	_on_mode_changed("BULLET")

	# Vat status icons — one per vat, coloured by species
	for child in vat_status_row.get_children():
		child.queue_free()

	for vat in vats:
		var sid   := vat.species_id as String
		var icon  := ColorRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.color = SPECIES_COLORS.get(sid, Color(0.3, 0.8, 0.4, 1))
		vat_status_row.add_child(icon)

		var dead_cb  := Callable(self, "_mark_vat_dead").bind(icon)
		var bloom_icon_cb := Callable(self, "_mark_vat_bloomed").bind(icon)
		var bloom_msg_cb  := Callable(self, "_on_vat_bloomed").bind(vat)

		vat.connect("vat_destroyed_signal", dead_cb)
		vat.connect("vat_bloomed",          bloom_icon_cb)
		vat.connect("vat_bloomed",          bloom_msg_cb)

		_connections.append([vat, "vat_destroyed_signal", dead_cb])
		_connections.append([vat, "vat_bloomed",          bloom_icon_cb])
		_connections.append([vat, "vat_bloomed",          bloom_msg_cb])


func _exit_tree() -> void:
	for conn in _connections:
		var obj:      Node     = conn[0]
		var sig:      String   = conn[1]
		var callable: Callable = conn[2]
		if is_instance_valid(obj) and obj.is_connected(sig, callable):
			obj.disconnect(sig, callable)
	_connections.clear()


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value     = current


func _on_mode_changed(mode_name: String) -> void:
	if mode_label:
		mode_label.text = "[ %s ]" % mode_name


func _on_vat_bloomed(species_id: String, vat: Node) -> void:
	var display: String = species_id.to_upper()
	if is_instance_valid(vat) and vat.has_method("get_display_name"):
		display = vat.get_display_name()
	_queue_message("%s VAT BLOOMED\n⚠ SPAWN RATE ×2" % display)


func _mark_vat_dead(_species_id: String, icon: ColorRect) -> void:
	icon.color = COL_DEAD


func _mark_vat_bloomed(_species_id: String, icon: ColorRect) -> void:
	icon.color = COL_BLOOMED


# ── Message queue ───────────────────────────────

func _queue_message(msg: String) -> void:
	_message_queue.append(msg)
	if not _message_busy:
		_pump_message_queue()


func _pump_message_queue() -> void:
	if _message_queue.is_empty():
		_message_busy = false
		return
	_message_busy = true
	_show_message(_message_queue.pop_front())


func _show_message(msg: String) -> void:
	if center_message == null:
		_pump_message_queue()
		return
	center_message.text    = msg
	center_message.visible = true
	await get_tree().create_timer(2.5).timeout
	if center_message:
		center_message.visible = false
	await get_tree().create_timer(0.2).timeout
	_pump_message_queue()
