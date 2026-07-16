extends Node2D
## Onboarding — интерактивный тутор (Фаза 3, переработан).
## 3 шага, каждый требует от игрока РЕАЛЬНО выполнить действие:
##   1. Наклони → сдвинь кубик к целевой зоне
##   2. Слей два одинаковых кубика (столкни их)
##   3. Правило game over + кнопка «Поехали»
## Переиспользует настоящие компоненты игры: Cube, TiltController, MergeLogic.
##
## Запуск: автоматически при первом запуске (total_games == 0), либо из меню.

const CubeScenePath := "res://scenes/Cube.tscn"

@onready var _cubes: Node2D = $Arena/Cubes
@onready var _tilt: Node = $TiltController
@onready var _merge: Node = $MergeLogic
@onready var _title: Label = $UI/Title
@onready var _hint: Label = $UI/Hint
@onready var _progress: Label = $UI/Progress
@onready var _next_btn: Button = $UI/NextButton
@onready var _goal: Node2D = $Arena/Goal
@onready var _goal_area: Area2D = $Arena/GoalArea
@onready var _arrow: Sprite2D = $Arena/Arrow

var _step: int = 0
var _step_done: bool = false
var _step_cube: Cube = null
var _step_cube2: Cube = null
var _goal_reached: bool = false
var _merge_happened: bool = false

const STEP_COUNT := 3


func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	_tilt.setup(_cubes)
	# онбординг всегда свайп-управление для предсказуемости (наклон ещё не пробовали)
	_tilt.set_control_mode("swipe")
	_merge.setup(_cubes)
	_merge.reset()
	MergeBus.merge_completed.connect(_on_merge_completed)
	_goal_area.body_entered.connect(_on_goal_body_entered)
	_goal_area.body_exited.connect(_on_goal_body_exited)

	_next_btn.pressed.connect(_on_next)
	_next_btn.hide()
	_arrow.hide()
	_goal.hide()
	_start_step(0)


# --- Шаги --------------------------------------------------------------------

func _start_step(idx: int) -> void:
	_step = idx
	_step_done = false
	# чистим арену
	for c in _cubes.get_children():
		c.queue_free()
	_step_cube = null
	_step_cube2 = null
	_goal_reached = false
	_merge_happened = false

	_update_progress()
	_next_btn.hide()
	_goal.hide()
	_arrow.hide()

	match idx:
		0: _step_one_tilt()
		1: _step_two_merge()
		2: _step_three_rule()


# Шаг 1: один кубик, доведи до цели (наклоном/свайпом)
func _step_one_tilt() -> void:
	_title.text = tr("onboarding.title")
	_hint.text = tr("ob.hint1")  # "Наклони телефон / веди пальцем, чтобы катить кубик к мишени"
	_goal.show()
	_goal.position = Vector2(560, 1050)
	_step_cube = _spawn_cube(1, Vector2(160, 600))
	_show_arrow_hint()


# Шаг 2: два одинаковых кубика, слей их
func _step_two_merge() -> void:
	_hint.text = tr("ob.hint2")  # "Столкни два одинаковых кубика — они сольются!"
	_step_cube = _spawn_cube(1, Vector2(180, 700))
	_step_cube2 = _spawn_cube(1, Vector2(540, 700))
	# лёгкая встречная скорость, чтобы при наклоне столкнулись
	_step_cube.linear_velocity = Vector2(40, 0)


# Шаг 3: правило game over + кнопка
func _step_three_rule() -> void:
	_hint.text = tr("ob.hint3")  # "Не дай кубикам достичь верхней линии — иначе game over!"
	# спавним несколько кубиков для визуального намёка
	for i in 3:
		_spawn_cube(1, Vector2(180 + i * 180, 900))
	_step_done = true  # этот шаг не требует действия, только кнопку
	_next_btn.text = tr("ob.lets_go")
	_next_btn.show()


func _spawn_cube(tier: int, pos: Vector2) -> Cube:
	var cube = load(CubeScenePath).instantiate()
	_cubes.add_child(cube)
	cube.global_position = pos
	cube.setup(tier)
	return cube


# --- Проверка выполнения шага ------------------------------------------------

func _physics_process(_delta: float) -> void:
	if _step_done:
		return
	match _step:
		0:
			if _goal_reached:
				_complete_step()
		1:
			if _merge_happened:
				_complete_step()


func _complete_step() -> void:
	_step_done = true
	_hint.text = tr("ob.done")  # "Отлично!"
	_next_btn.text = tr("ob.next")
	_next_btn.show()
	AudioManager.play_sfx("button")
	Haptics.medium()
	_arrow.hide()


func _on_next() -> void:
	AudioManager.play_sfx("button")
	if _step < STEP_COUNT - 1:
		_start_step(_step + 1)
	else:
		# финал → в меню
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


# --- События арены -----------------------------------------------------------

func _on_goal_body_entered(body: Node) -> void:
	if body is Cube:
		_goal_reached = true


func _on_goal_body_exited(body: Node) -> void:
	if body is Cube:
		_goal_reached = false


func _on_merge_completed(_new_cube: Node, _old_tier: int, _new_tier: int, _pos: Vector2) -> void:
	_merge_happened = true


# --- UI-подсказки ------------------------------------------------------------

func _update_progress() -> void:
	var dots: Array = []
	for i in range(STEP_COUNT):
		dots.append("●" if i == _step else "○")
	_progress.text = "  ".join(dots)


func _show_arrow_hint() -> void:
	# стрелка-указатель к цели (пульсирующая)
	_arrow.show()
	_arrow.position = Vector2(560, 980)
	var tw := create_tween().set_loops()
	tw.tween_property(_arrow, "position:y", 1000.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_arrow, "position:y", 980.0, 0.5).set_trans(Tween.TRANS_SINE)
