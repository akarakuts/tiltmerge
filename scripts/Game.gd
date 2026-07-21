extends Node2D
## Game — главная игровая сцена (Фаза 2).
## Связывает TiltController + Spawner + MergeLogic + SaveSystem + GameManager.
## Поддерживает режимы (classic/blitz/zen/daily) и подсчёт max_tier/merges.

@onready var _cubes: Node2D = $Cubes
@onready var _tilt: Node = $TiltController
@onready var _spawner: Node = $Spawner
@onready var _merge: Node = $MergeLogic
@onready var _camera_shake: Camera2D = $Camera2D

@onready var _hud: CanvasLayer = $HUD

@onready var _score_label: Label = $HUD/TopBar/TopVBox/Row1/ScoreLabel
@onready var _combo_label: Label = $HUD/TopBar/TopVBox/ComboLabel
@onready var _next_label: Label = $HUD/TopBar/TopVBox/Row2/NextLabel
@onready var _reroll_btn: Button = $HUD/TopBar/TopVBox/Row2/RerollButton
@onready var _objective_label: Label = $HUD/TopBar/TopVBox/ObjectiveLabel
@onready var _timer_label: Label = $HUD/TopBar/TopVBox/Row1/TimerLabel
@onready var _pause_btn: Button = $HUD/TopBar/TopVBox/Row1/PauseButton
@onready var _game_over_panel: Control = $HUD/GameOverPanel
@onready var _go_score: Label = $HUD/GameOverPanel/Card/VBox/GoScore
@onready var _go_best: Label = $HUD/GameOverPanel/Card/VBox/GoBest
@onready var _restart_btn: Button = $HUD/GameOverPanel/Card/VBox/RestartButton
@onready var _menu_btn: Button = $HUD/GameOverPanel/Card/VBox/MenuButton
@onready var _pause_panel: Control = $HUD/PausePanel
@onready var _paused_label: Label = $HUD/PausePanel/Card/VBox/PausedLabel
@onready var _resume_hint: Label = $HUD/PausePanel/Card/VBox/ResumeHint
@onready var _resume_btn: Button = $HUD/PausePanel/Card/VBox/ResumeButton
@onready var _go_title: Label = $HUD/GameOverPanel/Card/VBox/Title

var _game_over_line_y: float = 80.0
var _game_over_grace: float = 1.5
var _overhead_timer: float = 0.0
var _max_tier_this_run: int = 1
var _merges_this_run: int = 0

var _mode: String = "classic"
var _mode_cfg: Dictionary = {}
var _blitz_time_left: float = 0.0
var _reroll_charges: int = 0
var _reroll_max_charges: int = 0
var _reroll_combo_interval: int = 3
var _daily_date_key: String = ""
var _daily_target_tier: int = 0
var _daily_complete: bool = false

