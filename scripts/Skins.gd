extends Control
## Skins — экран выбора скинов кубиков.

@onready var _grid: GridContainer = $Scroll/VBox/Grid
@onready var _back: Button = $Back
@onready var _title: Label = $Title


func _ready() -> void:
	UiTheme.apply(self)
	UiTheme.make_bg(self)
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	_build()
	_title.text = tr("skins.title")
	_back.text = tr("settings.back")
	_back.pressed.connect(_on_back)


func _build() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for skin in SkinsManager.list():
		_grid.add_child(_make_card(skin))


func _make_card(skin: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 280)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	var preview := HBoxContainer.new()
	preview.alignment = BoxContainer.ALIGNMENT_CENTER
	preview.add_theme_constant_override("separation", 8)
	var pal: Dictionary = GameConfig.skins.get(skin.id, {}).get("palette", {})
	for tier in range(1, 6):
		var sw := ColorRect.new()
		sw.color = Color.from_string(pal.get(str(tier), "#888"), Color.WHITE)
		sw.custom_minimum_size = Vector2(44, 44)
		preview.add_child(sw)
	col.add_child(preview)
	var name := Label.new()
	name.text = skin.name
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 32)
	col.add_child(name)
	var status := Label.new()
	if skin.selected:
		status.text = tr("skins.selected")
		status.add_theme_color_override("font_color", UiTheme.COL_ACCENT)
	elif skin.unlocked:
		status.text = tr("skins.choose")
		status.add_theme_color_override("font_color", UiTheme.COL_MUTED)
	else:
		status.text = tr("skins.locked")
		status.add_theme_color_override("font_color", UiTheme.COL_MUTED)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 26)
	col.add_child(status)
	if skin.unlocked and not skin.selected:
		var btn := Button.new()
		btn.text = tr("skins.select")
		btn.custom_minimum_size = Vector2(0, 72)
		btn.theme_type_variation = &"PrimaryButton"
		btn.add_theme_font_size_override("font_size", 30)
		btn.pressed.connect(_on_select_skin.bind(skin.id))
		col.add_child(btn)
	panel.add_child(col)
	return panel


func _on_select_skin(skin_id: String) -> void:
	SkinsManager.select(skin_id)
	AudioManager.play_sfx("button")
	_build()


func _on_back() -> void:
	AudioManager.play_sfx("button")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func handle_android_back() -> void:
	_on_back()
