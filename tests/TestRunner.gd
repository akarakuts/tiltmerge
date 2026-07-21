extends Node2D
## TestRunner — сцена для запуска всех тестов. Запускается через:
##   godot --headless tests/TestRunner.tscn
## (autoload-синглтоны инициализируются при загрузке сцены, в отличие от --script)

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	print("\n========================================")
	print("  TiltMerge — Test Suite")
	print("========================================")
	# ждём полной инициализации autoload-конфигов
	await get_tree().process_frame
	await get_tree().process_frame

	_run_unit_tests()
	_run_smoke_tests()

	print("\n========================================")
	print("  TOTAL: %d passed, %d failed" % [passed, failed])
	print("========================================")
	# код выхода: 1 если есть failures
	get_tree().quit(1 if failed > 0 else 0)


# ---------------------------------------------------------------------------
# UNIT TESTS — чистая логика GameConfig
# ---------------------------------------------------------------------------
func _run_unit_tests() -> void:
	print("\n--- UNIT TESTS (GameConfig) ---")
	_ut("radius_for_tier(1) == 28.0", func(): _eq(GameConfig.radius_for_tier(1), 28.0))
	_ut("radius grows with tier", func():
		_true(GameConfig.radius_for_tier(3) > GameConfig.radius_for_tier(1), "r3 > r1"))
	_ut("tier_data(1).score == 2", func(): _eq(int(GameConfig.tier_data(1).score), 2))
	_ut("tier_data(5).score == 32", func(): _eq(int(GameConfig.tier_data(5).score), 32))
	_ut("max_tier == 12", func(): _eq(GameConfig.max_tier(), 12))
	_ut("spawn_interval(0) == 1.5", func(): _eq(GameConfig.spawn_interval(0), 1.5))
	_ut("spawn_interval floors at 0.55", func(): _eq(GameConfig.spawn_interval(999999), 0.55))
	_ut("spawn_interval decreases with score", func():
		_true(GameConfig.spawn_interval(5000) < GameConfig.spawn_interval(0), "decreases"))
	_ut("pick_spawn_tier(0) always 1", func():
		var ok := true
		for i in 50:
			if GameConfig.pick_spawn_tier(0) != 1: ok = false; break
		_true(ok, "all tier 1 at score 0"))
	_ut("pick_spawn_tier(2000) reaches 3+", func():
		var mx := 0
		for i in 200: mx = maxi(mx, GameConfig.pick_spawn_tier(2000))
		_true(mx >= 3, "tier 3+ seen at score 2000"))
	_ut("color_for_tier valid", func(): _true(GameConfig.color_for_tier(1).a > 0.0, "alpha>0"))
	_ut("SkinsManager.color_for_tier valid", func():
		_true(SkinsManager.color_for_tier(1).a > 0.0, "alpha>0"))
	_ut("daily target is deterministic", func():
		_eq(GameConfig.daily_target_tier("2099-01-01"), GameConfig.daily_target_tier("2099-01-01")))
	_ut("daily target stays in configured range", func():
		var target := GameConfig.daily_target_tier("2099-01-01")
		_true(target >= 4 and target <= 6, "target=%d" % target))


