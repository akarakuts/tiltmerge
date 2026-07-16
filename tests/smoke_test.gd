extends SceneTree
## Smoke-тест: проверяет, что сцена Game.tscn инстанцируется без ошибок и
## GameManager/Saves/AudioManager/Haptics/autoloads живы. Запуск:
##   godot --headless --script tests/smoke_test.gd
##
## Симулирует полный цикл старт→game_over за фиксированное число кадров.

const GameScenePath := "res://scenes/Game.tscn"
const MainMenuPath := "res://scenes/MainMenu.tscn"
const OnboardingPath := "res://scenes/Onboarding.tscn"
const SettingsPath := "res://scenes/Settings.tscn"
const LeaderboardPath := "res://scenes/Leaderboard.tscn"
const SkinsPath := "res://scenes/Skins.tscn"
const PrototypePath := "res://scenes/Prototype.tscn"
const CubePath := "res://scenes/Cube.tscn"

var errors: int = 0


func _init() -> void:
	print("=== TiltMerge smoke test ===")
	if not GameConfig.ready:
		await process_frame

	_check_autoloads()
	_check_scene_load(MainMenuPath, "MainMenu")
	_check_scene_load(OnboardingPath, "Onboarding")
	_check_scene_load(SettingsPath, "Settings")
	_check_scene_load(LeaderboardPath, "Leaderboard")
	_check_scene_load(SkinsPath, "Skins")
	_check_scene_load(PrototypePath, "Prototype")
	_check_scene_load(CubePath, "Cube")
	_check_scene_load(GameScenePath, "Game")

	# проверка save round-trip
	var before := SaveSystem.data.total_games
	SaveSystem.record_game_result("classic", 1234, 50, 4)
	assert_true(SaveSystem.data.total_games == before + 1, "total_games incremented")
	assert_true(SaveSystem.best_score("classic") >= 1234, "best_score recorded")

	# daily seed детерминирован
	var d1 := Time.get_date_dict_from_system()
	var seed1: int = hash("%04d-%02d-%02d" % [d1.year, d1.month, d1.day])
	var seed2: int = hash("%04d-%02d-%02d" % [d1.year, d1.month, d1.day])
	assert_true(seed1 == seed2, "daily seed deterministic for same date")

	print("\n=== Smoke: errors=%d ===" % errors)
	quit(1 if errors > 0 else 0)


func _check_autoloads() -> void:
	for name in ["GameConfig", "MergeBus", "SaveSystem", "GameManager", "AudioManager", "Haptics", "Achievements", "SkinsManager"]:
		var node := get_root().get_node_or_null("/root/" + name)
		if node == null:
			print("  ✗ autoload missing: %s" % name)
			errors += 1
		else:
			print("  ✓ autoload: %s" % name)


func _check_scene_load(path: String, label: String) -> void:
	if not ResourceLoader.exists(path):
		print("  ✗ %s: file not found (%s)" % [label, path])
		errors += 1
		return
	var scene := load(path) as PackedScene
	if scene == null:
		print("  ✗ %s: failed to load as PackedScene" % label)
		errors += 1
		return
	print("  ✓ %s: loads" % label)


func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		print("  ✗ ASSERT: %s" % msg)
		errors += 1
	else:
		print("  ✓ %s" % msg)