func _ready() -> void:
	# Игра должна получать ui_pause и во время глобальной паузы, иначе Esc
	# не сможет закрыть пауз-экран (хотя это обещано в интерфейсе).
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	_mode = GameManager.current_mode
	_mode_cfg = GameConfig.cfg.modes.get(_mode, GameConfig.cfg.modes.classic)
	_tilt.setup(_cubes)
	_tilt.set_control_mode(str(SaveSystem.data.settings.control_mode))
	_merge.setup(_cubes)
	_merge.reset()
	var decor := get_node_or_null("ArenaDecor")
	if decor != null and decor.has_method("setup"):
		decor.setup(get_node_or_null("DangerLine") as Line2D)
	var seeded: bool = bool(_mode_cfg.get("seeded", false))
	var spawn_mult: float = float(_mode_cfg.get("spawn_interval_mult", 1.0))
	if ABTest.is_variant("spawn_speed", "fast"):
		spawn_mult *= 0.85
	var spawn_pos := Vector2(
		float(GameConfig.cfg.game.spawn_pos.x),
		float(GameConfig.cfg.game.spawn_pos.y))
	_spawner.setup(_cubes, spawn_pos, spawn_mult, seeded)

	_merge.score_changed.connect(_on_score_changed)
	_merge.combo_changed.connect(_on_combo_changed)
	MergeBus.merge_completed.connect(_on_merge_completed)
	_spawner.next_tier_changed.connect(_on_next_tier_changed)

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
	_resume_btn.pressed.connect(_on_resume)
	_game_over_panel.visible = false
	_pause_panel.visible = false
	# HUD must keep receiving touch and mouse events while the game tree is paused.
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	UiTheme.apply($HUD/TopBar)
	UiTheme.apply($HUD/PausePanel/Card)
	UiTheme.apply($HUD/GameOverPanel/Card)
	_apply_localized_text()
	_setup_tactics()
	_reroll_btn.pressed.connect(_on_reroll_pressed)

	GameManager.go(GameManager.State.PLAYING)
	_spawner.start()
	_merge.score = 0
	AudioManager.play_music("music_game")
	if _mode == "daily":
		var date := Time.get_date_dict_from_system()
		_daily_date_key = "%04d-%02d-%02d" % [date.year, date.month, date.day]
		_daily_target_tier = GameConfig.daily_target_tier(_daily_date_key)
		_daily_complete = str(SaveSystem.data.daily.get("completed_date", "")) == _daily_date_key
		_update_daily_objective()
		Analytics.daily_played(SaveSystem.record_daily_play(_daily_date_key))
	else:
		_objective_label.hide()
	# тап по пауз-панели возобновляет игру
	_pause_panel.gui_input.connect(_on_pause_panel_input)
	if OS.is_debug_build():
		print("[Game] started mode=%s" % _mode)


func _on_pause_panel_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		_on_resume()
		get_viewport().set_input_as_handled()


func _on_score_changed(new_score: int, delta: int, is_merge: bool) -> void:
	_score_label.text = "%s: %d" % [tr("game.score"), new_score]
	_spawner.set_score(new_score)
	_update_tactics_ui()
	if is_merge:
		_merges_this_run += 1
		AudioManager.play_sfx("merge", 1.0 + min(0.3, _merges_this_run * 0.01))
		if delta < 100:
			Haptics.light()
		else:
			Haptics.medium()
		# camera shake пропорционально очкам слияния
		_camera_shake.shake(clampf(float(delta) / 300.0, 0.1, 0.8), 0.25)
	else:
		AudioManager.play_sfx("combo", 1.15)
		Haptics.medium()
		_camera_shake.shake(0.45, 0.35)


func _on_combo_changed(combo_count: int, mult: float) -> void:
	_combo_label.text = "%s: x%.1f" % [tr("game.combo"), mult]
	if combo_count > 0 and combo_count % _reroll_combo_interval == 0:
		_reroll_charges = mini(_reroll_charges + 1, _reroll_max_charges)
		_update_tactics_ui()


func _on_merge_completed(_new_cube: Node, _old_tier: int, new_tier: int, _pos: Vector2) -> void:
	_max_tier_this_run = maxi(_max_tier_this_run, new_tier)
	Analytics.merge_event(new_tier, _merge.combo_count)
	if _mode == "daily" and not _daily_complete and new_tier >= _daily_target_tier:
		_daily_complete = SaveSystem.complete_daily_challenge(_daily_date_key)
		if _daily_complete:
			var bonus: int = int(GameConfig.cfg.daily.target_bonus)
			_merge.award_bonus(bonus, tr("game.daily_complete"))
			Analytics.daily_completed(_daily_target_tier, bonus)
			_update_daily_objective()


func _setup_tactics() -> void:
	_reroll_charges = int(GameConfig.cfg.tactics.reroll_starting_charges)
	_reroll_max_charges = int(GameConfig.cfg.tactics.reroll_max_charges)
	_reroll_combo_interval = int(GameConfig.cfg.tactics.reroll_combo_interval)
	_update_tactics_ui()
	_on_next_tier_changed(_spawner.peek_next_tier())


