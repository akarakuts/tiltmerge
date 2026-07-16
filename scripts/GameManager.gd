extends Node
## GameManager (autoload singleton)
## Стейт-машина сессии: BOOT → MENU → PLAYING → PAUSED → GAME_OVER → MENU
## Координирует переходы между сценами/состояниями, хранит текущий режим.

enum State { BOOT, MENU, PLAYING, PAUSED, GAME_OVER }

signal state_changed(new_state: int)
signal game_started(mode: String)
signal game_over(score: int, mode: String)

var state: int = State.BOOT
var current_mode: String = "classic"  # classic | blitz | zen | daily
var last_score: int = 0
var last_merges: int = 0
var last_max_tier: int = 1
var _play_start_time: int = 0


func go(s: int) -> void:
	state = s
	state_changed.emit(s)


func start_game(mode: String) -> void:
	current_mode = mode.to_lower()
	last_score = 0
	last_merges = 0
	last_max_tier = 1
	_play_start_time = Time.get_unix_time_from_system()
	go(State.PLAYING)
	game_started.emit(current_mode)
	Analytics.game_start(current_mode)


func end_game(score: int, merges: int, max_tier: int) -> void:
	last_score = score
	last_merges = merges
	last_max_tier = max_tier
	var duration: float = Time.get_unix_time_from_system() - _play_start_time
	# пишем в сохранение
	SaveSystem.record_game_result(current_mode, score, merges, max_tier)
	go(State.GAME_OVER)
	game_over.emit(score, current_mode)
	Analytics.game_over(score, current_mode, merges, max_tier, duration)


func pause_game() -> void:
	if state == State.PLAYING:
		go(State.PAUSED)


func resume_game() -> void:
	if state == State.PAUSED:
		go(State.PLAYING)


func to_menu() -> void:
	go(State.MENU)
