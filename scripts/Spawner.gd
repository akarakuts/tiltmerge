extends Node
## Spawner
## Спавнит кубики сверху по центру с интервалом, зависящим от очков.
## Интервал = GameConfig.spawn_interval(score).
## Tier выбирается через GameConfig.pick_spawn_tier(score).

const CUBE_SCENE: PackedScene = preload("res://scenes/Cube.tscn")

var _root: Node2D
var _spawn_pos: Vector2
var _timer: float = 0.0
var _mode_spawn_mult: float = 1.0
var _current_score: int = 0
var _active: bool = false
var _seeded: bool = false
var _rng := RandomNumberGenerator.new()

signal cube_spawned(cube: Node)
signal score_readback(score: int)  # чтобы Spawner знал текущий score
signal next_tier_changed(tier: int)

var _next_tier: int = 1


func setup(root: Node2D, spawn_pos: Vector2, mode_mult: float = 1.0, seeded: bool = false) -> void:
	_root = root
	_spawn_pos = spawn_pos
	_mode_spawn_mult = mode_mult
	_seeded = seeded
	if seeded:
		_rng.seed = _daily_seed()
	else:
		_rng.randomize()
	_roll_next_tier()


func start() -> void:
	_active = true
	_timer = 0.0


func stop() -> void:
	_active = false


func set_score(s: int) -> void:
	_current_score = s


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_spawn()
		var interval: float = GameConfig.spawn_interval(_current_score) * _mode_spawn_mult
		_timer = interval


func _spawn() -> void:
	var tier := _next_tier
	_roll_next_tier()
	var cube = CUBE_SCENE.instantiate()
	_root.add_child(cube)
	cube.global_position = _spawn_pos + Vector2(_rng.randf_range(-30, 30), 0)
	cube.setup(tier)
	cube_spawned.emit(cube)


func peek_next_tier() -> int:
	return _next_tier


func can_reroll_next_tier() -> bool:
	return GameConfig.spawn_group_for_score(_current_score).tiers.size() > 1


func reroll_next_tier() -> bool:
	if not can_reroll_next_tier():
		return false
	var previous_tier := _next_tier
	for attempt in 4:
		_roll_next_tier()
		if _next_tier != previous_tier:
			return true
	# Even a heavily weighted pool must make the paid tactical choice meaningful.
	for tier in GameConfig.spawn_group_for_score(_current_score).tiers:
		if int(tier) != previous_tier:
			_next_tier = int(tier)
			next_tier_changed.emit(_next_tier)
			return true
	return false


func _roll_next_tier() -> void:
	# seeded daily: один RNG на забег; classic: тот же API без seed
	_next_tier = GameConfig.pick_spawn_tier(_current_score, _rng)
	next_tier_changed.emit(_next_tier)


# --- Детерминированный seed для Daily Challenge ---
func _daily_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return hash("%04d-%02d-%02d" % [d.year, d.month, d.day])
