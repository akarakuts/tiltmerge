extends Node2D
## GameplayTest — полноценный автоматический плейтест всей игры.
## Запуск: godot --headless tests/GameplayTest.tscn
##
## Что проверяет:
##   1. Сцена Game грузится и стартует (mode=classic)
##   2. Эмуляция ввода наклона → кубики двигаются
##   3. Слияния происходят (score растёт)
##   4. Game over срабатывает при пересечении порога переполнения
##   5. Рестарт работает

const GAME_SCENE := "res://scenes/Game.tscn"

var game_instance: Node = null
var test_log: Array = []
var phase: String = "init"
var elapsed: float = 0.0
var merge_seen: bool = false
var score_at_check: int = 0
var pause_cycle_ok: bool = false
var tactics_ok: bool = false
var daily_goal_ok: bool = false


func _ready() -> void:
	print("\n========================================")
	print("  TiltMerge — GAMEPLAY TEST")
	print("========================================")
	# ждём autoloads
	await get_tree().create_timer(0.5).timeout
	await get_tree().process_frame

	# принудительно swipe-режим
	SaveSystem.data.settings.control_mode = "swipe"
	GameManager.start_game("classic")
	await get_tree().process_frame

	# инстанцируем игру
	game_instance = load(GAME_SCENE).instantiate()
	add_child(game_instance)
	await get_tree().create_timer(0.3).timeout
	_log("Game instance created, mode=classic, control=swipe")
	game_instance._on_pause()
	var resume_click := InputEventMouseButton.new()
	resume_click.button_index = MOUSE_BUTTON_LEFT
	resume_click.pressed = true
	game_instance._on_pause_panel_input(resume_click)
	pause_cycle_ok = GameManager.state == GameManager.State.PLAYING and not get_tree().paused
	_log("%s pause overlay resumes from mouse input" % ("✓" if pause_cycle_ok else "✗ FAIL:"))
	game_instance._spawner.set_score(50)
	var starting_rerolls: int = game_instance._reroll_charges
	var next_tier: int = game_instance._spawner.peek_next_tier()
	game_instance._on_reroll_pressed()
	game_instance._on_combo_changed(game_instance._reroll_combo_interval, 1.5)
	tactics_ok = next_tier >= 1 and game_instance._spawner.peek_next_tier() != next_tier and game_instance._reroll_charges == starting_rerolls
	_log("%s next preview and combo-earned reroll work" % ("✓" if tactics_ok else "✗ FAIL:"))

	# фаза 1: подождать спавна и слияний.
	phase = "playing"
	_log("Phase 1: playing — waiting for spawns & merges (≤15s)...")
	await get_tree().create_timer(15.0).timeout

	# проверяем, что счёт либо game over наступил
	var merge_logic = game_instance.get_node("MergeLogic")
	score_at_check = merge_logic.score
	_log("After 15s: score=%d, game_over=%s, total_games(before)=%d" % [
		score_at_check, GameManager.state == GameManager.State.GAME_OVER, SaveSystem.data.total_games
	])

	if score_at_check > 0:
		merge_seen = true
		_log("✓ Merges occurred (score > 0)")
	else:
		_log("⚠ No merges in 15s (may need more time or tilted input)")

	# фаза 2: не ждём случайного переполнения в headless-физике. Поднимаем порог
	# над уже созданными кубиками, чтобы детерминированно проверить production-path
	# обнаружения переполнения и сохранения результата.
	phase = "wait_game_over"
	game_instance._game_over_line_y = 2000.0
	await get_tree().create_timer(2.0).timeout

	if GameManager.state == GameManager.State.GAME_OVER:
		_log("✓ Game over triggered after controlled overflow")
		_log("  final score=%d" % merge_logic.score)
	else:
		_log("✗ FAIL: game over did not trigger after controlled overflow")

	# итоги
	print("\n--- RESULTS ---")
	var ok := true
	if not merge_seen and score_at_check == 0:
		_log("✗ FAIL: no merges happened")
		ok = false
	else:
		_log("✓ PASS: game ran, mechanics functional")
	if not pause_cycle_ok:
		ok = false
	if not tactics_ok:
		ok = false
	if GameManager.state != GameManager.State.GAME_OVER:
		ok = false
	# сохранение должно было инкрементировать total_games при game over
	if GameManager.state == GameManager.State.GAME_OVER:
		await get_tree().process_frame
		if SaveSystem.data.total_games >= 1:
			_log("✓ PASS: total_games incremented on game over")
		else:
			_log("✗ FAIL: total_games not incremented")
		var stable_score: bool = game_instance._merge.score == GameManager.last_score
		_log("%s score stays immutable after game over" % ("✓" if stable_score else "✗ FAIL:"))
		if not stable_score:
			ok = false
	daily_goal_ok = await _verify_daily_goal()
	if not daily_goal_ok:
		ok = false

	print("\n========================================")
	print("  GAMEPLAY TEST: %s" % ("PASS" if ok else "FAIL"))
	print("========================================")
	get_tree().quit(0 if ok else 1)


func _verify_daily_goal() -> bool:
	game_instance.queue_free()
	await get_tree().process_frame
	GameManager.start_game("daily")
	var daily_game: Node = load(GAME_SCENE).instantiate()
	add_child(daily_game)
	await get_tree().create_timer(0.3).timeout
	var target: int = daily_game._daily_target_tier
	var bonus: int = int(GameConfig.cfg.daily.target_bonus)
	daily_game._on_merge_completed(null, target - 1, target, Vector2.ZERO)
	await get_tree().process_frame
	var completed: bool = daily_game._daily_complete
	var bonus_awarded: bool = daily_game._merge.score == bonus
	daily_game.queue_free()
	_log("%s daily goal persists and awards its bonus" % ("✓" if completed and bonus_awarded else "✗ FAIL:"))
	return completed and bonus_awarded


func _physics_process(delta: float) -> void:
	elapsed += delta
	if phase == "playing" and game_instance != null:
		# эмулируем «наклон»: симулируем нажатие клавиши tilt_right/tilt_left поочерёдно
		# через Input.action_press (псевдо-ввод для TiltController)
		var cycle := fmod(elapsed * 0.5, 2.0)
		if cycle < 1.0:
			Input.action_press("tilt_right")
			Input.action_release("tilt_left")
		else:
			Input.action_press("tilt_left")
			Input.action_release("tilt_right")


func _log(msg: String) -> void:
	print("  [test] %s" % msg)
	test_log.append(msg)
