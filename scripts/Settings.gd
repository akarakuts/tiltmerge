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

# Слайдеры громкости стреляют value_changed десятки раз в секунду при перетаскивании.
# Чтобы не делать десятки save() в секунду, откладываем запись на 0.3с после
# последнего движения; громкость применяем мгновенно.
var _pending_sound: float = -1.0
var _pending_music: float = -1.0
var _save_timer: float = 0.0
const _SAVE_DEBOUNCE_SEC := 0.3
# Список опций Language: "auto" + все загруженные локали. Строится в _ready.
var _locales: Array = ["auto"]


func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	var s: Dictionary = SaveSystem.data.settings
	_control.selected = 0 if s.control_mode == "tilt" else 1
	_haptics.button_pressed = bool(s.haptics)
	_reduce_motion.button_pressed = bool(s.reduce_motion)
	_sound.value = float(s.sound_volume)
	_music.value = float(s.music_volume)
	_build_language_options(str(s.language))

	_control.item_selected.connect(_on_control)
	_haptics.toggled.connect(_on_haptics)
	_reduce_motion.toggled.connect(_on_reduce_motion)
	_sound.value_changed.connect(_on_sound)
	_music.value_changed.connect(_on_music)
	_lang.item_selected.connect(_on_lang)
	_back.pressed.connect(_on_back)
	_apply_language()


func _apply_language() -> void:
	$Title.text = tr("settings.title")
	$Scroll/VBox/ControlLbl.text = tr("settings.control")
	$Scroll/VBox/Haptics.text = tr("settings.haptics")
	$Scroll/VBox/ReduceMotion.text = tr("settings.reduce_motion")
	$Scroll/VBox/SoundLbl.text = tr("settings.sound")
	$Scroll/VBox/MusicLbl.text = tr("settings.music")
	$Scroll/VBox/LangLbl.text = tr("settings.language")
	_back.text = tr("settings.back")
	# Подписи режимов управления тоже локализуем.
	var sel := _control.selected
	_control.clear()
	_control.add_item(tr("settings.control.tilt"))
	_control.add_item(tr("settings.control.swipe"))
	_control.selected = clampi(sel, 0, 1)
	if _lang.item_count > 0:
		_lang.set_item_text(0, tr("settings.language_auto"))


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
	_pending_sound = v
	AudioManager.set_sound_volume(v)
	_schedule_save()


func _on_music(v: float) -> void:
	_pending_music = v
	AudioManager.set_music_volume(v)
	_schedule_save()


func _schedule_save() -> void:
	_save_timer = _SAVE_DEBOUNCE_SEC


func _process(_delta: float) -> void:
	if _save_timer > 0.0:
		_save_timer -= _delta
		if _save_timer <= 0.0:
			_flush_pending_settings()


func _flush_pending_settings() -> void:
	_save_timer = 0.0
	if _pending_sound >= 0.0:
		SaveSystem.set_setting("sound_volume", _pending_sound)
		_pending_sound = -1.0
	if _pending_music >= 0.0:
		SaveSystem.set_setting("music_volume", _pending_music)
		_pending_music = -1.0


func _on_lang(idx: int) -> void:
	var lang: String = _locales[mini(idx, _locales.size() - 1)]
	SaveSystem.set_setting("language", lang)
	_apply_language_setting(lang)
	# перерисовать подписи настроек на новом языке немедленно
	_apply_language()


func _apply_language_setting(lang: String) -> void:
	I18n.apply_saved_language(lang)


## Заполняет OptionButton языка: «Авто» + все доступные переводы.
## Отображаемое имя — нативное имя локали из TranslationServer
## (например "Deutsch", "中文 (简体)"), чтобы игрок видел названия на родном языке.
func _build_language_options(current: String) -> void:
	_lang.clear()
	_lang.add_item(tr("settings.language_auto"))
	var loaded := TranslationServer.get_loaded_locales()
	loaded.sort()
	_locales = ["auto"]
	var selected := 0
	for i in range(loaded.size()):
		var loc: String = str(loaded[i])
		_lang.add_item("%s — %s" % [TranslationServer.get_locale_name(loc), loc])
		_locales.append(loc)
		if loc == current:
			selected = i + 1
	_lang.selected = selected


func _on_back() -> void:
	_flush_pending_settings()
	AudioManager.play_sfx("button")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func handle_android_back() -> void:
	_on_back()
