extends Node
## SaveSystem (autoload singleton)
## Сохраняет прогресс в user://save.json. Структура — см. BALANCE.md §9.
## API: SaveSystem.load(), SaveSystem.save(), SaveSystem.data

signal saved()

const SAVE_PATH := "user://save.json"
const SCHEMA_VERSION := 1

var data: Dictionary = _default()


func _ready() -> void:
	load_data()


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
		"settings": {
			"control_mode": "swipe",
			"haptics": true,
			"reduce_motion": false,
			"language": "auto",
			"sound_volume": 1.0,
			"music_volume": 0.7
		},
		"daily": {"last_played": "", "streak": 0}
	}


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = _default()
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
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


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	saved.emit()


# --- Хелперы -----------------------------------------------------------------

func record_game_result(mode: String, score: int, merges: int, max_tier: int) -> void:
	data.total_games += 1
	data.total_merges += merges
	data.max_tier_reached = maxi(data.max_tier_reached, max_tier)
	var m := mode.to_lower()
	if data.best_score.has(m):
		data.best_score[m] = maxi(int(data.best_score[m]), score)
	save()


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
