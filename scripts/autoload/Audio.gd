extends Node

# ──────────────────────────────────────────────
#  Audio.gd  —  Autoload singleton
#
#  All game audio goes through here so individual
#  scripts stay clean.  Bullet fire is pooled
#  (10 players) to prevent self-interruption at
#  high fire rates.  Beam is a looping player that
#  fades in/out.  Everything else is a one-shot.
#
#  Usage (from any script):
#    Audio.play_bullet()
#    Audio.play_grenade()
#    Audio.play_explosion()
#    Audio.play_footstep()
#    Audio.start_beam()
#    Audio.stop_beam()
#    Audio.start_music()     ← called once from Main
# ──────────────────────────────────────────────

const BULLET_POOL_SIZE  := 10
const MUSIC_VOLUME_DB   := -10.0
const SFX_VOLUME_DB     := 0.0
const BEAM_VOLUME_DB    := -6.0
const FOOTSTEP_INTERVAL := 0.32   # seconds between footstep triggers

# Streams — loaded once at startup
var _s_bullet:    AudioStream
var _s_grenade:   AudioStream
var _s_explosion: AudioStream
var _s_beam:      AudioStream
var _s_footstep:  AudioStream
var _s_music:     AudioStream

# Bullet pool
var _bullet_pool: Array[AudioStreamPlayer] = []
var _bullet_pool_idx: int = 0

# Dedicated players
var _beam_player:     AudioStreamPlayer
var _music_player:    AudioStreamPlayer
var _grenade_player:  AudioStreamPlayer
var _explosion_player: AudioStreamPlayer

# Footstep state
var _footstep_timer: float = 0.0
var _player_moving:  bool  = false   # toggled by Player.gd


func _ready() -> void:
	_s_bullet    = load("res://bullet.ogg")
	_s_grenade   = load("res://grenade.ogg")
	_s_explosion = load("res://explosion.ogg")
	_s_beam      = load("res://beam.ogg")
	_s_footstep  = load("res://footstep.ogg")
	_s_music     = load("res://background_music.ogg")

	# Bullet pool
	for i in BULLET_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.stream      = _s_bullet
		p.volume_db   = SFX_VOLUME_DB - 4.0   # slightly quieter; rapid fire fills fast
		p.bus         = "SFX"
		add_child(p)
		_bullet_pool.append(p)

	# Beam — looping, starts silent
	_beam_player = AudioStreamPlayer.new()
	_beam_player.stream    = _s_beam
	_beam_player.volume_db = SFX_VOLUME_DB - 25.0
	_beam_player.bus       = "SFX"
	add_child(_beam_player)
	# Loop the beam: set loop via AudioStreamOggVorbis if available
	if _s_beam is AudioStreamOggVorbis:
		(_s_beam as AudioStreamOggVorbis).loop = true

	# Music — looping
	_music_player = AudioStreamPlayer.new()
	_music_player.stream    = _s_music
	_music_player.volume_db = MUSIC_VOLUME_DB
	_music_player.bus       = "Music"
	add_child(_music_player)
	if _s_music is AudioStreamOggVorbis:
		(_s_music as AudioStreamOggVorbis).loop = true

	# Grenade one-shot
	_grenade_player = AudioStreamPlayer.new()
	_grenade_player.stream    = _s_grenade
	_grenade_player.volume_db = SFX_VOLUME_DB
	_grenade_player.bus       = "SFX"
	add_child(_grenade_player)

	# Explosion one-shot
	_explosion_player = AudioStreamPlayer.new()
	_explosion_player.stream    = _s_explosion
	_explosion_player.volume_db = SFX_VOLUME_DB + 2.0
	_explosion_player.bus       = "SFX"
	add_child(_explosion_player)


func _process(delta: float) -> void:
	# Footstep ticker — Player.gd sets _player_moving each frame
	if _player_moving:
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			_footstep_timer = FOOTSTEP_INTERVAL
			_play_footstep_oneshot()
	else:
		_footstep_timer = 0.0   # reset so first step after stop fires immediately


# ── Public API ──────────────────────────────────

func play_bullet() -> void:
	# Round-robin the pool so we never interrupt a bullet that's still audible
	var p := _bullet_pool[_bullet_pool_idx]
	_bullet_pool_idx = (_bullet_pool_idx + 1) % BULLET_POOL_SIZE
	p.stop()
	p.play()


func play_grenade() -> void:
	_grenade_player.stop()
	_grenade_player.play()


func play_explosion() -> void:
	_explosion_player.stop()
	_explosion_player.play()


func start_beam() -> void:
	if not _beam_player.playing:
		_beam_player.play()


func stop_beam() -> void:
	_beam_player.stop()


func set_player_moving(moving: bool) -> void:
	_player_moving = moving


func start_music() -> void:
	if not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	_music_player.stop()


# ── Internal ────────────────────────────────────

func _play_footstep_oneshot() -> void:
	# Spawn a fresh one-shot player parented here so it outlives any scene change
	var p := AudioStreamPlayer.new()
	p.stream    = _s_footstep
	p.volume_db = SFX_VOLUME_DB - 8.0
	p.bus       = "SFX"
	# Slight random pitch variation so repeated footsteps don't sound mechanical
	p.pitch_scale = randf_range(0.88, 1.12)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
