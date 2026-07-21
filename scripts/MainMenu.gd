extends Control
## MainMenu — главный экран: Play, режимы, настройки, leaderboard.
## Фаза 3. Запускает онбординг при первом запуске (нет сохранённых игр).

@onready var _play: Button = $VBox/Play
@onready var _modes: VBoxContainer = $VBox/Modes
@onready var _classic: Button = $VBox/Modes/Classic
@onready var _blitz: Button = $VBox/Modes/Blitz
@onready var _zen: Button = $VBox/Modes/Zen
@onready var _daily: Button = $VBox/Modes/Daily
@onready var _settings: Button = $VBox/Settings
@onready var _skins: Button = $VBox/Skins
@onready var _leaderboard: Button = $VBox/Leaderboard
@onready var _best_label: Label = $VBox/BestLabel
@onready var _title: Label = $VBox/Title


func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	# Страховка: если попали сюда без онбординга — сразу уходим, без показа меню
	if not bool(SaveSystem.data.get("onboarding_completed", false)):
		hide()
		get_tree().change_scene_to_file("res://scenes/Onboarding.tscn")
		return
	_apply_language()
	_refresh_best()
	_play.pressed.connect(_on_play)
	_classic.pressed.connect(_start.bind("classic"))
	_blitz.pressed.connect(_start.bind("blitz"))
	_zen.pressed.connect(_start.bind("zen"))
	_daily.pressed.connect(_start.bind("daily"))
	_settings.pressed.connect(_on_settings)
	_skins.pressed.connect(_on_skins)
	_leaderboard.pressed.connect(_on_leaderboard)
	# раскрываем режимы только после нажатия Play
	_modes.hide()
	GameManager.go(GameManager.State.MENU)
	AudioManager.play_music("music_menu")


func _apply_language() -> void:
	I18n.apply_saved_language(str(SaveSystem.data.settings.get("language", "auto")))
	_title.text = tr("app.title")
	_play.text = tr("menu.play")
	_classic.text = tr("menu.classic")
	_blitz.text = tr("menu.blitz")
	_zen.text = tr("menu.zen")
	_daily.text = tr("menu.daily")
	_settings.text = tr("menu.settings")
	_skins.text = tr("menu.skins")
	_leaderboard.text = tr("menu.leaderboard")


func _refresh_best() -> void:
	_best_label.text = "%s: %d" % [tr("game.best"), SaveSystem.best_score("classic")]


func _on_play() -> void:
	AudioManager.play_sfx("button")
	_play.hide()
	_modes.show()


func _start(mode: String) -> void:
	AudioManager.play_sfx("button")
	GameManager.start_game(mode)
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_settings() -> void:
	AudioManager.play_sfx("button")
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_skins() -> void:
	AudioManager.play_sfx("button")
	get_tree().change_scene_to_file("res://scenes/Skins.tscn")


func _on_leaderboard() -> void:
	AudioManager.play_sfx("button")
	get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")


func handle_android_back() -> void:
	# Сначала свернуть выбор режима, иначе выход из приложения.
	if _modes.visible:
		_modes.hide()
		_play.show()
		return
	get_tree().quit()
