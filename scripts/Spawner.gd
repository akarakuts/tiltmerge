extends Node
## Spawner
## Спавнит кубики сверху по центру с интервалом, зависящим от очков.
## Интервал = GameConfig.spawn_interval(score).
## Tier выбирается через GameConfig.pick_spawn_tier(score).

const CubeScenePath := "res://scenes/Cube.tscn"

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


func setup(root: Node2D, spawn_pos: Vector2, mode_mult: float = 1.0, seeded: bool = false) -> void:
	_root = root
	_spawn_pos = spawn_pos
	_mode_spawn_mult = mode_mult
	_seeded = seeded
	if seeded:
		_rng.seed = _daily_seed()
	else:
		_rng.randomize()


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
	var tier: int = GameConfig.pick_spawn_tier(_current_score)
	if _seeded:
		# переопределяем выбор tier детерминированно для Daily
		tier = _seeded_pick_tier()
	var scene := load(CubeScenePath) as PackedScene
	var cube = scene.instantiate()
	_root.add_child(cube)
	cube.global_position = _spawn_pos + Vector2(_rng.randf_range(-30, 30), 0)
	cube.setup(tier)
	cube_spawned.emit(cube)


# --- Детерминированный выбор для Daily Challenge ---
func _daily_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return hash("%04d-%02d-%02d" % [d.year, d.month, d.day])


func _seeded_pick_tier() -> int:
	var group: Dictionary = GameConfig.cfg.spawn.score_tiers[0]
	for g in GameConfig.cfg.spawn.score_tiers:
		if _current_score >= int(g.min_score):
			group = g
		else:
			break
	var tiers: Array = group.tiers
	var weights: Array = group.weights
	var total := 0
	for w in weights:
		total += int(w)
	var roll := _rng.randi() % total
	var acc := 0
	for i in range(tiers.size()):
		acc += int(weights[i])
		if roll < acc:
			return int(tiers[i])
	return int(tiers[0])
