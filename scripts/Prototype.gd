extends Node2D
## Prototype — связывает TiltController + Spawner + MergeLogic для теста механики.
## Фаза 1: нет меню, нет game over-экрана (просто метка), нет сохранения.
## Запуск: открыть scenes/Prototype.tscn в Godot и нажать F5.

@onready var _cubes: Node2D = $Cubes
@onready var _tilt: Node = $TiltController
@onready var _spawner: Node = $Spawner
@onready var _merge: Node = $MergeLogic

@onready var _score_label: Label = $HUD/ScoreLabel
@onready var _combo_label: Label = $HUD/ComboLabel
@onready var _game_over_label: Label = $HUD/GameOverLabel

var _game_over_line_y: float = 80.0
var _game_over_grace: float = 1.5
var _overhead_timer: float = 0.0
var _game_over: bool = false

const SPAWN_POS := Vector2(360, 120)


func _ready() -> void:
	# ждём, пока GameConfig загрузится (autoload выполняется до _ready сцены, но подстрахуемся)
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	_tilt.setup()
	_merge.setup(_cubes)
	_spawner.setup(_cubes, SPAWN_POS, 1.0, false)
	_merge.score_changed.connect(_on_score_changed)
	_merge.combo_changed.connect(_on_combo_changed)
	_game_over_line_y = float(GameConfig.cfg.game.game_over_line_y)
	_game_over_grace = float(GameConfig.cfg.game.game_over_grace_sec)
	_spawner.start()
	print("[Prototype] started — наклоняй телефоном или A/D, ←/→")


func _on_score_changed(new_score: int, _delta: int) -> void:
	_score_label.text = "Score: %d" % new_score
	_spawner.set_score(new_score)


func _on_combo_changed(combo_count: int, mult: float) -> void:
	_combo_label.text = "Combo: x%.1f" % mult


func _physics_process(delta: float) -> void:
	if _game_over:
		return
	# проверка game over: любой кубик выше линии дольше grace
	var any_overhead := false
	for cube in _cubes.get_children():
		if cube is Cube and cube.global_position.y < _game_over_line_y:
			any_overhead = true
			break
	if any_overhead:
		_overhead_timer += delta
		if _overhead_timer >= _game_over_grace:
			_trigger_game_over()
	else:
		_overhead_timer = 0.0


func _trigger_game_over() -> void:
	_game_over = true
	_spawner.stop()
	_game_over_label.text = "GAME OVER\nScore: %d\nPress R to restart" % _merge.score
	print("[Prototype] game over, score=%d" % _merge.score)


func _unhandled_input(event: InputEvent) -> void:
	if _game_over and event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
