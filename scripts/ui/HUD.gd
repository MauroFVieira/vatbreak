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
@onready var vat_status_row:  HBoxContainer = $TopRight/VatRow

# Called by Main when player and vats are ready
func init(player: Node, mp35: Node, vats: Array) -> void:
	# Player health
	player.health_changed.connect(_on_health_changed)
	health_bar.max_value = player.max_health
	health_bar.value     = player.health
	_update_health_label(player.health, player.max_health)

	# Ammo mode
	mp35.mode_changed.connect(_on_mode_changed)
	_on_mode_changed("BULLET")

	# Vat status icons
	for child in vat_status_row.get_children():
		child.queue_free()
	for vat in vats:
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.color = Color(0.1, 0.9, 0.1)   # green = active
		vat_status_row.add_child(icon)
		# Connect vat signals
		vat.connect("vat_destroyed_signal", func(_id): _mark_vat_dead(icon))
		GameState.vat_destroyed.connect(func(_id): _check_bloom(vat, icon))


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.value = current
	_update_health_label(current, maximum)


func _update_health_label(cur: int, max_val: int) -> void:
	if health_label:
		health_label.text = "%d / %d" % [cur, max_val]


func _on_mode_changed(mode_name: String) -> void:
	if mode_label:
		mode_label.text = "[ %s ]" % mode_name


func _mark_vat_dead(icon: ColorRect) -> void:
	icon.color = Color(0.3, 0.3, 0.3)   # grey = destroyed


func _check_bloom(vat: Node, icon: ColorRect) -> void:
	# Poll the vat's stage; if bloomed show red
	if is_instance_valid(vat) and vat.stage == 1:   # Stage.BLOOMED == 1
		icon.color = Color(0.9, 0.1, 0.1)