func _on_next_tier_changed(tier: int) -> void:
	_next_label.text = "%s: %d" % [tr("game.next"), tier]
	_next_label.modulate = SkinsManager.color_for_tier(tier)


func _on_reroll_pressed() -> void:
	if _reroll_charges <= 0 or not _spawner.can_reroll_next_tier() or GameManager.state != GameManager.State.PLAYING:
		return
	if not _spawner.reroll_next_tier():
		return
	_reroll_charges -= 1
	_update_tactics_ui()
	AudioManager.play_sfx("button")
	Haptics.light()
	Analytics.reroll_used(_reroll_charges)


func _update_tactics_ui() -> void:
	_reroll_btn.text = "%s (%d)" % [tr("game.reroll"), _reroll_charges]
	_reroll_btn.disabled = _reroll_charges <= 0 or not _spawner.can_reroll_next_tier()


func _update_daily_objective() -> void:
	_objective_label.show()
	if _daily_complete:
		_objective_label.text = tr("game.daily_done")
	else:
		_objective_label.text = tr("game.daily_goal") % _daily_target_tier


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
	_merge.stop()
	var score: int = _merge.score
	GameManager.end_game(score, _merges_this_run, _max_tier_this_run)
	# оценки достижений по итогам забега
	var control_is_swipe: bool = str(SaveSystem.data.settings.control_mode) == "swipe"
	Achievements.evaluate_run({
		"score": score,
		"max_tier": _max_tier_this_run,
		"combo": _merge.combo_count,
		"merges": _merges_this_run,
		"score_swipe": score if control_is_swipe else 0
	})
	# показываем панель
	_go_score.text = "%s: %d" % [tr("game.score"), score]
	_go_best.text = "%s: %d" % [tr("game.best"), SaveSystem.best_score(_mode)]
	_game_over_panel.visible = true
	AudioManager.play_sfx("game_over")
	Haptics.custom(150)
	_camera_shake.shake(0.7, 0.6)
	if OS.is_debug_build():
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
	BackHandler.block_quit_briefly()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _apply_localized_text() -> void:
	_score_label.text = "%s: 0" % tr("game.score")
	_combo_label.text = "%s: x1.0" % tr("game.combo")
	_paused_label.text = tr("game.paused")
	_resume_hint.text = tr("game.resume_hint")
	_resume_btn.text = tr("game.resume")
	_go_title.text = tr("game.game_over")
	_go_score.text = "%s: 0" % tr("game.score")
	_go_best.text = "%s: 0" % tr("game.best")
	_restart_btn.text = tr("game.restart")
	_menu_btn.text = tr("game.menu")
	_go_title.add_theme_color_override("font_color", UiTheme.COL_DANGER)
	_go_best.add_theme_color_override("font_color", UiTheme.COL_ACCENT)
	_combo_label.add_theme_color_override("font_color", UiTheme.COL_MUTED)
	var danger := get_node_or_null("DangerLine") as Line2D
	if danger:
		danger.clear_points()
		danger.add_point(Vector2(40, _game_over_line_y))
		danger.add_point(Vector2(680, _game_over_line_y))
		danger.default_color = Color(UiTheme.COL_DANGER.r, UiTheme.COL_DANGER.g, UiTheme.COL_DANGER.b, 0.55)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		if GameManager.state == GameManager.State.PLAYING:
			_on_pause()
		elif GameManager.state == GameManager.State.PAUSED:
			_on_resume()
		get_viewport().set_input_as_handled()


func handle_android_back() -> void:
	if _game_over_panel.visible:
		_on_to_menu()
		return
	if GameManager.state == GameManager.State.PAUSED or _pause_panel.visible:
		_on_resume()
		return
	if GameManager.state == GameManager.State.PLAYING:
		_on_pause()
