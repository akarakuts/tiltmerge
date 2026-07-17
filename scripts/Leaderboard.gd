extends Control
## Leaderboard — локальные рекорды + заглушка под Google Play Services (Фаза 8).
## Фаза 4 показывает best_score по режимам из SaveSystem.

@onready var _vbox: VBoxContainer = $Scroll/VBox
@onready var _back: Button = $Back

const MODES := ["classic", "blitz", "zen", "daily"]


func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	_build()
	_back.text = tr("settings.back")
	_back.pressed.connect(_on_back)


func _build() -> void:
	for child in _vbox.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = tr("menu.leaderboard")
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(title)
	for m in MODES:
		var row := HBoxContainer.new()
		var name := Label.new()
		name.text = tr("menu." + m)
		name.add_theme_font_size_override("font_size", 30)
		name.custom_minimum_size = Vector2(300, 60)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var val := Label.new()
		val.text = str(SaveSystem.best_score(m))
		val.add_theme_font_size_override("font_size", 30)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val.custom_minimum_size = Vector2(200, 60)
		row.add_child(name)
		row.add_child(val)
		_vbox.add_child(row)
	# Явно обозначаем локальный источник данных, пока онлайн-сервис не подключён.
	var note := Label.new()
	note.text = tr("leaderboard.local_note")
	note.add_theme_font_size_override("font_size", 20)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(note)


func _on_back() -> void:
	AudioManager.play_sfx("button")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
