extends CanvasLayer

# ──────────────────────────────────────────────
#  HUD.gd
#  Health bar (top-left)
#  Ammo mode indicator (bottom-centre)
#  Vat status row (top-right): green / red / ✕
# ──────────────────────────────────────────────

@onready var health_bar:      ProgressBar = $TopLeft/HealthBar
@onready var health_label:    Label       = $TopLeft/HealthLabel
@onready var mode_label:      Label       = $BottomCentre/ModeLabel
@onready var center_message:  Label       = $CenterMessage
@onready var vat_status_row:  HBoxContainer = $TopRight/VatRow

# Track signal connections for cleanup on exit
var _connections: Array = []  # Array of (object, signal, callable) tuples

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
		# Connect vat signals explicitly and track for cleanup
		var dead_callback = Callable(self, "_mark_vat_dead").bindv([icon])
		vat.connect("vat_destroyed_signal", dead_callback)
		_connections.append([vat, "vat_destroyed_signal", dead_callback])
		
		var bloom_callback = Callable(self, "_mark_vat_bloomed").bindv([icon])
		vat.connect("vat_bloomed", bloom_callback)
		_connections.append([vat, "vat_bloomed", bloom_callback])
		
		vat.connect("vat_bloomed", Callable(self, "_on_vat_bloomed"))
		_connections.append([vat, "vat_bloomed", Callable(self, "_on_vat_bloomed")])


func _exit_tree() -> void:
	# Disconnect all tracked signals to prevent cleanup errors on scene transitions
	for conn_info in _connections:
		var obj = conn_info[0]
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


func _on_vat_bloomed(species_id: String) -> void:
	_display_center_message("VATS BLOOMED")


func _display_center_message(msg: String) -> void:
	if center_message == null:
		return
	center_message.text = msg
	center_message.visible = true
	await get_tree().create_timer(2.0).timeout
	if center_message:
		center_message.visible = false


func _mark_vat_dead(_species_id: String, icon: ColorRect) -> void:
	icon.color = Color(0.3, 0.3, 0.3)   # grey = destroyed


func _mark_vat_bloomed(_species_id: String, icon: ColorRect) -> void:
	icon.color = Color(0.9, 0.1, 0.1)   # red = bloomed


func _check_bloom(_species_id: String, vat: Node, icon: ColorRect) -> void:
	# Poll the vat's stage; if bloomed show red
	if is_instance_valid(vat) and vat.stage == 1:   # Stage.BLOOMED == 1
		icon.color = Color(0.9, 0.1, 0.1)
