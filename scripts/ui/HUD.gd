extends CanvasLayer

# ──────────────────────────────────────────────
#  HUD.gd
#  Health bar (top-left) — percentage bar only
#  Ammo mode indicator (bottom-centre)
#  Vat status row (top-right): species-coloured → red → grey
# ──────────────────────────────────────────────

@onready var health_bar:     ProgressBar   = $TopLeft/HealthBar
@onready var mode_label:     Label         = $BottomCentre/ModeLabel
@onready var center_message: Label         = $CenterMessage
@onready var vat_status_row: HBoxContainer = $TopRight/VatRow

const SPECIES_COLORS := {
	"consu_crawler": Color(0.18, 0.72, 0.55, 1),
	"fnitu_drifter": Color(0.62, 0.72, 0.12, 1),
	"rraey_brute":   Color(0.75, 0.12, 0.08, 1),
	"obin_seer":     Color(0.55, 0.15, 0.90, 1),
}
const COL_BLOOMED := Color(1.0, 0.20, 0.04, 1)
const COL_DEAD    := Color(0.28, 0.28, 0.28, 1)

# Each entry: { obj, sig, callable } — all untyped to survive freed references.
var _connections: Array = []

var _message_queue: Array[String] = []
var _message_busy:  bool          = false


func init(player: Node, mp35: Node, vats: Array) -> void:
	var cb_health := Callable(self, "_on_health_changed")
	player.health_changed.connect(cb_health)
	_connections.append({ "obj": player, "sig": "health_changed", "cb": cb_health })
	health_bar.max_value = player.max_health
	health_bar.value     = player.health

	var cb_mode := Callable(self, "_on_mode_changed")
	mp35.mode_changed.connect(cb_mode)
	_connections.append({ "obj": mp35, "sig": "mode_changed", "cb": cb_mode })
	_on_mode_changed("BULLET")

	for child in vat_status_row.get_children():
		child.queue_free()

	for vat in vats:
		var sid  : String   = vat.species_id
		var icon : ColorRect = ColorRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.color = SPECIES_COLORS.get(sid, Color(0.3, 0.8, 0.4, 1))
		vat_status_row.add_child(icon)

		var cb_dead      := Callable(self, "_mark_vat_dead").bind(icon)
		var cb_bloom_ico := Callable(self, "_mark_vat_bloomed").bind(icon)
		var cb_bloom_msg := Callable(self, "_on_vat_bloomed").bind(vat)

		vat.connect("vat_destroyed_signal", cb_dead)
		vat.connect("vat_bloomed",          cb_bloom_ico)
		vat.connect("vat_bloomed",          cb_bloom_msg)

		_connections.append({ "obj": vat, "sig": "vat_destroyed_signal", "cb": cb_dead })
		_connections.append({ "obj": vat, "sig": "vat_bloomed",          "cb": cb_bloom_ico })
		_connections.append({ "obj": vat, "sig": "vat_bloomed",          "cb": cb_bloom_msg })


func _exit_tree() -> void:
	# Extract the raw reference into an untyped variable FIRST.
	# Assigning a freed instance to a typed Node var crashes immediately in GDScript,
	# before is_instance_valid() ever runs — so we must stay untyped here.
	for conn in _connections:
		var raw = conn["obj"]          # untyped — safe even if freed
		var sig : String   = conn["sig"]
		var cb  : Callable = conn["cb"]
		if is_instance_valid(raw) and raw.is_connected(sig, cb):
			raw.disconnect(sig, cb)
	_connections.clear()


func _on_health_changed(current: int, maximum: int) -> void:
	if health_bar:
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
	if is_instance_valid(icon):
		icon.color = COL_DEAD


func _mark_vat_bloomed(_species_id: String, icon: ColorRect) -> void:
	if is_instance_valid(icon):
		icon.color = COL_BLOOMED


# ── Message queue ────────────────────────────────

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
	if not is_instance_valid(center_message):
		_pump_message_queue()
		return
	center_message.text    = msg
	center_message.visible = true
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(center_message):
		center_message.visible = false
	await get_tree().create_timer(0.2).timeout
	_pump_message_queue()
