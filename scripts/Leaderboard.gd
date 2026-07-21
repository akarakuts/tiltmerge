extends Control
## Leaderboard — локальные рекорды по режимам.

@onready var _vbox: VBoxContainer = $Scroll/VBox
@onready var _back: Button = $Back

const MODES := ["classic", "blitz", "zen", "daily"]


func _ready() -> void:
	UiTheme.apply(self)
	UiTheme.make_bg(self)
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
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(title)

	for m in MODES:
		var panel := PanelContainer.new()
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 72)
		var name := Label.new()
		name.text = tr("menu." + m)
		name.add_theme_font_size_override("font_size", 34)
		name.custom_minimum_size = Vector2(300, 72)
		name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var val := Label.new()
		val.text = str(SaveSystem.best_score(m))
		val.add_theme_font_size_override("font_size", 36)
		val.add_theme_color_override("font_color", UiTheme.COL_ACCENT)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		val.custom_minimum_size = Vector2(160, 72)
		row.add_child(name)
		row.add_child(val)
		panel.add_child(row)
		_vbox.add_child(panel)

	var note := Label.new()
	note.text = tr("leaderboard.local_note")
	note.add_theme_font_size_override("font_size", 24)
	note.add_theme_color_override("font_color", UiTheme.COL_MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vbox.add_child(note)


func _on_back() -> void:
	AudioManager.play_sfx("button")
	BackHandler.block_quit_briefly()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func handle_android_back() -> void:
	_on_back()
