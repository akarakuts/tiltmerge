class_name Cube
extends RigidBody2D
## Cube — физический кубик с tier.
## Сталкивается с другими Cube; при совпадении tier-ов они сливаются (через MergeLogic).
## Фаза 5: добавлены squash-and-stretch при появлении и glow-shader на Visual.

signal merged(self_node: Node)

@export var tier: int = 1

var _radius: float = 28.0
var _color: Color = Color.WHITE
var _merge_pending: bool = false  # защита от двойного слияния
var _lifetime: float = 0.0  # для приземления (защита от мгновенного слияния в воздухе)
var _visual: Polygon2D = null


func setup(p_tier: int) -> void:
	tier = p_tier
	_radius = GameConfig.radius_for_tier(tier)
	_color = SkinsManager.color_for_tier(tier)
	_refresh_visual()
	_refresh_physics()


func _refresh_visual() -> void:
	$CollisionShape2D.shape.radius = _radius
	_visual = $Visual
	# рисуем скруглённый квадрат (многоугольник с округлёнными углами)
	var s: float = _radius
	_visual.polygon = _rounded_square_points(s, s * 0.28)
	_visual.color = _color
	# glow shader (если reduce_motion — пропускаем для производительности)
	if not SaveSystem.data.settings.reduce_motion:
		var glow := ShaderMaterial.new()
		glow.shader = preload("res://shaders/Glow.gdshader")
		glow.set_shader_parameter("glow_color", _color)
		glow.set_shader_parameter("glow_intensity", 0.6)
		_visual.material = glow
	# pop-in анимация (squash-and-stretch)
	if not SaveSystem.data.settings.reduce_motion:
		_visual.scale = Vector2(0.3, 0.3)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_visual, "scale", Vector2(1.15, 0.85), 0.08).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_property(_visual, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_ELASTIC)


# Генерирует вершины скруглённого квадрата (для красивого вида кубика).
func _rounded_square_points(half: float, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps_per_corner := 5
	var corners := [
		Vector2(half - radius, half - radius),   # нижний-правый
		Vector2(-half + radius, half - radius),  # нижний-левый
		Vector2(-half + radius, -half + radius), # верхний-левый
		Vector2(half - radius, -half + radius),  # верхний-правый
	]
	var angles := [-PI / 2.0, PI, PI / 2.0, 0.0]  # стартовый угол для каждого угла
	for i in range(4):
		var center: Vector2 = corners[i]
		var start: float = angles[i]
		for j in range(steps_per_corner + 1):
			var t: float = start + (PI / 2.0) * (float(j) / float(steps_per_corner))
			pts.append(center + Vector2(cos(t), sin(t)) * radius)
	return pts


func spawn_merge_burst() -> void:
	# вспышка при появлении нового кубика (вызывается MergeLogic)
	if SaveSystem.data.settings.reduce_motion or _visual == null:
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_visual, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_property(_visual, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_ELASTIC)


func _refresh_physics() -> void:
	var p: Dictionary = GameConfig.cfg.cube.physics
	# PhysicsMaterial применяется к RigidBody2D напрямую (physics_material_override)
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
	# защита: не сливать в первые 0.05с жизни (избежать слияния при спавне)
	if _lifetime < 0.05 or other_cube._lifetime < 0.05:
		return
	# сливаемся: один из двух берёт на себя роль «инициатора»
	if is_instance_valid(other_cube) and get_instance_id() < other_cube.get_instance_id():
		_merge_pending = true
		other_cube._merge_pending = true
		merged.emit(self)
		# MergeLogic подписан на merge_requested через шину и выполнит работу
		MergeBus.request_merge(self, other_cube)


func _physics_process(delta: float) -> void:
	_lifetime += delta
