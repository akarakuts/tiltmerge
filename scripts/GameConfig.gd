extends Node
## GameConfig (autoload singleton)
## Загружает data/config.json и data/skins.json — единый источник истины по балансу.
## Доступ из любого скрипта: GameConfig.cfg.game.gravity.y

signal config_loaded

var cfg: Dictionary = {}
var skins: Dictionary = {}
var is_ready: bool = false

const CONFIG_PATH := "res://data/config.json"
const SKINS_PATH := "res://data/skins.json"


func _ready() -> void:
	_load_config()
	_load_skins()
	is_ready = true
	config_loaded.emit()
	print("[GameConfig] loaded: %d tiers, %d skins" % [cfg.cube.tiers.size(), skins.size()])


func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("[GameConfig] config.json not found at %s" % CONFIG_PATH)
		return
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("[GameConfig] config.json parse error")
		return
	# убираем служебные поля _comment/_version из верхнего уровня для удобства
	cfg = {}
	for key in parsed:
		if not key.begins_with("_"):
			cfg[key] = parsed[key]


func _load_skins() -> void:
	if not FileAccess.file_exists(SKINS_PATH):
		push_error("[GameConfig] skins.json not found")
		return
	var f := FileAccess.open(SKINS_PATH, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("[GameConfig] skins.json parse error")
		return
	skins = {}
	for key in parsed:
		if not key.begins_with("_"):
			skins[key] = parsed[key]


# --- Хелперы -----------------------------------------------------------------

## Радиус кубика конкретного tier
func radius_for_tier(tier: int) -> float:
	var base: float = cfg.cube.base_radius
	var mult: float = cfg.cube.size_multiplier
	return base * pow(mult, tier - 1)


## Данные tier по номеру
func tier_data(tier: int) -> Dictionary:
	for t in cfg.cube.tiers:
		if int(t.tier) == tier:
			return t
	return {}


## HEX-цвет конкретного tier из config-палитры
func color_for_tier(tier: int) -> Color:
	var hex: String = cfg.cube.palette.get(str(tier), "#FFFFFF")
	return Color.from_string(hex, Color.WHITE)


## Максимальный tier (из merge-секции)
func max_tier() -> int:
	return int(cfg.merge.max_tier)


## Текущий интервал спавна по очкам
func spawn_interval(score: int) -> float:
	var base: float = cfg.spawn.interval_base_sec
	var mn: float = cfg.spawn.interval_min_sec
	var div: int = cfg.spawn.interval_score_divisor
	return maxf(mn, base - float(score) / float(div))


## Выбрать tier для спавна по текущему score (взвешенный рандом)
func pick_spawn_tier(score: int) -> int:
	# берём последнюю применимую группу по min_score
	var group: Dictionary = cfg.spawn.score_tiers[0]
	for g in cfg.spawn.score_tiers:
		if score >= int(g.min_score):
			group = g
		else:
			break
	var tiers: Array = group.tiers
	var weights: Array = group.weights
	var total := 0
	for w in weights:
		total += int(w)
	var roll := randi() % total
	var acc := 0
	for i in range(tiers.size()):
		acc += int(weights[i])
		if roll < acc:
			return int(tiers[i])
	return int(tiers[0])
