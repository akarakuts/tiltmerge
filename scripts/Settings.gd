extends Control
## Settings — управление, вибрация, reduce motion, громкость.
## Язык всегда берётся из ОС (auto), ручного выбора нет.

@onready var _tilt_btn: Button = $Body/ControlRow/TiltBtn
@onready var _swipe_btn: Button = $Body/ControlRow/SwipeBtn
@onready var _haptics: CheckButton = $Body/Haptics
@onready var _reduce_motion: CheckButton = $Body/ReduceMotion
@onready var _sound: HSlider = $Body/Sound
@onready var _music: HSlider = $Body/Music
@onready var _sound_value: Label = $Body/SoundHeader/SoundValue
@onready var _music_value: Label = $Body/MusicHeader/MusicValue
@onready var _back: Button = $Back

var _pending_sound: float = -1.0
var _pending_music: float = -1.0
var _save_timer: float = 0.0
const _SAVE_DEBOUNCE_SEC := 0.3


func _ready() -> void:
	UiTheme.apply(self)
	UiTheme.make_bg(self)
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	if str(SaveSystem.data.settings.get("language", "auto")) != "auto":
		SaveSystem.set_setting("language", "auto")
	I18n.apply_saved_language("auto")

	var s: Dictionary = SaveSystem.data.settings
	var is_tilt: bool = str(s.control_mode) != "swipe"
	_tilt_btn.button_pressed = is_tilt
	_swipe_btn.button_pressed = not is_tilt
	_haptics.button_pressed = bool(s.haptics)
	_reduce_motion.button_pressed = bool(s.reduce_motion)
	_sound.value = float(s.sound_volume)
	_music.value = float(s.music_volume)
	_refresh_volume_labels()
	_sync_control_styles()

	_tilt_btn.pressed.connect(_on_tilt_pressed)
	_swipe_btn.pressed.connect(_on_swipe_pressed)
	_haptics.toggled.connect(_on_haptics)
	_reduce_motion.toggled.connect(_on_reduce_motion)
	_sound.value_changed.connect(_on_sound)
	_music.value_changed.connect(_on_music)
	_back.pressed.connect(_on_back)
	_apply_language()


func _apply_language() -> void:
	$Title.text = tr("settings.title")
	$Title.add_theme_color_override("font_color", UiTheme.COL_TEXT)
	$Body/ControlLbl.text = tr("settings.control")
	$Body/ControlLbl.add_theme_color_override("font_color", UiTheme.COL_MUTED)
	_tilt_btn.text = tr("settings.control.tilt")
	_swipe_btn.text = tr("settings.control.swipe")
	_haptics.text = tr("settings.haptics")
	_reduce_motion.text = tr("settings.reduce_motion")
	$Body/SoundHeader/SoundLbl.text = tr("settings.sound")
	$Body/MusicHeader/MusicLbl.text = tr("settings.music")
	$Body/SoundHeader/SoundLbl.add_theme_color_override("font_color", UiTheme.COL_MUTED)
	$Body/MusicHeader/MusicLbl.add_theme_color_override("font_color", UiTheme.COL_MUTED)
	_sound_value.add_theme_color_override("font_color", UiTheme.COL_ACCENT)
	_music_value.add_theme_color_override("font_color", UiTheme.COL_ACCENT)
	_back.text = tr("settings.back")


func _on_tilt_pressed() -> void:
	_set_control_mode("tilt")


func _on_swipe_pressed() -> void:
	_set_control_mode("swipe")


func _set_control_mode(mode: String) -> void:
	SaveSystem.set_setting("control_mode", mode)
	_sync_control_styles()
	AudioManager.play_sfx("button")
	Haptics.light()


func _sync_control_styles() -> void:
	var tilt_on := _tilt_btn.button_pressed
	_tilt_btn.theme_type_variation = &"PrimaryButton" if tilt_on else &"GhostButton"
	_swipe_btn.theme_type_variation = &"PrimaryButton" if not tilt_on else &"GhostButton"


func _on_haptics(v: bool) -> void:
	SaveSystem.set_setting("haptics", v)
	Haptics.set_enabled(v)
	if v:
		Haptics.light()


func _on_reduce_motion(v: bool) -> void:
	SaveSystem.set_setting("reduce_motion", v)


func _on_sound(v: float) -> void:
	_pending_sound = v
	AudioManager.set_sound_volume(v)
	_refresh_volume_labels()
	_schedule_save()


func _on_music(v: float) -> void:
	_pending_music = v
	AudioManager.set_music_volume(v)
	_refresh_volume_labels()
	_schedule_save()


func _refresh_volume_labels() -> void:
	_sound_value.text = "%d%%" % int(round(_sound.value * 100.0))
	_music_value.text = "%d%%" % int(round(_music.value * 100.0))


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


func _on_back() -> void:
	_flush_pending_settings()
	AudioManager.play_sfx("button")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func handle_android_back() -> void:
	_on_back()
