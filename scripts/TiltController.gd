extends Node
## TiltController
## Управляет боковой силой на кубики по наклону телефона или свайпу.
##
## Физическая модель (важно): вертикальная гравитация ОСТАЁТСЯ постоянной (980 вниз),
## а наклон применяется как дополнительная ГОРИЗОНТАЛЬНАЯ сила к каждому кубику.
## Это физически правдоподобнее, чем «наклонять весь мир», и не сбивает вертикаль.
##
## Источники ввода (по выбранному control_mode из настроек):
##   - "tilt":  акселерометр (Input.get_accelerometer) — основной для телефона
##   - "swipe": свайп/касание/мышь — для десктопа, тача и fallback
## Клавиши A/D, ←/→ работают всегда (дебаг/desktop).

signal tilt_changed(value: float)  # нормализованный наклон [-1, 1] для UI-индикатора

var _tilt_x: float = 0.0  # нормализованный наклон [-1, 1]
var _sensitivity: float = 1.0
var _max_force: float = 1500.0
var _deadzone: float = 0.05
var _control_mode: String = "tilt"  # "tilt" | "swipe" — из SaveSystem.settings
var _cubes_root: Node2D = null  # куда применять силу
var _world_space: RID = RID()
var _base_gravity_y: float = 980.0
var _smoothed: float = 0.0  # сглаженный наклон для плавности
var _smooth_speed: float = 12.0


func setup(cubes_root: Node2D = null) -> void:
	var t: Dictionary = GameConfig.cfg.tilt
	_sensitivity = float(t.sensitivity)
	_max_force = float(t.max_force)
	_deadzone = float(t.deadzone)
	_base_gravity_y = float(GameConfig.cfg.game.gravity.y)
	_cubes_root = cubes_root
	_world_space = get_viewport().find_world_2d().space


func set_control_mode(mode: String) -> void:
	_control_mode = mode


func set_cubes_root(root: Node2D) -> void:
	_cubes_root = root


func _physics_process(delta: float) -> void:
	_tilt_x = _read_input()
	# сглаживание для плавности (избегает рывков)
	_smoothed = lerp(_smoothed, _tilt_x, clampf(_smooth_speed * delta, 0.0, 1.0))

	# Гравитация вниз неизменна. Горизонтальная сила — на каждый кубик.
	if _cubes_root != null:
		var force: float = clampf(_smoothed * _sensitivity, -1.0, 1.0) * _max_force
		_apply_horizontal_force(force)

	tilt_changed.emit(_smoothed)


# Применяем боковую силу как постоянное ускорение ко всем RigidBody2D кубикам.
func _apply_horizontal_force(force: float) -> void:
	if _cubes_root == null:
		return
	for cube in _cubes_root.get_children():
		if cube is RigidBody2D and not cube.is_queued_for_deletion():
			# постоянная сила пропорциональна массе, чтобы ускорение было равным
			cube.apply_force(Vector2(force * cube.mass, 0.0), Vector2.ZERO)


func _read_input() -> float:
	# 1. Клавиатура (всегда — для desktop-теста)
	if Input.is_action_pressed("tilt_left"):
		return -1.0
	if Input.is_action_pressed("tilt_right"):
		return 1.0

	# 2. Свайп-режим (touch + mouse)
	if _control_mode == "swipe":
		return _read_swipe()

	# 3. Акселерометр-режим
	if _control_mode == "tilt":
		var accel := Input.get_accelerometer()
		if accel != Vector3.ZERO:
			var raw: float = clampf(accel.x / 10.0, -1.0, 1.0)
			if absf(raw) > _deadzone:
				return raw
		# если акселерометр не отдаёт (десктоп) — fallback на свайп
		return _read_swipe()

	return 0.0


# Свайп/касание: точка касания/мыши задаёт целевой наклон.
# Левая половина экрана = полный наклон влево, центр = 0, правая = вправо.
func _read_swipe() -> float:
	# touch (запоминается из _unhandled_input)
	if _touch_active:
		return _last_touch_tilt
	# mouse (desktop)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var vp := get_viewport().get_visible_rect().size
		if vp.x > 0:
			var mx: float = get_viewport().get_mouse_position().x / vp.x
			return clampf((mx - 0.5) * 2.0, -1.0, 1.0)
	return 0.0


var _last_touch_tilt: float = 0.0
var _touch_active: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if _control_mode != "swipe" and not (_control_mode == "tilt" and Input.get_accelerometer() == Vector3.ZERO):
		return  # в tilt-режиме на телефоне свайп не нужен
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_active = true
			_last_touch_tilt = _x_to_tilt(event.position.x)
		else:
			_touch_active = false
			_last_touch_tilt = 0.0
	elif event is InputEventScreenDrag and _touch_active:
		_last_touch_tilt = _x_to_tilt(event.position.x)
	get_viewport().set_input_as_handled()


func _x_to_tilt(x: float) -> float:
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0:
		return 0.0
	return clampf((x / vp.x - 0.5) * 2.0, -1.0, 1.0)


## Текущий нормализованный наклон (для UI-индикатора)
func current_tilt() -> float:
	return _smoothed
