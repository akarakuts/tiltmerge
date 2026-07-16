extends Node
## ABTest (autoload singleton) — Фаза 8.
## Управляет A/B-флагами для soft launch. Флаги хранятся в SaveSystem.data.ab_flags,
## назначаются детерминированно по хэшу session_id, чтобы пользователь не "прыгал".
##
## Пример: ABTest.get("spawn_speed") -> "fast" | "normal"
## 🧑 HUMAN: настроить флаги и cohort-размеры в data/ab_config.json перед soft launch.

const AB_PATH := "res://data/ab_config.json"
var _flags: Dictionary = {}  # flag_name -> assigned variant
var _config: Dictionary = {}


func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	_load_config()
	_assign_all()


func _load_config() -> void:
	if not FileAccess.file_exists(AB_PATH):
		_config = {}
		return
	var f := FileAccess.open(AB_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed != null:
		_config = parsed


func _assign_all() -> void:
	if not SaveSystem.data.has("ab_flags"):
		SaveSystem.data.ab_flags = {}
	for flag in _config.get("flags", {}):
		var f: Dictionary = _config.flags[flag]
		if SaveSystem.data.ab_flags.has(flag):
			_flags[flag] = SaveSystem.data.ab_flags[flag]
		else:
			_flags[flag] = _pick_variant(flag, f.get("variants", []), float(f.get("salt", 0.0)))
			SaveSystem.data.ab_flags[flag] = _flags[flag]
	SaveSystem.save()


# детерминированный выбор варианта по хэшу ID устройства/сессии
func _pick_variant(flag: String, variants: Array, salt: float) -> String:
	if variants.is_empty():
		return ""
	var h: int = absi(hash(str(salt) + flag + str(SaveSystem.data.get("install_id", ""))))
	var roll: int = h % 100
	var acc: float = 0.0
	for v in variants:
		acc += float(v.get("weight", 0.0))
		if roll < acc:
			return str(v.get("value", ""))
	return str(variants[0].get("value", ""))


func get_flag(flag: String) -> String:
	return _flags.get(flag, "")


func is_variant(flag: String, value: String) -> bool:
	return _flags.get(flag, "") == value
