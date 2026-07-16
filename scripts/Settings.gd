extends Control
## Settings — настройки: управление, вибрация, reduce motion, звук, музыка, язык.
## Фаза 3. Всё пишется в SaveSystem и применяется мгновенно.

@onready var _control: OptionButton = $Scroll/VBox/ControlMode
@onready var _haptics: CheckButton = $Scroll/VBox/Haptics
@onready var _reduce_motion: CheckButton = $Scroll/VBox/ReduceMotion
@onready var _sound: HSlider = $Scroll/VBox/Sound
@onready var _music: HSlider = $Scroll/VBox/Music
@onready var _lang: OptionButton = $Scroll/VBox/Language
@onready var _back: Button = $Back


func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	var s: Dictionary = SaveSystem.data.settings
	_control.selected = 0 if s.control_mode == "tilt" else 1
	_haptics.button_pressed = bool(s.haptics)
	_reduce_motion.button_pressed = bool(s.reduce_motion)
	_sound.value = float(s.sound_volume)
	_music.value = float(s.music_volume)
	_lang.selected = 0 if s.language == "auto" else (1 if s.language == "en" else 2)

	_control.item_selected.connect(_on_control)
	_haptics.toggled.connect(_on_haptics)
	_reduce_motion.toggled.connect(_on_reduce_motion)
	_sound.value_changed.connect(_on_sound)
	_music.value_changed.connect(_on_music)
	_lang.item_selected.connect(_on_lang)
	_back.pressed.connect(_on_back)
	_apply_language()


func _apply_language() -> void:
	$Scroll/VBox/ControlLbl.text = tr("settings.control")
	$Scroll/VBox/Haptics.text = tr("settings.haptics")
	$Scroll/VBox/ReduceMotion.text = tr("settings.reduce_motion")
	$Scroll/VBox/SoundLbl.text = tr("settings.sound")
	$Scroll/VBox/MusicLbl.text = tr("settings.music")
	$Scroll/VBox/LangLbl.text = tr("settings.language")
	_back.text = tr("settings.back")


func _on_control(idx: int) -> void:
	var mode := "tilt" if idx == 0 else "swipe"
	SaveSystem.set_setting("control_mode", mode)
	Haptics.set_enabled(SaveSystem.data.settings.haptics)


func _on_haptics(v: bool) -> void:
	SaveSystem.set_setting("haptics", v)
	Haptics.set_enabled(v)


func _on_reduce_motion(v: bool) -> void:
	SaveSystem.set_setting("reduce_motion", v)


func _on_sound(v: float) -> void:
	SaveSystem.set_setting("sound_volume", v)
	AudioManager.set_sound_volume(v)


func _on_music(v: float) -> void:
	SaveSystem.set_setting("music_volume", v)
	AudioManager.set_music_volume(v)


func _on_lang(idx: int) -> void:
	var langs: Array = ["auto", "en", "ru"]
	var lang: String = langs[idx]
	SaveSystem.set_setting("language", lang)
	_apply_language_setting(lang)


func _apply_language_setting(lang: String) -> void:
	I18n.apply_saved_language(lang)


func _on_back() -> void:
	AudioManager.play_sfx("button")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
