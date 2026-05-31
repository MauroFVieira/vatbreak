extends CanvasLayer

# ──────────────────────────────────────────────
#  HUD.gd
#  Health bar (top-left)
#  Ammo mode indicator (bottom-centre)
#  Vat status row (top-right): green / red / ✕
# ──────────────────────────────────────────────

@onready var health_bar:      ProgressBar   = $TopLeft/HealthBar
@onready var health_label:    Label         = $TopLeft/HealthLabel
@onready var mode_label:      Label         = $BottomCentre/ModeLabel
@onready var center_message:  Label         = $CenterMessage
@onready var vat_status_row:  HBoxContainer = $TopRight/VatRow

# Track signal connections for cleanup on exit
var _connections: Array = []

# Message queue so rapid bloom events don't overwrite each other
var _message_queue: Array[String] = []
var _message_busy: bool = false


# Called by Main when player and vats are ready
func init(player: Node, mp35: Node, vats: Array) -> void:
	# Player health
	player.health_changed.connect(_on_health_changed)
	_connections.append([player, "health_changed", Callable(self, "_on_health_changed")])
	health_bar.max_value = player.max_health
	health_bar.value     = player.health
	_update_health_label(player.health, player.max_health)

	# Ammo mode
	mp35.mode_changed.connect(_on_mode_changed)
	_connections.append([mp35, "mode_changed", Callable(self, "_on_mode_changed")])
	_on_mode_changed("BULLET")

	# Vat status icons
	for child in vat_status_row.get_children():
		child.queue_free()
	for vat in vats:
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.color = Color(0.1, 0.9, 0.1)   # green = active
		vat_status_row.add_child(icon)

		var dead_callback := Callable(self, "_mark_vat_dead").bindv([icon])
		vat.connect("vat_destroyed_signal", dead_callback)
		_connections.append([vat, "vat_destroyed_signal", dead_callback])

		var bloom_icon_callback := Callable(self, "_mark_vat_bloomed").bindv([icon])
		vat.connect("vat_bloomed", bloom_icon_callback)
		_connections.append([vat, "vat_bloomed", bloom_icon_callback])

		var bloom_msg_callback := Callable(self, "_on_vat_bloomed").bindv([vat])
		vat.connect("vat_bloomed", bloom_msg_callback)
		_connections.append([vat, "vat_bloomed", bloom_msg_callback])


func _exit_tree() -> void:
	for conn_info in _connections:
		var obj      = conn_info[0]
		var sig_name = conn_info[1]
		var callable = conn_info[2]
		if is_instance_valid(obj) and obj.is_connected(sig_name, callable):
			obj.disconnect(sig_name, callable)
	_connections.clear()


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.value = current
	_update_health_label(current, maximum)


func _update_health_label(cur: int, max_val: int) -> void:
	if health_label:
		health_label.text = "%d / %d" % [cur, max_val]


func _on_mode_changed(mode_name: String) -> void:
	if mode_label:
		mode_label.text = "[ %s ]" % mode_name


func _on_vat_bloomed(species_id: String, vat: Node) -> void:
	# Ask the vat itself for the display name so the mapping lives in one place
	var display: String = species_id.to_upper()
	if is_instance_valid(vat) and vat.has_method("get_display_name"):
		display = vat.get_display_name()
	_queue_message("%s VAT BLOOMED\n⚠ SPAWN RATE ×2" % display)


func _mark_vat_dead(_species_id: String, icon: ColorRect) -> void:
	icon.color = Color(0.3, 0.3, 0.3)   # grey = destroyed


func _mark_vat_bloomed(_species_id: String, icon: ColorRect) -> void:
	icon.color = Color(0.9, 0.1, 0.1)   # red = bloomed


# ── Message queue ──────────────────────────────

func _queue_message(msg: String) -> void:
	_message_queue.append(msg)
	if not _message_busy:
		_pump_message_queue()


func _pump_message_queue() -> void:
	if _message_queue.is_empty():
		_message_busy = false
		return
	_message_busy = true
	var msg := _message_queue.pop_front() as String
	_show_message(msg)


func _show_message(msg: String) -> void:
	if center_message == null:
		_pump_message_queue()
		return
	center_message.text = msg
	center_message.visible = true
	await get_tree().create_timer(2.5).timeout
	if center_message:
		center_message.visible = false
	await get_tree().create_timer(0.2).timeout
	_pump_message_queue()
