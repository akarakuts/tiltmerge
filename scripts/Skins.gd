extends Control
## Skins — экран выбора скинов кубиков. Фаза 4.
## Косметика: показывает палитру tier 1-5 превью, разблокировку и выбор.

@onready var _grid: GridContainer = $Scroll/VBox/Grid
@onready var _back: Button = $Back


func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	_build()
	$Scroll/VBox/Title.text = tr("skins.title")
	_back.text = tr("settings.back")
	_back.pressed.connect(_on_back)


func _build() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for skin in SkinsManager.list():
		_grid.add_child(_make_card(skin))


func _make_card(skin: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 200)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	# превью палитры
	var preview := HBoxContainer.new()
	preview.alignment = BoxContainer.ALIGNMENT_CENTER
	var pal: Dictionary = GameConfig.skins.get(skin.id, {}).get("palette", {})
	for tier in range(1, 6):
		var sw := ColorRect.new()
		sw.color = Color.from_string(pal.get(str(tier), "#888"), Color.WHITE)
		sw.custom_minimum_size = Vector2(36, 36)
		preview.add_child(sw)
	col.add_child(preview)
	var name := Label.new()
	name.text = skin.name
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 26)
	col.add_child(name)
	var status := Label.new()
	if skin.selected:
		status.text = tr("skins.selected")
	elif skin.unlocked:
		status.text = tr("skins.choose")
	else:
		status.text = tr("skins.locked")
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 20)
	col.add_child(status)
	if skin.unlocked and not skin.selected:
		var btn := Button.new()
		btn.text = tr("skins.select")
		# bind вместо замыкания над loop-переменной: явно фиксируем skin_id на
		# момент создания кнопки, без зависимости от capture-семантики GDScript.
		btn.pressed.connect(_on_select_skin.bind(skin.id))
		col.add_child(btn)
	panel.add_child(col)
	return panel


func _on_select_skin(skin_id: String) -> void:
	SkinsManager.select(skin_id)
	_build()


func _on_back() -> void:
	AudioManager.play_sfx("button")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
