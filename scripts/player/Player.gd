extends CharacterBody2D

# ──────────────────────────────────────────────
#  Player.gd
# ──────────────────────────────────────────────

const SPEED := 230.0

@export var max_health: int = 100

var health: int = max_health
var dead: bool = false
var _speed_multiplier: float = 1.0
var _slow_timer: float = 0.0

@onready var gun_pivot: Node2D = $GunPivot

func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	if dead:
		return
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_speed_multiplier = 1.0
	_handle_movement()
	_handle_aim()
	move_and_slide()


func _handle_movement() -> void:
	var dir := Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")
	velocity = dir.normalized() * SPEED * _speed_multiplier


func apply_slow(factor: float, duration: float) -> void:
	_speed_multiplier = factor
	_slow_timer = duration


func _handle_aim() -> void:
	var mouse_pos := get_global_mouse_position()
	gun_pivot.look_at(mouse_pos)


func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	health = maxi(health, 0)
	# Notify HUD via signal (HUD connects externally)
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		die()


func die() -> void:
	dead = true
	GameState.on_player_died()
	# Simple visual: hide the player
	hide()
	set_physics_process(false)


signal health_changed(current: int, maximum: int)
