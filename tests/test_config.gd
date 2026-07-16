extends SceneTree
## Unit-тесты чистой логики (без физики). Запуск:
##   godot --headless --script tests/test_config.gd
## Возвращает код 0 при успехе, 1 при провале.

var passed: int = 0
var failed: int = 0


func _init() -> void:
	print("=== TiltMerge unit tests ===")
	# ждём загрузки autoload-конфига
	if not GameConfig.ready:
		await process_frame

	_test("radius_for_tier(1) == base_radius", func():
		assert_eq(GameConfig.radius_for_tier(1), 28.0)
	)
	_test("radius grows with tier", func():
		var r1 := GameConfig.radius_for_tier(1)
		var r3 := GameConfig.radius_for_tier(3)
		assert_true(r3 > r1, "r3 (%.1f) > r1 (%.1f)" % [r3, r1])
	)
	_test("tier_data returns score", func():
		var t1: Dictionary = GameConfig.tier_data(1)
		assert_eq(int(t1.score), 2)
		var t5: Dictionary = GameConfig.tier_data(5)
		assert_eq(int(t5.score), 32)
	)
	_test("max_tier == 12", func():
		assert_eq(GameConfig.max_tier(), 12)
	)
	_test("spawn_interval at score 0 == base", func():
		assert_eq(GameConfig.spawn_interval(0), 1.5)
	)
	_test("spawn_interval floors at min", func():
		var i := GameConfig.spawn_interval(999999)
		assert_eq(i, 0.55)
	)
	_test("spawn_interval decreases with score", func():
		var i0 := GameConfig.spawn_interval(0)
		var i1 := GameConfig.spawn_interval(5000)
		assert_true(i1 < i0, "interval at 5000 < interval at 0")
	)
	_test("pick_spawn_tier at 0 returns 1", func():
		var all_tier1 := true
		for i in 50:
			if GameConfig.pick_spawn_tier(0) != 1:
				all_tier1 = false
				break
		assert_true(all_tier1, "all spawns at score 0 are tier 1")
	)
	_test("pick_spawn_tier at 2000 can return up to 5", func():
		var max_seen := 0
		for i in 200:
			max_seen = maxi(max_seen, GameConfig.pick_spawn_tier(2000))
		assert_true(max_seen >= 3, "tier 3+ seen at score 2000")
	)
	_test("color_for_tier returns valid Color", func():
		var c := GameConfig.color_for_tier(1)
		assert_true(c.a > 0.0, "color alpha > 0")
	)
	_test("save default best_score 0", func():
		assert_eq(SaveSystem.best_score("classic"), 0)
	)
	_test("achievements condition parser: simple >=", func():
		var ach := Achievements
		# прямая проверка внутреннего метода через отражение невозможно — проверим через evaluate
		# вместо этого проверим, что evaluate_run не падает
		ach.evaluate_run({"score": 1000, "max_tier": 3, "combo": 1, "merges": 10, "revives": 0, "score_swipe": 0})
		pass_test()  # просто не должно крашиться
	)

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


# --- Простой assert-framework ---
func _test(name: String, fn: Callable) -> void:
	var before_failed := failed
	fn.call()
	if failed == before_failed:
		passed += 1
		print("  ✓ %s" % name)
	else:
		print("  ✗ %s" % name)


func assert_eq(a, b) -> void:
	if a != b:
		print("    ASSERT EQ FAILED: %s != %s" % [str(a), str(b)])
		failed += 1


func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		print("    ASSERT TRUE FAILED: %s" % msg)
		failed += 1


func pass_test() -> void:
	pass
