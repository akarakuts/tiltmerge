extends Node
## Analytics (autoload singleton) — Фаза 8 (Soft Launch).
## Обёртка над Firebase Analytics + GA4. Если плагин не подключён — no-op (логирование в stdout).
## События: game_start, game_over, merge, daily_played, reroll_used, daily_completed, skin_selected.
##
## 🧑 HUMAN: подключить Firebase SDK и google-services.json (Phase 8) до soft launch.

var _enabled: bool = false
var _session_id: String = ""
var _events_buffered: int = 0


func _ready() -> void:
	# включаем аналитику только если зарегистрирован singleton плагина
	_enabled = Engine.has_singleton("FirebaseAnalytics")
	_session_id = str(Time.get_unix_time_from_system())
	if OS.is_debug_build():
		print("[Analytics] enabled=%s session=%s" % [_enabled, _session_id])


func event(name: String, params: Dictionary = {}) -> void:
	if not _enabled:
		# debug-лог для локальной разработки
		if OS.is_debug_build():
			print("[Analytics] %s %s" % [name, params])
		return
	var fa = Engine.get_singleton("FirebaseAnalytics")
	# GodotFirebase: fa.log_event(name, params)
	if fa.has_method("log_event"):
		fa.log_event(name, params)
	else:
		fa.call("log_event", name, params)


# --- Семантические события ---------------------------------------------------

func game_start(mode: String) -> void:
	event("game_start", {"mode": mode, "session": _session_id, "control": SaveSystem.data.settings.control_mode})


func game_over(score: int, mode: String, merges: int, max_tier: int, duration_sec: float) -> void:
	event("game_over", {
		"score": score, "mode": mode, "merges": merges,
		"max_tier": max_tier, "duration_sec": int(duration_sec),
		"session": _session_id
	})


func merge_event(new_tier: int, combo: int) -> void:
	event("merge", {"new_tier": new_tier, "combo": combo})


func daily_played(streak: int) -> void:
	event("daily_played", {"streak": streak})


func reroll_used(charges_left: int) -> void:
	event("reroll_used", {"charges_left": charges_left})


func daily_completed(target_tier: int, bonus: int) -> void:
	event("daily_completed", {"target_tier": target_tier, "bonus": bonus})


func skin_selected(skin_id: String) -> void:
	event("skin_selected", {"skin": skin_id})