# ---------------------------------------------------------------------------
# SMOKE TESTS — autoloads, сцены, сохранения
# ---------------------------------------------------------------------------
func _run_smoke_tests() -> void:
	print("\n--- SMOKE TESTS ---")
	# autoloads живы
	var autoloads := [
		"I18n", "GameConfig", "MergeBus", "SaveSystem", "GameManager", "AudioManager",
		"Haptics", "Achievements", "SkinsManager", "Analytics", "ABTest"
	]
	for name_ in autoloads:
		var node := get_node_or_null("/root/" + name_)
		_smoke("autoload %s exists" % name_, node != null)
	# все сцены грузятся
	var scene_paths := [
		"res://scenes/Boot.tscn", "res://scenes/MainMenu.tscn", "res://scenes/Onboarding.tscn",
		"res://scenes/Settings.tscn", "res://scenes/Leaderboard.tscn",
		"res://scenes/Skins.tscn",
		"res://scenes/Cube.tscn", "res://scenes/Game.tscn"
	]
	for scene_path in scene_paths:
		var loaded := load(scene_path) if ResourceLoader.exists(scene_path) else null
		_smoke("scene %s loads" % scene_path.get_file(), loaded != null and loaded is PackedScene)
	# save round-trip
	var before: int = SaveSystem.data.total_games
	SaveSystem.record_game_result("classic", 1234, 50, 4)
	_smoke("save total_games increments", SaveSystem.data.total_games == before + 1)
	_smoke("save best_score records", SaveSystem.best_score("classic") >= 1234)
	_smoke("save install_id exists", not str(SaveSystem.data.get("install_id", "")).is_empty())
	SaveSystem.load_data()
	_smoke("save round-trip reloads persisted data", SaveSystem.data.total_games == before + 1)
	var streak := SaveSystem.record_daily_play("2099-01-01")
	_smoke("daily streak starts at one", streak == 1)
	_smoke("daily play is idempotent", SaveSystem.record_daily_play("2099-01-01") == 1)
	_smoke("daily challenge completion persists", SaveSystem.complete_daily_challenge("2099-01-01"))
	_smoke("daily challenge completion is one-time", not SaveSystem.complete_daily_challenge("2099-01-01"))
	_smoke("A/B spawn cohort assigned", ABTest.get_flag("spawn_speed") in ["normal", "fast"])
	# achievements не падают
	Achievements.evaluate_run({"score": 1000, "max_tier": 3, "combo": 1, "merges": 10, "revives": 0, "score_swipe": 0})
	_smoke("achievements evaluate_run no crash", true)
	# Скин с достигнутым порогом должен не только отображаться доступным,
	# но и действительно выбираться с сохранением разблокировки.
	SaveSystem.data.best_score.classic = 5000
	var pastel_selected := SkinsManager.select("pastel")
	var score_skin_is_persisted: bool = (
		pastel_selected
		and SaveSystem.data.selected_skin == "pastel"
		and SaveSystem.data.unlocked_skins.has("pastel")
	)
	_smoke("score-unlocked skin can be selected", score_skin_is_persisted)
	# переводы зарегистрированы
	_smoke("translation 'menu.play' resolves", tr("menu.play") != "menu.play")
	# мульти-локализация: все языки загружены
	var loaded := TranslationServer.get_loaded_locales()
	_smoke(">= 20 translations loaded", loaded.size() >= 20)
	# авто-подбор локали Android: ru_RU → ru, de_DE → de, zh_CN → zh_CN, неизвестная → en
	_smoke("locale ru_RU maps to ru", I18n._best_locale_for("ru_RU") == "ru")
	_smoke("locale de_DE maps to de", I18n._best_locale_for("de_DE") == "de")
	_smoke("locale zh_CN maps to zh_CN", I18n._best_locale_for("zh_CN") == "zh_CN")
	_smoke("unknown locale falls back to en", I18n._best_locale_for("xx_YY") == "en")
	# реальные строки перевода для нескольких языков
	var saved_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("de")
	var de_play := tr("menu.play")
	TranslationServer.set_locale("ja")
	var ja_play := tr("menu.play")
	TranslationServer.set_locale("ar")
	var ar_settings := tr("settings.language")
	TranslationServer.set_locale(saved_locale)
	_smoke("de menu.play == SPIELEN", de_play == "SPIELEN")
	_smoke("ja menu.play == プレイ", ja_play == "プレイ")
	_smoke("ar settings.language == اللغة", ar_settings == "اللغة")


# --- фреймворк ---
func _ut(name_: String, fn: Callable) -> void:
	var before := failed
	fn.call()
	if failed == before:
		passed += 1
		print("  ✓ %s" % name_)
	else:
		print("  ✗ %s" % name_)


func _smoke(name_: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("  ✓ %s" % name_)
	else:
		failed += 1
		print("  ✗ %s" % name_)


func _eq(a, b) -> void:
	if a != b:
		print("      ASSERT EQ FAILED: %s != %s" % [str(a), str(b)])
		failed += 1


func _true(cond: bool, msg: String = "") -> void:
	if not cond:
		print("      ASSERT TRUE FAILED: %s" % msg)
		failed += 1
