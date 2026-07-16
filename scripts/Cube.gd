extends RigidBody2D
## Cube — физический кубик с tier.
## Сталкивается с другими Cube; при совпадении tier-ов они сливаются (через MergeLogic).

signal merged(self_node: Node)

@export var tier: int = 1

var _radius: float = 28.0
var _color: Color = Color.WHITE
var _merge_pending: bool = false  # защита от двойного слияния
var _lifetime: float = 0.0  # для приземления (защита от мгновенного слияния в воздухе)


func setup(p_tier: int) -> void:
	tier = p_tier
	_radius = GameConfig.radius_for_tier(tier)
	_color = GameConfig.color_for_tier(tier)
	_refresh_visual()
	_refresh_physics()


func _refresh_visual() -> void:
	$CollisionShape2D.shape.radius = _radius
	var sprite: Polygon2D = $Visual
	# рисуем квадрат по радиусу
	var s := _radius
	sprite.polygon = PackedVector2Array([
		Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)
	])
	sprite.color = _color
	# лёгкая обводка через второй полигон не делаем — MVP


func _refresh_physics() -> void:
	var p: Dictionary = GameConfig.cfg.cube.physics
	physics_material = PhysicsMaterial.new()
	physics_material.bounce = float(p.bounce)
	physics_material.friction = float(p.friction)
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
		# MergeLogic подписан на merged и выполнит фактический спавн нового кубика
		# удаление — тоже в MergeLogic, чтобы избежать гонок
		_MergeBus.request_merge(self, other_cube)


func _physics_process(delta: float) -> void:
	_lifetime += delta
