extends Node2D
## Game — главная игровая сцена (Фаза 2).
## Связывает TiltController + Spawner + MergeLogic + SaveSystem + GameManager.
## Поддерживает режимы (classic/blitz/zen/daily) и подсчёт max_tier/merges.

@onready var _cubes: Node2D = $Cubes
@onready var _tilt: Node = $TiltController
@onready var _spawner: Node = $Spawner
@onready var _merge: Node = $MergeLogic
@onready var _camera_shake: Camera2D = $Camera2D

@onready var _score_label: Label = $HUD/ScoreLabel
@onready var _combo_label: Label = $HUD/ComboLabel
@onready var _timer_label: Label = $HUD/TimerLabel
@onready var _pause_btn: Button = $HUD/PauseButton
@onready var _game_over_panel: Control = $HUD/GameOverPanel
@onready var _go_score: Label = $HUD/GameOverPanel/VBox/GoScore
@onready var _go_best: Label = $HUD/GameOverPanel/VBox/GoBest
@onready var _restart_btn: Button = $HUD/GameOverPanel/VBox/RestartButton
@onready var _menu_btn: Button = $HUD/GameOverPanel/VBox/MenuButton
@onready var _pause_panel: Control = $HUD/PausePanel

var _game_over_line_y: float = 80.0
var _game_over_grace: float = 1.5
var _overhead_timer: float = 0.0
var _max_tier_this_run: int = 1
var _merges_this_run: int = 0

var _mode: String = "classic"
var _mode_cfg: Dictionary = {}
var _blitz_time_left: float = 0.0

const SPAWN_POS := Vector2(360, 120)


func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	_mode = GameManager.current_mode
	_mode_cfg = GameConfig.cfg.modes.get(_mode, GameConfig.cfg.modes.classic)
	_tilt.setup(_cubes)
	_tilt.set_control_mode(str(SaveSystem.data.settings.control_mode))
	_merge.setup(_cubes)
	_merge.reset()
	var seeded: bool = bool(_mode_cfg.get("seeded", false))
	var spawn_mult: float = float(_mode_cfg.get("spawn_interval_mult", 1.0))
	_spawner.setup(_cubes, SPAWN_POS, spawn_mult, seeded)

	_merge.score_changed.connect(_on_score_changed)
	_merge.combo_changed.connect(_on_combo_changed)
	MergeBus.merge_completed.connect(_on_merge_completed)

	_game_over_line_y = float(GameConfig.cfg.game.game_over_line_y)
	_game_over_grace = float(GameConfig.cfg.game.game_over_grace_sec)

	# Blitz — таймер
	if _mode_cfg.has("duration_sec") and _mode_cfg.duration_sec != null:
		_blitz_time_left = float(_mode_cfg.duration_sec)
		_timer_label.visible = true
	else:
		_timer_label.visible = false

	_pause_btn.pressed.connect(_on_pause)
	_restart_btn.pressed.connect(_on_restart)
	_menu_btn.pressed.connect(_on_to_menu)
	_game_over_panel.visible = false
	_pause_panel.visible = false

	GameManager.go(GameManager.State.PLAYING)
	_spawner.start()
	_merge.score = 0
	AudioManager.play_music("music_game")
	# тап по пауз-панели возобновляет игру
	_pause_panel.gui_input.connect(_on_pause_panel_input)
	print("[Game] started mode=%s" % _mode)


func _on_pause_panel_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_on_resume()


func _on_score_changed(new_score: int, delta: int) -> void:
	_score_label.text = "Score: %d" % new_score
	_spawner.set_score(new_score)
	_merges_this_run += 1
	AudioManager.play_sfx("merge", 1.0 + min(0.3, _merges_this_run * 0.01))
	if delta < 100:
		Haptics.light()
	else:
		Haptics.medium()
	# camera shake пропорционально очкам слияния
	_camera_shake.shake(clampf(float(delta) / 300.0, 0.1, 0.8), 0.25)


func _on_combo_changed(_combo_count: int, mult: float) -> void:
	_combo_label.text = "Combo: x%.1f" % mult


func _on_merge_completed(new_cube: Node, _old_tier: int, new_tier: int, _pos: Vector2) -> void:
	_max_tier_this_run = maxi(_max_tier_this_run, new_tier)


func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	# Blitz — обратный отсчёт
	if _timer_label.visible:
		_blitz_time_left -= delta
		_timer_label.text = "%.1f" % maxf(0.0, _blitz_time_left)
		if _blitz_time_left <= 0.0:
			_trigger_game_over()
			return
	# Game over по переполнению (если режим это разрешает)
	if not bool(_mode_cfg.get("game_over", true)):
		return
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
	_spawner.stop()
	var score: int = _merge.score
	GameManager.end_game(score, _merges_this_run, _max_tier_this_run)
	# оценки достижений по итогам забега
	var control_is_swipe: bool = str(SaveSystem.data.settings.control_mode) == "swipe"
	Achievements.evaluate_run({
		"score": score,
		"max_tier": _max_tier_this_run,
		"combo": _merge.combo_count,
		"merges": _merges_this_run,
		"revives": 0,
		"score_swipe": score if control_is_swipe else 0
	})
	# показываем панель
	_go_score.text = "Score: %d" % score
	_go_best.text = "Best: %d" % SaveSystem.best_score(_mode)
	_game_over_panel.visible = true
	AudioManager.play_sfx("game_over")
	Haptics.custom(150)
	_camera_shake.shake(0.7, 0.6)
	print("[Game] game over score=%d max_tier=%d" % [score, _max_tier_this_run])


func _on_pause() -> void:
	if GameManager.state == GameManager.State.PLAYING:
		GameManager.pause_game()
		_pause_panel.visible = true
		get_tree().paused = true


func _on_resume() -> void:
	_pause_panel.visible = false
	get_tree().paused = false
	GameManager.resume_game()


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		if GameManager.state == GameManager.State.PLAYING:
			_on_pause()
		elif GameManager.state == GameManager.State.PAUSED:
			_on_resume()
		get_viewport().set_input_as_handled()
