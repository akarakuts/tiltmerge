class_name Cube
extends RigidBody2D
## Cube — физический кубик с tier.
## Сталкивается с другими Cube; при совпадении tier-ов они сливаются (через MergeLogic).
## Фаза 5: squash-and-stretch, glow, блик и номер tier.

signal merged(self_node: Node)

@export var tier: int = 1

var _radius: float = 28.0
var _color: Color = Color.WHITE
var _merge_pending: bool = false
var _lifetime: float = 0.0
var _visual: Polygon2D = null
var _shine: Polygon2D = null
var _tier_label: Label = null


func setup(p_tier: int) -> void:
	tier = p_tier
	_radius = GameConfig.radius_for_tier(tier)
	_color = SkinsManager.color_for_tier(tier)
	_refresh_visual()
	_refresh_physics()


func _refresh_visual() -> void:
	$CollisionShape2D.shape.radius = _radius
	_visual = $Visual
	var s: float = _radius
	_visual.polygon = _rounded_square_points(s, s * 0.28)
	_visual.color = _color

	# Блик (веселее и «игрушечнее»)
	if _shine == null:
		_shine = Polygon2D.new()
		_shine.name = "Shine"
		_shine.z_index = 1
		add_child(_shine)
	var hs := s * 0.42
	_shine.polygon = PackedVector2Array([
		Vector2(-hs, -s * 0.55), Vector2(hs * 0.35, -s * 0.72),
		Vector2(hs * 0.15, -s * 0.15), Vector2(-hs * 0.55, -s * 0.05)
	])
	_shine.color = Color(1, 1, 1, 0.38)

	# Номер tier
	if _tier_label == null:
		_tier_label = Label.new()
		_tier_label.name = "TierLabel"
		_tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tier_label.z_index = 2
		add_child(_tier_label)
	_tier_label.text = str(tier)
	var font_size := clampi(int(_radius * 0.9), 14, 36)
	_tier_label.add_theme_font_size_override("font_size", font_size)
	_tier_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	_tier_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	_tier_label.add_theme_constant_override("outline_size", 4)
	_tier_label.size = Vector2(_radius * 2.2, _radius * 2.2)
	_tier_label.position = -_tier_label.size * 0.5

	if not SaveSystem.data.settings.reduce_motion:
		var glow := ShaderMaterial.new()
		glow.shader = preload("res://shaders/Glow.gdshader")
		glow.set_shader_parameter("glow_color", _color.lightened(0.25))
		glow.set_shader_parameter("glow_intensity", 0.85)
		_visual.material = glow
	else:
		_visual.material = null

	if not SaveSystem.data.settings.reduce_motion:
		_visual.scale = Vector2(0.3, 0.3)
		if _shine:
			_shine.scale = Vector2(0.3, 0.3)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_visual, "scale", Vector2(1.15, 0.85), 0.08).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_shine, "scale", Vector2(1.15, 0.85), 0.08).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_property(_visual, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_ELASTIC)
		tw.parallel().tween_property(_shine, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_ELASTIC)


func _rounded_square_points(half: float, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps_per_corner := 5
	var corners := [
		Vector2(half - radius, half - radius),
		Vector2(-half + radius, half - radius),
		Vector2(-half + radius, -half + radius),
		Vector2(half - radius, -half + radius),
	]
	var angles := [-PI / 2.0, PI, PI / 2.0, 0.0]
	for i in range(4):
		var center: Vector2 = corners[i]
		var start: float = angles[i]
		for j in range(steps_per_corner + 1):
			var t: float = start + (PI / 2.0) * (float(j) / float(steps_per_corner))
			pts.append(center + Vector2(cos(t), sin(t)) * radius)
	return pts


func spawn_merge_burst() -> void:
	if SaveSystem.data.settings.reduce_motion or _visual == null:
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_visual, "scale", Vector2(1.35, 1.35), 0.1).set_trans(Tween.TRANS_SINE)
	if _shine:
		tw.tween_property(_shine, "scale", Vector2(1.35, 1.35), 0.1).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_property(_visual, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_ELASTIC)
	if _shine:
		tw.parallel().tween_property(_shine, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_ELASTIC)


func _refresh_physics() -> void:
	var p: Dictionary = GameConfig.cfg.cube.physics
	var mat := PhysicsMaterial.new()
	mat.bounce = float(p.bounce)
	mat.friction = float(p.friction)
	physics_material_override = mat
	mass = float(p.mass_base) * (1.0 + 0.1 * (tier - 1))


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)


func _on_body_entered(other: Node) -> void:
	if _merge_pending:
		return
	if not other is Cube:
		return
	var other_cube: Cube = other
	if other_cube.tier != tier:
		return
	if other_cube._merge_pending:
		return
	if _lifetime < 0.05 or other_cube._lifetime < 0.05:
		return
	if is_instance_valid(other_cube) and get_instance_id() < other_cube.get_instance_id():
		_merge_pending = true
		other_cube._merge_pending = true
		merged.emit(self)
		MergeBus.request_merge(self, other_cube)


func _physics_process(delta: float) -> void:
	_lifetime += delta
