extends Node2D

# ──────────────────────────────────────────────
#  MP35.gd  —  The "Empee" nano-rifle
#  Three ammo modes: BULLET / GRENADE / BEAM
# ──────────────────────────────────────────────

enum AmmoMode { BULLET, GRENADE, BEAM }

const MODE_NAMES := ["BULLET", "GRENADE", "BEAM"]
const MODE_COUNT := 3

# Mode indicator light colours (matches projectile palettes)
const MODE_COLORS := [
	Color(1.0, 0.98, 0.5, 1),   # BULLET — yellow-white
	Color(1.0, 0.45, 0.08, 1),  # GRENADE — orange
	Color(0.35, 0.88, 1.0, 1),  # BEAM — cyan
]

@export var bullet_scene:  PackedScene
@export var grenade_scene: PackedScene
@export var beam_scene:    PackedScene

# Bullet mode
const BULLET_COOLDOWN := 0.10
const BULLET_DAMAGE   := 12
const BULLET_SPEED    := 800.0

# Grenade mode
const GRENADE_COOLDOWN := 0.60
const GRENADE_DAMAGE   := 80
const GRENADE_SPEED    := 280.0
const GRENADE_RADIUS   := 96.0

# Beam mode
const BEAM_TICK_DAMAGE := 4
const BEAM_RANGE       := 900.0   # matches BeamProjectile scene RayCast2D target

var current_mode: AmmoMode = AmmoMode.BULLET
var last_mode:    AmmoMode = AmmoMode.GRENADE

var _fire_cooldown: float     = 0.0
var _beam_instance            = null
var _prev_left_pressed: bool  = false
var _prev_right_pressed: bool = false

@onready var mode_light: Polygon2D = $ModeLight

signal mode_changed(mode_name: String)


func _ready() -> void:
	emit_signal("mode_changed", MODE_NAMES[current_mode])
	_update_mode_light()


func _process(delta: float) -> void:
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_handle_mode_switch()
	_handle_fire()


func _handle_mode_switch() -> void:
	var left  := Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT)
	var right := Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_RIGHT)
	if left and not _prev_left_pressed:
		_set_mode((current_mode + 1) % MODE_COUNT)
	elif right and not _prev_right_pressed:
		_set_mode((current_mode - 1 + MODE_COUNT) % MODE_COUNT)
	elif Input.is_action_just_pressed("quick_swap"):
		var tmp := current_mode
		_set_mode(last_mode)
		last_mode = tmp
	_prev_left_pressed  = left
	_prev_right_pressed = right


func _set_mode(new_mode: int) -> void:
	if new_mode == current_mode:
		return
	last_mode    = current_mode
	current_mode = new_mode as AmmoMode
	_stop_beam()
	emit_signal("mode_changed", MODE_NAMES[current_mode])
	_update_mode_light()


func _update_mode_light() -> void:
	if mode_light:
		mode_light.color = MODE_COLORS[current_mode]


func _handle_fire() -> void:
	match current_mode:
		AmmoMode.BULLET:
			_stop_beam()
			if _fire_cooldown <= 0.0:
				_fire_bullet()
		AmmoMode.GRENADE:
			_stop_beam()
			if _fire_cooldown <= 0.0:
				_fire_grenade()
		AmmoMode.BEAM:
			_start_beam()


func _fire_bullet() -> void:
	if not bullet_scene:
		return
	_fire_cooldown = BULLET_COOLDOWN
	var proj = bullet_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.direction       = Vector2.RIGHT.rotated(global_rotation)
	proj.speed           = BULLET_SPEED
	proj.damage          = BULLET_DAMAGE


func _fire_grenade() -> void:
	if not grenade_scene:
		return
	_fire_cooldown = GRENADE_COOLDOWN
	var proj = grenade_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position  = global_position
	proj.direction        = Vector2.RIGHT.rotated(global_rotation)
	proj.speed            = GRENADE_SPEED
	proj.damage           = GRENADE_DAMAGE
	proj.explosion_radius = GRENADE_RADIUS


func _start_beam() -> void:
	if _beam_instance == null and beam_scene:
		_beam_instance = beam_scene.instantiate()
		add_child(_beam_instance)
		_beam_instance.tick_damage = BEAM_TICK_DAMAGE
		_beam_instance.beam_range  = BEAM_RANGE


func _stop_beam() -> void:
	if _beam_instance != null:
		_beam_instance.queue_free()
		_beam_instance = null
