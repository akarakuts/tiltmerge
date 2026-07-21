extends Node
## UiTheme — единый визуальный стиль TiltMerge (тёмный фон + бирюзовый акцент).
## Подключать theme к корню Control/CanvasLayer HUD.

const COL_BG := Color(0.07, 0.11, 0.18, 1.0)
const COL_BG_TOP := Color(0.14, 0.28, 0.38, 1.0)
const COL_PANEL := Color(0.12, 0.18, 0.26, 0.94)
const COL_PANEL_SOFT := Color(0.11, 0.16, 0.24, 0.78)
const COL_ACCENT := Color(0.30, 0.90, 0.78, 1.0)
const COL_ACCENT_DOWN := Color(0.18, 0.65, 0.56, 1.0)
const COL_ACCENT_HOVER := Color(0.45, 0.96, 0.85, 1.0)
const COL_SECONDARY := Color(0.16, 0.24, 0.34, 1.0)
const COL_SECONDARY_HOVER := Color(0.22, 0.32, 0.44, 1.0)
const COL_TEXT := Color(0.96, 0.98, 1.0, 1.0)
const COL_MUTED := Color(0.68, 0.78, 0.88, 1.0)
const COL_DANGER := Color(1.0, 0.38, 0.45, 1.0)
const COL_OUTLINE := Color(0.32, 0.48, 0.55, 1.0)

var theme: Theme


func _ready() -> void:
	theme = build_theme()


func apply(root: Control) -> void:
	if root == null:
		return
	if theme == null:
		theme = build_theme()
	root.theme = theme


func build_theme() -> Theme:
	var t := Theme.new()
	t.set_color("font_color", "Label", COL_TEXT)
	t.set_color("font_color", "Button", COL_TEXT)
	t.set_color("font_hover_color", "Button", COL_TEXT)
	t.set_color("font_pressed_color", "Button", COL_TEXT)
	t.set_color("font_disabled_color", "Button", COL_MUTED)
	t.set_color("font_color", "CheckButton", COL_TEXT)
	t.set_color("font_hover_color", "CheckButton", COL_TEXT)
	t.set_color("font_pressed_color", "CheckButton", COL_TEXT)
	t.set_color("font_color", "OptionButton", COL_TEXT)

	t.set_stylebox("normal", "Button", _btn(COL_SECONDARY, COL_OUTLINE))
	t.set_stylebox("hover", "Button", _btn(COL_SECONDARY_HOVER, COL_ACCENT))
	t.set_stylebox("pressed", "Button", _btn(COL_ACCENT_DOWN, COL_ACCENT))
	t.set_stylebox("disabled", "Button", _btn(Color(0.12, 0.14, 0.18, 1), Color(0.2, 0.22, 0.28, 1)))
	t.set_stylebox("focus", "Button", _btn(COL_SECONDARY, COL_ACCENT))

	# Primary CTA: Button type variation via theme type
	t.set_type_variation("PrimaryButton", "Button")
	t.set_stylebox("normal", "PrimaryButton", _btn(COL_ACCENT, COL_ACCENT))
	t.set_stylebox("hover", "PrimaryButton", _btn(COL_ACCENT_HOVER, COL_ACCENT_HOVER))
	t.set_stylebox("pressed", "PrimaryButton", _btn(COL_ACCENT_DOWN, COL_ACCENT_DOWN))
	t.set_stylebox("disabled", "PrimaryButton", _btn(COL_ACCENT_DOWN, COL_ACCENT_DOWN))
	t.set_stylebox("focus", "PrimaryButton", _btn(COL_ACCENT, COL_ACCENT))
	t.set_color("font_color", "PrimaryButton", Color(0.05, 0.1, 0.12, 1))
	t.set_color("font_hover_color", "PrimaryButton", Color(0.05, 0.1, 0.12, 1))
	t.set_color("font_pressed_color", "PrimaryButton", Color(0.05, 0.1, 0.12, 1))

	t.set_type_variation("GhostButton", "Button")
	t.set_stylebox("normal", "GhostButton", _btn(Color(0, 0, 0, 0), COL_OUTLINE))
	t.set_stylebox("hover", "GhostButton", _btn(Color(1, 1, 1, 0.06), COL_ACCENT))
	t.set_stylebox("pressed", "GhostButton", _btn(Color(1, 1, 1, 0.1), COL_ACCENT))
	t.set_stylebox("focus", "GhostButton", _btn(Color(0, 0, 0, 0), COL_ACCENT))

	t.set_stylebox("normal", "CheckButton", _btn(COL_PANEL_SOFT, COL_OUTLINE, 18))
	t.set_stylebox("hover", "CheckButton", _btn(COL_PANEL, COL_ACCENT, 18))
	t.set_stylebox("pressed", "CheckButton", _btn(COL_PANEL, COL_ACCENT, 18))
	t.set_stylebox("hover_pressed", "CheckButton", _btn(COL_PANEL, COL_ACCENT, 18))
	t.set_stylebox("focus", "CheckButton", _btn(COL_PANEL_SOFT, COL_ACCENT, 18))

	t.set_stylebox("panel", "PanelContainer", _panel(COL_PANEL, 20))
	t.set_stylebox("panel", "Panel", _panel(COL_PANEL, 20))

	t.set_constant("h_separation", "HBoxContainer", 14)
	t.set_constant("v_separation", "VBoxContainer", 16)
	t.set_constant("separation", "VBoxContainer", 16)
	return t


func make_bg(parent: Control) -> void:
	## Градиентный фон: низ темнее, сверху мягкий блик + акцентное пятно.
	var base := ColorRect.new()
	base.name = "UiBg"
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.color = COL_BG
	parent.add_child(base)
	parent.move_child(base, 0)

	var top := ColorRect.new()
	top.name = "UiBgTop"
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 420.0
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.color = Color(COL_BG_TOP.r, COL_BG_TOP.g, COL_BG_TOP.b, 0.55)
	parent.add_child(top)
	parent.move_child(top, 1)

	var glow := ColorRect.new()
	glow.name = "UiGlow"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.color = Color(COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 0.07)
	glow.offset_left = 120.0
	glow.offset_top = -80.0
	glow.offset_right = 600.0
	glow.offset_bottom = 280.0
	parent.add_child(glow)
	parent.move_child(glow, 2)


func _btn(bg: Color, border: Color, radius: float = 18.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(int(radius))
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	return s


func _panel(bg: Color, radius: float = 20.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = COL_OUTLINE
	s.set_border_width_all(1)
	s.set_corner_radius_all(int(radius))
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	return s
