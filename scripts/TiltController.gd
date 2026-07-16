extends Node
## TiltController
## Управляет боковой гравитацией физического мира по наклону телефона.
##   - Первичный ввод: акселерометр (Input.get_accelerometer)
##   - Fallback: свайп/касание экрана (tilt.fallback_swipe = true в config)
##   - Дебаг: клавиши A/D, ←/→
##
## Применяет горизонтальную силу к выбранному «физическому телу-контейнеру»,
## меняя gravity.x физического мира.

var _tilt_x: float = 0.0  # нормализованный наклон [-1, 1]
var _sensitivity: float = 1.0
var _max_force: float = 1500.0
var _deadzone: float = 0.05
var _use_swipe: bool = false
var _control_mode: String = "tilt"  # tilt | swipe

var _swipe_target_x: float = 0.0  # целевая позиция касания в нормализованных координатах


func setup() -> void:
	var t: Dictionary = GameConfig.cfg.tilt
	_sensitivity = float(t.sensitivity)
	_max_force = float(t.max_force)
	_deadzone = float(t.deadzone)
	_use_swipe = bool(t.fallback_swipe)


func set_control_mode(mode: String) -> void:
	_control_mode = mode


func _physics_process(_delta: float) -> void:
	_tilt_x = _read_input()
	# применяем к глобальной гравитации физического мира
	var force: float = clampf(_tilt_x * _sensitivity, -1.0, 1.0) * _max_force
	PhysicsServer2D.area_set_param(
		get_viewport().find_world_2d().space,
		PhysicsServer2D.AREA_PARAM_GRAVITY,
		Vector2(force, GameConfig.cfg.game.gravity.y).length()
	)
	# направление гравитации: задаём через gravity_vector
	PhysicsServer2D.area_set_param(
		get_viewport().find_world_2d().space,
		PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR,
		Vector2(force, GameConfig.cfg.game.gravity.y).normalized()
	)
	# Примечание: Godot-физика берёт magnitude из AREA_PARAM_GRAVITY и направление из vector.
	# Мы хотим сохранить вертикальную 980 и добавить горизонтальную -> задаём вектор напрямую.


func _read_input() -> float:
	# 1. Клавиатура (дебаг) — приоритет для desktop-теста
	if Input.is_action_pressed("tilt_left"):
		return -1.0
	if Input.is_action_pressed("tilt_right"):
		return 1.0

	# 2. Акселерометр
	if _control_mode == "tilt":
		var accel := Input.get_accelerometer()
		if accel != Vector3.ZERO:
			# accel.x: наклон влево/вправо. Знак зависит от ориентации устройства.
			var raw: float = clampf(accel.x / 10.0, -1.0, 1.0)
			if absf(raw) > _deadzone:
				return raw

	# 3. Свайп-fallback
	if _use_swipe or _control_mode == "swipe":
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or (
			Input.get_connected_joypads().size() > 0 and Input.is_action_pressed("tilt_right")
		):
			var vp := get_viewport().get_visible_rect().size
			if vp.x > 0:
				var mx: float = get_viewport().get_mouse_position().x / vp.x
				return clampf((mx - 0.5) * 2.0, -1.0, 1.0)

	return 0.0
