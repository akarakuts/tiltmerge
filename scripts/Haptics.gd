extends Node
## Haptics (autoload singleton)
## Обёртка над вибрацией Android.
## На desktop — no-op (тихо). На Android — использует GodotHaptics plugin если доступен,
## иначе fallback на короткий Input.vibrate_handheld (доступен на Android).
## Уважает настройку SaveSystem.data.settings.haptics.

var _enabled: bool = true


func _ready() -> void:
	_enabled = bool(SaveSystem.data.settings.get("haptics", true))


func set_enabled(v: bool) -> void:
	_enabled = v


func light() -> void:
	_vibrate(15)


func medium() -> void:
	_vibrate(35)


func heavy() -> void:
	_vibrate(80)


func custom(ms: int) -> void:
	_vibrate(maxi(1, ms))


func _vibrate(ms: int) -> void:
	if not _enabled:
		return
	# Плагин (Фаза 6) — если зарегистрирован singleton
	if Engine.has_singleton("GodotHaptics"):
		Engine.get_singleton("GodotHaptics").vibrate(ms)
		return
	# Fallback: встроенный handheld (работает только на Android, на desktop — no-op)
	if OS.has_feature("android"):
		Input.vibrate_handheld(ms)
