extends Node
## AudioManager (autoload singleton)
## Управляет музыкой и SFX. Звуковые файлы кладёт художник в assets/audio/.
## API: AudioManager.play_music("menu"), .play_sfx("merge")
## Если файл не найден — тихо пропускаем (MVP без ассетов).

var _music: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
const SFX_POOL_SIZE := 6

var _sounds: Dictionary = {}  # name -> AudioStream
var _sound_volume: float = 1.0
var _music_volume: float = 0.7
var _audio_enabled: bool = true

const AUDIO_DIR := "res://assets/audio/"


func _ready() -> void:
	_audio_enabled = DisplayServer.get_name() != "headless"
	if not _audio_enabled:
		return
	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	add_child(_music)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)
	_preload()


func _exit_tree() -> void:
	release_resources()


func release_resources() -> void:
	# Explicitly release active playback before the audio server shuts down. This
	# also keeps headless tests free of orphan AudioStreamPlayback instances.
	if _music != null:
		_music.stop()
		_music.stream = null
	for player in _sfx_pool:
		player.stop()
		player.stream = null
	_sfx_pool.clear()
	_sounds.clear()


func _preload() -> void:
	# ожидаемые файлы (могут отсутствовать на раннем этапе):
	var names: Array = ["merge", "spawn", "combo", "game_over", "button", "music_menu", "music_game"]
	for n in names:
		var path: String = AUDIO_DIR + String(n) + ".wav"
		if ResourceLoader.exists(path):
			_sounds[n] = load(path)
		else:
			var ogg: String = AUDIO_DIR + String(n) + ".ogg"
			if ResourceLoader.exists(ogg):
				_sounds[n] = load(ogg)


func set_music_volume(v: float) -> void:
	_music_volume = clampf(v, 0.0, 1.0)
	if _music != null and _music.playing:
		_music.volume_db = linear_to_db(_music_volume)


func set_sound_volume(v: float) -> void:
	_sound_volume = clampf(v, 0.0, 1.0)


func play_music(name: String) -> void:
	if not _audio_enabled or _music == null:
		return
	if _music.playing and _music.stream == _sounds.get(name):
		return
	var s = _sounds.get(name)
	if s == null:
		_music.stop()
		return
	_music.stream = s
	_music.volume_db = linear_to_db(_music_volume)
	_music.play()


func stop_music() -> void:
	if _music != null:
		_music.stop()


func play_sfx(name: String, pitch: float = 1.0) -> void:
	if not _audio_enabled or _sound_volume <= 0.0:
		return
	var s = _sounds.get(name)
	if s == null:
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = linear_to_db(_sound_volume)
	p.play()
