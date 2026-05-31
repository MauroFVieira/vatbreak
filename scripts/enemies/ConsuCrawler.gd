extends "res://scripts/enemies/EnemyBase.gd"

# ──────────────────────────────────────────────
#  ConsuCrawler.gd  —  Fast, low HP swarm unit
#  The Consu: numerous, alien in motivation.
# ──────────────────────────────────────────────

func _ready() -> void:
	species_id       = "consu_crawler"
	max_health       = 18
	move_speed       = 160.0
	contact_damage   = 8
	contact_cooldown = 0.8
	shard_color      = Color(0.18, 0.72, 0.55, 1)
	super._ready()
