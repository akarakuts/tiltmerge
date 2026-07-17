extends Node2D
## OnboardingTest — проверяет интерактивный онбординг.
## Запуск: godot --headless tests/OnboardingTest.tscn
##
## Что проверяет:
##   1. Сцена инстанцируется без ошибок
##   2. Стартует на шаге 0 (3 шага всего)
##   3. Шаг 0 → можно завершить (помещаем кубик в goal area)
##   4. Переход к шагу 1, шаг 2
##   5. Финальный шаг показывает кнопку
##
## Симуляция: напрямую двигаем кубик в goal и триггерим merge через MergeBus.

const OnboardingScene := "res://scenes/Onboarding.tscn"
var ob: Node = null
var passed: int = 0
var failed: int = 0


func _ready() -> void:
	print("\n========================================")
	print("  Onboarding — INTERACTIVE TEST")
	print("========================================")
	await get_tree().create_timer(0.4).timeout
	await get_tree().process_frame
	# This scenario intentionally covers the interactive A/B variant.
	ABTest._flags["onboarding_style"] = "interactive"

	ob = load(OnboardingScene).instantiate()
	add_child(ob)
	await get_tree().create_timer(0.3).timeout

	# 1. сцена стартовала на шаге 0
	_check("starts on step 0", ob._step == 0)
	_check("has 3 steps total", ob.STEP_COUNT == 3)
	_check("step 0 spawned a cube", ob._step_cube != null and is_instance_valid(ob._step_cube))
	_check("goal visible on step 0", ob._goal.visible)

	# 2. симулируем достижение цели: эмулируем body_entered (в headless прямое
	#    перемещение позиции не вызывает коллизию Area2D — нужен физический контакт)
	print("  [sim] cube enters goal area...")
	if ob._step_cube:
		ob._goal_area.body_entered.emit(ob._step_cube)
	await get_tree().create_timer(0.3).timeout
	_check("goal_reached flag set", ob._goal_reached)
	await get_tree().create_timer(0.2).timeout
	_check("step 0 completed (button shown)", ob._step_done and ob._next_btn.visible)

	# 3. переходим к шагу 1 (merge)
	ob._on_next()
	await get_tree().create_timer(0.3).timeout
	_check("advanced to step 1", ob._step == 1)
	_check("step 1 has two cubes", ob._step_cube != null and ob._step_cube2 != null)

	# 4. симулируем merge через шину (как сделал бы MergeLogic при столкновении)
	print("  [sim] triggering merge...")
	MergeBus.merge_completed.emit(null, 1, 2, Vector2(360, 700))
	await get_tree().create_timer(0.3).timeout
	_check("step 1 completed after merge", ob._step_done)

	# 5. шаг 2
	ob._on_next()
	await get_tree().create_timer(0.3).timeout
	_check("advanced to step 2", ob._step == 2)
	_check("step 2 shows Lets Go button", ob._next_btn.visible)
	SaveSystem.complete_onboarding()
	_check("completing onboarding is persisted", SaveSystem.data.onboarding_completed)
	ob.queue_free()
	await get_tree().process_frame

	# The alternate onboarding A/B path is deterministic when explicitly selected.
	var slide_ob: Node = load(OnboardingScene).instantiate()
	slide_ob.style_override = "3slides"
	add_child(slide_ob)
	await get_tree().process_frame
	_check("slide variant starts on first slide", slide_ob._slide_mode and slide_ob._step == 0)
	_check("slide variant keeps arena hidden", not slide_ob._arena.visible)
	_check("slide variant exposes Next button", slide_ob._next_btn.visible)
	slide_ob._on_next()
	_check("slide variant advances to second slide", slide_ob._step == 1)
	slide_ob.queue_free()
	AudioManager.release_resources()
	await get_tree().process_frame

	print("\n========================================")
	print("  ONBOARDING TEST: %s (%d passed, %d failed)" % [
		"PASS" if failed == 0 else "FAIL", passed, failed])
	print("========================================")
	get_tree().quit(1 if failed > 0 else 0)


func _check(name_: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("  ✓ %s" % name_)
	else:
		failed += 1
		print("  ✗ %s" % name_)
