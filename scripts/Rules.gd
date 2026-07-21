extends Control
## Rules — статичная страница с правилами игры (доступна из меню).

@onready var _title: Label = $Title
@onready var _scroll: ScrollContainer = $Scroll
@onready var _body: VBoxContainer = $Scroll/Body
@onready var _back: Button = $Back


func _ready() -> void:
	UiTheme.apply(self)
	UiTheme.make_bg(self)
	# Скрыть старый плоский Bg, если остался в сцене
	var old_bg := get_node_or_null("Bg")
	if old_bg:
		old_bg.hide()
	I18n.apply_saved_language("auto")
	_title.text = tr("rules.title")
	_back.text = tr("settings.back")
	_back.pressed.connect(_on_back)
	_build_sections()


func _build_sections() -> void:
	for child in _body.get_children():
		child.queue_free()
	var keys := [
		["rules.s1_title", "rules.s1_body"],
		["rules.s2_title", "rules.s2_body"],
		["rules.s3_title", "rules.s3_body"],
		["rules.s4_title", "rules.s4_body"],
		["rules.s5_title", "rules.s5_body"],
	]
	for pair in keys:
		_body.add_child(_make_card(tr(pair[0]), tr(pair[1])))


func _make_card(heading: String, body: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	var h := Label.new()
	h.text = heading
	h.add_theme_font_size_override("font_size", 32)
	h.add_theme_color_override("font_color", UiTheme.COL_ACCENT)
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var b := Label.new()
	b.text = body
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", UiTheme.COL_TEXT)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(h)
	col.add_child(b)
	panel.add_child(col)
	return panel


func _on_back() -> void:
	AudioManager.play_sfx("button")
	BackHandler.block_quit_briefly()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func handle_android_back() -> void:
	_on_back()
