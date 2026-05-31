extends CharacterBody2D

# ──────────────────────────────────────────────
#  EnemyBase.gd
#  Inherited by each species scene.
#  Override: _species_process(delta) for unique AI.
# ──────────────────────────────────────────────

@export var species_id: String = "unknown"
@export var max_health: int = 30
@export var move_speed: float = 80.0
@export var contact_damage: int = 10
@export var contact_cooldown: float = 1.0

var health: int
var dead: bool = false

# NanoBurn DoT
var nano_burn_damage: int = 0
var nano_burn_stacks: int = 0
const NANO_BURN_TICK := 0.5
const NANO_BURN_DURATION := 3.0
var _nano_burn_timer: float = 0.0
var _nano_burn_elapsed: float = 0.0

var _contact_timer: float = 0.0
var _player_ref: Node = null


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	_find_player()


func _physics_process(delta: float) -> void:
	if dead:
		return
	_process_nano_burn(delta)
	_contact_timer = maxf(_contact_timer - delta, 0.0)
	_species_process(delta)
	move_and_slide()


# ── Override in subclasses ──
func _species_process(_delta: float) -> void:
	_chase_player()


func _chase_player() -> void:
	if _player_ref == null:
		_find_player()
		return
	var dir:Vector2 = ((_player_ref.global_position - global_position).normalized())
	velocity = dir * move_speed


func _find_player() -> void:
	_player_ref = get_tree().get_first_node_in_group("player")


# ── Damage ──
func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	if health <= 0:
		die()


func apply_nano_burn(dps: int) -> void:
	nano_burn_stacks += 1
	nano_burn_damage += dps
	_nano_burn_elapsed = 0.0   # refresh duration
	_nano_burn_timer = 0.0


func _process_nano_burn(delta: float) -> void:
	if nano_burn_stacks == 0:
		return
	_nano_burn_elapsed += delta
	_nano_burn_timer   += delta
	if _nano_burn_timer >= NANO_BURN_TICK:
		_nano_burn_timer -= NANO_BURN_TICK
		take_damage(nano_burn_damage)
	if _nano_burn_elapsed >= NANO_BURN_DURATION:
		nano_burn_stacks = 0
		nano_burn_damage = 0


func die() -> void:
	dead = true
	# TODO: death VFX / loot drop
	call_deferred("queue_free")


# ── Contact damage on player ──
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and _contact_timer <= 0.0:
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
		_contact_timer = contact_cooldown
