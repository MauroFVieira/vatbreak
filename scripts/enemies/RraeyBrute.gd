extends "res://scripts/enemies/EnemyBase.gd"

# ──────────────────────────────────────────────
#  RraeyBrute.gd  —  Slow, very high HP, charges
#  The Rraey: militaristic, physically imposing.
# ──────────────────────────────────────────────

enum BruteState { IDLE, WINDING_UP, CHARGING, RECOVERING }

const WIND_UP_TIME    := 0.8
const CHARGE_SPEED    := 480.0
const CHARGE_DIST     := 320.0
const RECOVER_TIME    := 1.2
const AGGRO_RANGE     := 280.0

var _state: BruteState          = BruteState.IDLE
var _state_timer: float         = 0.0
var _charge_dir: Vector2        = Vector2.ZERO
var _charge_dist_remaining: float = 0.0


func _ready() -> void:
	species_id       = "rraey_brute"
	max_health       = 220
	move_speed       = 55.0
	contact_damage   = 20
	contact_cooldown = 1.5
	shard_color      = Color(0.75, 0.12, 0.08, 1)
	super._ready()


func _species_process(delta: float) -> void:
	_state_timer -= delta
	match _state:
		BruteState.IDLE:
			_chase_player()
			if _player_in_range(AGGRO_RANGE) and _state_timer <= 0.0:
				_enter_state(BruteState.WINDING_UP)

		BruteState.WINDING_UP:
			velocity = Vector2.ZERO
			if _state_timer <= 0.0:
				if _player_ref:
					_charge_dir = (_player_ref.global_position - global_position).normalized()
				_charge_dist_remaining = CHARGE_DIST
				_enter_state(BruteState.CHARGING)

		BruteState.CHARGING:
			velocity = _charge_dir * CHARGE_SPEED
			_charge_dist_remaining -= CHARGE_SPEED * delta
			if _charge_dist_remaining <= 0.0:
				_enter_state(BruteState.RECOVERING)

		BruteState.RECOVERING:
			velocity = Vector2.ZERO
			if _state_timer <= 0.0:
				_enter_state(BruteState.IDLE)


func _enter_state(new_state: BruteState) -> void:
	_state = new_state
	match new_state:
		BruteState.WINDING_UP:
			_state_timer = WIND_UP_TIME
			# Coil back: squish horizontally as if loading the charge
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2(0.8, 1.25), WIND_UP_TIME * 0.6)
			tw.tween_property(self, "scale", Vector2(1.0, 1.0),  WIND_UP_TIME * 0.4)
		BruteState.CHARGING:
			# Stretch forward along charge direction
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2(1.35, 0.7), 0.08)
			tw.tween_property(self, "scale", Vector2(1.0,  1.0), 0.18)
		BruteState.RECOVERING:
			_state_timer = RECOVER_TIME
			# Slam stop: squish wide
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2(1.4, 0.65), 0.08)
			tw.tween_property(self, "scale", Vector2(1.0, 1.0),  0.22)
		_:
			_state_timer = 0.0


func _player_in_range(range_px: float) -> bool:
	if _player_ref == null:
		return false
	return global_position.distance_to(_player_ref.global_position) <= range_px
