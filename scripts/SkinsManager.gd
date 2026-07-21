extends Node
## SkinsManager (autoload singleton)
## Управляет косметическими скинами: разблокировка, выбор, применение палитры.
## Палитра скина переопределяет config.json cube.palette для текущей игры.

var _active_palette: Dictionary = {}


func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	_apply_selected()


func _apply_selected() -> void:
	var skin_id: String = SaveSystem.data.selected_skin
	var skin: Dictionary = GameConfig.skins.get(skin_id, {})
	_active_palette = skin.get("palette", GameConfig.cfg.cube.palette)


## Текущий HEX-цвет tier с учётом выбранного скина
func color_for_tier(tier: int) -> Color:
	var hex: String = _active_palette.get(str(tier), "#FFFFFF")
	return Color.from_string(hex, Color.WHITE)


## Список скинов с состоянием разблокировки (для экрана скинов)
func list() -> Array:
	var out: Array = []
	for skin_id in GameConfig.skins:
		var s: Dictionary = GameConfig.skins[skin_id]
		var unlocked: bool = _is_unlocked(skin_id, s)
		out.append({
			"id": skin_id,
			"name": str(s.get("name", skin_id)),
			"unlocked": unlocked,
			"selected": skin_id == SaveSystem.data.selected_skin,
			"unlock_cost_score": int(s.get("unlock_cost_score", 0)),
			"unlock_condition": str(s.get("unlock_condition", "default"))
		})
	return out


func _is_unlocked(skin_id: String, skin: Dictionary) -> bool:
	if SaveSystem.data.unlocked_skins.has(skin_id):
		return true
	match str(skin.get("unlock_condition", "default")):
		"default":
			return true
		"score":
			# разблокируется по сумме best_score всех режимов
			var total := 0
			for m in SaveSystem.data.best_score.values():
				total += int(m)
			return total >= int(skin.get("unlock_cost_score", 0))
		"achievement":
			var req: String = str(skin.get("unlock_required_achievement", ""))
			return req != "" and SaveSystem.data.achievements.has(req)
	return false


func try_unlock(skin_id: String) -> bool:
	var skin: Dictionary = GameConfig.skins.get(skin_id, {})
	if skin.is_empty():
		return false
	if _is_unlocked(skin_id, skin):
		SaveSystem.unlock_skin(skin_id)
		return true
	return false


func select(skin_id: String) -> bool:
	var skin: Dictionary = GameConfig.skins.get(skin_id, {})
	if skin.is_empty() or not _is_unlocked(skin_id, skin):
		return false
	# Скины за счёт/достижение становятся доступны автоматически. Перед
	# выбором сохраняем факт разблокировки, иначе интерфейс показывает
	# «Выбрать», но SaveSystem отклоняет нажатие.
	SaveSystem.unlock_skin(skin_id)
	SaveSystem.select_skin(skin_id)
	_apply_selected()
	Analytics.skin_selected(skin_id)
	return true


func purchase_with_score(skin_id: String) -> bool:
	# Для score-скинов: разблокировка происходит автоматически при достижении суммы.
	var skin: Dictionary = GameConfig.skins.get(skin_id, {})
	if str(skin.get("unlock_condition")) != "score":
		return false
	if _is_unlocked(skin_id, skin):
		SaveSystem.unlock_skin(skin_id)
		return true
	return false
