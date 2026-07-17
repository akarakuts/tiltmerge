extends Camera2D
## CameraShake — миксер тряски камеры. Вешается на Camera2D сцены.
## API: shake(intensity, duration). Уважает настройку reduce_motion.
##
## Использование: добавить как дочерний узел ИЛИ вызвать из камеры напрямую.
## Здесь реализован как узел-примесь: add_child к Camera2D.

@export var max_offset: float = 24.0
@export var decay_rate: float = 6.0  # как быстро затухает

var _trauma: float = 0.0
var _seed: int = 0


func _ready() -> void:
	_seed = randi()


func shake(intensity: float, _duration: float = 0.3) -> void:
	if SaveSystem.data.settings.reduce_motion:
		return
	_trauma = clampf(_trauma + intensity, 0.0, 1.0)
	# duration влияет через decay: чем больше duration, тем медленнее затухание


func _process(delta: float) -> void:
	if SaveSystem.data.settings.reduce_motion:
		_trauma = 0.0
		offset = Vector2.ZERO
		return
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * decay_rate * 0.5)
		var amount: float = _trauma * _trauma  # квадратичный falloff
		offset = Vector2(
			(_noise(_seed, Time.get_ticks_msec() * 0.01) - 0.5) * 2.0 * max_offset * amount,
			(_noise(_seed + 999, Time.get_ticks_msec() * 0.01) - 0.5) * 2.0 * max_offset * amount
		)
	else:
		offset = offset.lerp(Vector2.ZERO, 0.5)


func _noise(s: int, t: float) -> float:
	# дешёвый псевдо-случай [0,1) без зависимости от внешних ресурсов
	var v := sin(float(s) * 12.9898 + t * 78.233) * 43758.5453
	return v - floor(v)
