extends Node
## SaveSystem (autoload singleton)
## Сохраняет прогресс в user://save.json. Структура — см. BALANCE.md §9.
## API: SaveSystem.load(), SaveSystem.save(), SaveSystem.data

signal saved()

const SAVE_PATH := "user://save.json"
const SCHEMA_VERSION := 1

var data: Dictionary = _default()
var _save_path: String = SAVE_PATH
var _cleanup_save_on_exit: bool = false


func _ready() -> void:
	_configure_save_path()
	load_data()
	_ensure_install_id()


func _exit_tree() -> void:
	if _cleanup_save_on_exit and _save_path.begins_with("user://tiltmerge-test-"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path))


func _configure_save_path() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-path="):
			var requested_path := argument.trim_prefix("--save-path=")
			if requested_path.begins_with("user://"):
				_save_path = requested_path
			else:
				push_warning("[SaveSystem] ignoring non-user save path")
		elif argument == "--cleanup-save":
			_cleanup_save_on_exit = true


func _default() -> Dictionary:
	return {
		"version": SCHEMA_VERSION,
		"best_score": {"classic": 0, "blitz": 0, "zen": 0, "daily": 0},
		"total_games": 0,
		"total_merges": 0,
		"max_tier_reached": 1,
		"achievements": [],
		"unlocked_skins": ["default"],
		"selected_skin": "default",
		"onboarding_completed": false,
		"install_id": "",
		"settings": {
			"control_mode": "tilt",
			"haptics": true,
			"reduce_motion": false,
			"language": "auto",
			"sound_volume": 1.0,
			"music_volume": 0.7
		},
		"daily": {"last_played": "", "streak": 0, "completed_date": ""}
	}


func load_data() -> void:
	if not FileAccess.file_exists(_save_path):
		data = _default()
		return
	var f := FileAccess.open(_save_path, FileAccess.READ)
	if f == null:
		push_warning("[SaveSystem] could not open save, using defaults")
		data = _default()
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[SaveSystem] corrupted save, using defaults")
		data = _default()
		return
	data = _merge_defaults(parsed, _default())


# рекурсивно дополняем сохранение недостающими полями схемы (миграции)
func _merge_defaults(loaded: Dictionary, defaults: Dictionary) -> Dictionary:
	var out := defaults.duplicate(true)
	for key in loaded:
		if typeof(loaded[key]) == TYPE_DICTIONARY and typeof(defaults.get(key)) == TYPE_DICTIONARY:
			out[key] = _merge_defaults(loaded[key], defaults[key])
		else:
			out[key] = loaded[key]
	return out


func save() -> bool:
	# Запись во временный файл предотвращает повреждение основного save при закрытии
	# приложения в середине операции.
	var temporary_path := "%s.tmp" % _save_path
	var f := FileAccess.open(temporary_path, FileAccess.WRITE)
	if f == null:
		push_error("[SaveSystem] could not open temporary save for writing")
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.flush()
	f.close()
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(_save_path))
	if err != OK:
		push_error("[SaveSystem] could not replace save (error %d)" % err)
		return false
	saved.emit()
	return true


func _ensure_install_id() -> void:
	if not str(data.get("install_id", "")).is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	data.install_id = "tm-%x-%x" % [Time.get_unix_time_from_system(), rng.randi()]
	save()


# --- Хелперы -----------------------------------------------------------------

func record_game_result(mode: String, score: int, merges: int, max_tier: int) -> void:
	data.total_games += 1
	data.total_merges += merges
	data.max_tier_reached = maxi(data.max_tier_reached, max_tier)
	var m := mode.to_lower()
	if data.best_score.has(m):
		data.best_score[m] = maxi(int(data.best_score[m]), score)
	save()


func complete_onboarding() -> void:
	if not bool(data.get("onboarding_completed", false)):
		data.onboarding_completed = true
		save()


func record_daily_play(date_key: String) -> int:
	var daily: Dictionary = data.daily
	if str(daily.get("last_played", "")) == date_key:
		return int(daily.get("streak", 0))
	var yesterday := Time.get_date_dict_from_unix_time(Time.get_unix_time_from_system() - 86400.0)
	var yesterday_key := "%04d-%02d-%02d" % [yesterday.year, yesterday.month, yesterday.day]
	daily.streak = int(daily.get("streak", 0)) + 1 if str(daily.get("last_played", "")) == yesterday_key else 1
	daily.last_played = date_key
	data.daily = daily
	save()
	return int(daily.streak)


func complete_daily_challenge(date_key: String) -> bool:
	var daily: Dictionary = data.daily
	if str(daily.get("completed_date", "")) == date_key:
		return false
	daily.completed_date = date_key
	data.daily = daily
	save()
	return true


func best_score(mode: String) -> int:
	return int(data.best_score.get(mode.to_lower(), 0))


func unlock_skin(skin_id: String) -> void:
	if not data.unlocked_skins.has(skin_id):
		data.unlocked_skins.append(skin_id)
		save()


func select_skin(skin_id: String) -> void:
	if data.unlocked_skins.has(skin_id):
		data.selected_skin = skin_id
		save()


func unlock_achievement(id: String) -> bool:
	if not data.achievements.has(id):
		data.achievements.append(id)
		save()
		return true
	return false


func set_setting(key: String, value) -> void:
	data.settings[key] = value
	save()
