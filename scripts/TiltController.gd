extends Node
## TiltController
## Управляет боковой силой на кубики по наклону телефона или свайпу.
##
## Физическая модель (важно): вертикальная гравитация ОСТАЁТСЯ постоянной (980 вниз),
## а наклон применяется как дополнительная ГОРИЗОНТАЛЬНАЯ сила к каждому кубику.
## Это физически правдоподобнее, чем «наклонять весь мир», и не сбивает вертикаль.
##
## Источники ввода (по выбранному control_mode из настроек):
##   - "tilt":  акселерометр/гравитация + свайп как запасной канал (важно для онбординга)
##   - "swipe": только свайп/касание/мышь
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
var _allow_swipe_in_tilt: bool = true  # tilt + палец одновременно


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


func set_allow_swipe_in_tilt(enabled: bool) -> void:
	_allow_swipe_in_tilt = enabled


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
			# Godot переводит неподвижный RigidBody2D в сон. В нижнем углу это
			# особенно заметно: без явного пробуждения следующий наклон может
			# не начать физическую симуляцию, и кубик становится недоступным.
			if absf(force) > 0.001 and cube.sleeping:
				cube.sleeping = false
			# постоянная сила пропорциональна массе, чтобы ускорение было равным
			cube.apply_force(Vector2(force * cube.mass, 0.0), Vector2.ZERO)


func _read_input() -> float:
	var result := 0.0
	# 1. Клавиатура (всегда — для desktop-теста)
	if Input.is_action_pressed("tilt_left"):
		result = -1.0
	elif Input.is_action_pressed("tilt_right"):
		result = 1.0
	elif _control_mode == "swipe":
		result = _read_swipe()
	elif _control_mode == "tilt":
		# Свайп имеет приоритет, пока палец на экране — иначе сенсор.
		if _allow_swipe_in_tilt:
			var swipe := _read_swipe()
			if _touch_active or absf(swipe) > _deadzone:
				result = swipe
			else:
				var sensor := _read_sensor_tilt()
				result = sensor if absf(sensor) > _deadzone else swipe
		else:
			result = _read_sensor_tilt()
	return result


func _read_sensor_tilt() -> float:
	# get_gravity стабильнее для «наклона», accelerometer — запасной канал.
	var g := Input.get_gravity()
	if g != Vector3.ZERO:
		# У телефона перед собой: X — влево/вправо. Делим на ~g.
		return clampf(g.x / 9.8, -1.0, 1.0)
	var accel := Input.get_accelerometer()
	if accel != Vector3.ZERO:
		return clampf(accel.x / 9.8, -1.0, 1.0)
	return 0.0


# Свайп/касание: точка касания/мыши задаёт целевой наклон.
# Левая половина экрана = полный наклон влево, центр = 0, правая = вправо.
func _read_swipe() -> float:
	# touch (запоминается из _input)
	if _touch_active:
		return _last_touch_tilt
	# mouse (desktop / emulate_mouse_from_touch)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var vp := get_viewport().get_visible_rect().size
		if vp.x > 0:
			var mx: float = get_viewport().get_mouse_position().x / vp.x
			return clampf((mx - 0.5) * 2.0, -1.0, 1.0)
	return 0.0


var _last_touch_tilt: float = 0.0
var _touch_active: bool = false


func _input(event: InputEvent) -> void:
	# Берём touch до UI, иначе подписи/плашки могут съесть unhandled.
	if _control_mode == "swipe" or (_control_mode == "tilt" and _allow_swipe_in_tilt):
		_handle_touch_event(event)


func _handle_touch_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_active = true
			_last_touch_tilt = _x_to_tilt(event.position.x)
		else:
			_touch_active = false
			_last_touch_tilt = 0.0
	elif event is InputEventScreenDrag and _touch_active:
		_last_touch_tilt = _x_to_tilt(event.position.x)


func _x_to_tilt(x: float) -> float:
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0:
		return 0.0
	return clampf((x / vp.x - 0.5) * 2.0, -1.0, 1.0)


## Текущий нормализованный наклон (для UI-индикатора)
func current_tilt() -> float:
	return _smoothed
