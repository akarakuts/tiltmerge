extends Node
## Achievements (autoload singleton)
## Проверяет условия достижений по событиям игры и разблокирует через SaveSystem.
## Условия описаны в config.json -> achievements. Здесь — обработчики триггеров.

signal unlocked(id: String, name: String)

# кэш: id -> {name, condition, ...}
var _defs: Dictionary = {}
var _unlock_queue: Array = []


func _ready() -> void:
	if not GameConfig.ready:
		await GameConfig.config_loaded
	for a in GameConfig.cfg.achievements:
		_defs[str(a.id)] = a


# Вызывается после каждой игры с итоговой статистикой забега
func evaluate_run(stats: Dictionary) -> void:
	# stats: {score, max_tier, combo, merges, revives, games, score_swipe}
	var ctx := {
		"score": int(stats.get("score", 0)),
		"max_tier": int(stats.get("max_tier", 1)),
		"combo": int(stats.get("combo", 0)),
		"merges": int(stats.get("merges", 0)),
		"revives": int(stats.get("revives", 0)),
		"games": int(SaveSystem.data.total_games),
		"score_swipe": int(stats.get("score_swipe", 0))
	}
	for id in _defs:
		if SaveSystem.data.achievements.has(id):
			continue
		var def: Dictionary = _defs[id]
		if _check(str(def.condition), ctx):
			var name: String = str(def.name)
			if SaveSystem.unlock_achievement(id):
				unlocked.emit(id, name)


# Простейший парсер условий вида "key >= value" или "key >= value AND ..."
func _check(expr: String, ctx: Dictionary) -> bool:
	var parts := expr.split(" AND ")
	for p in parts:
		if not _check_single(p.strip_edges(), ctx):
			return false
	return true


func _check_single(expr: String, ctx: Dictionary) -> bool:
	for op in [">=", "<=", ">", "<", "=="]:
		var idx := expr.find(op)
		if idx != -1:
			var key := expr.substr(0, idx).strip_edges()
			var val_str := expr.substr(idx + op.length()).strip_edges()
			var lhs: float = float(ctx.get(key, 0))
			var rhs: float = float(val_str)
			match op:
				">=": return lhs >= rhs
				"<=": return lhs <= rhs
				">":  return lhs > rhs
				"<":  return lhs < rhs
				"==": return lhs == rhs
	return false
