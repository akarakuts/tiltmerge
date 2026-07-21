extends Node2D
## ArenaDecor — весёлый фон игровой арены: градиент, мягкие пятна, бортики.

var _blobs: Array = []  # {node, vel, base}
var _pulse: float = 0.0
var _danger: Line2D = null
var _reduce_motion: bool = false


func setup(danger_line: Line2D = null) -> void:
	_danger = danger_line
	_reduce_motion = bool(SaveSystem.data.settings.get("reduce_motion", false))
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_blobs.clear()

	# Фон арены
	var bg := Polygon2D.new()
	bg.z_index = -20
	bg.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(720, 0), Vector2(720, 1280), Vector2(0, 1280)
	])
	bg.color = Color(0.07, 0.11, 0.18, 1.0)
	add_child(bg)

	# Верхний «небо»-блик
	var sky := Polygon2D.new()
	sky.z_index = -19
	sky.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(720, 0), Vector2(720, 420), Vector2(0, 520)
	])
	sky.color = Color(0.18, 0.35, 0.48, 0.35)
	add_child(sky)

	# Мягкие цветные пятна
	var colors := [
		Color(0.35, 0.86, 0.76, 0.10),
		Color(0.98, 0.55, 0.35, 0.09),
		Color(0.95, 0.80, 0.30, 0.08),
		Color(0.55, 0.45, 0.95, 0.08),
		Color(0.30, 0.75, 0.95, 0.09),
	]
	var seeds := [
		Vector2(120, 380), Vector2(560, 520), Vector2(200, 900),
		Vector2(500, 780), Vector2(360, 1100)
	]
	for i in colors.size():
		var blob := Polygon2D.new()
		blob.z_index = -18
		blob.polygon = _circle_pts(70.0 + i * 12.0, 16)
		blob.color = colors[i]
		blob.position = seeds[i]
		add_child(blob)
		_blobs.append({"node": blob, "vel": Vector2(18 + i * 3, -12 + i * 4), "base": seeds[i]})

	# Игровое «поле» чуть светлее
	var play := Polygon2D.new()
	play.z_index = -17
	play.polygon = PackedVector2Array([
		Vector2(28, 60), Vector2(692, 60), Vector2(692, 1220), Vector2(28, 1220)
	])
	play.color = Color(0.10, 0.14, 0.22, 0.55)
	add_child(play)

	# Бортики
	_add_rail(Vector2(0, 640), Vector2(28, 1280), Color(0.35, 0.86, 0.76, 0.55))
	_add_rail(Vector2(692, 640), Vector2(28, 1280), Color(0.35, 0.86, 0.76, 0.55))
	_add_rail(Vector2(360, 1248), Vector2(720, 36), Color(0.98, 0.72, 0.35, 0.65))

	# Нижняя «подушка»
	var cushion := Polygon2D.new()
	cushion.z_index = -10
	cushion.polygon = PackedVector2Array([
		Vector2(40, 1205), Vector2(680, 1205), Vector2(700, 1240), Vector2(20, 1240)
	])
	cushion.color = Color(0.98, 0.72, 0.35, 0.25)
	add_child(cushion)


func _add_rail(center: Vector2, size: Vector2, color: Color) -> void:
	var rail := Polygon2D.new()
	rail.z_index = -9
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	rail.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	rail.position = center
	rail.color = color
	add_child(rail)


func _circle_pts(r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


func _process(delta: float) -> void:
	if _reduce_motion:
		return
	_pulse += delta
	for item in _blobs:
		var n: Polygon2D = item.node
		if not is_instance_valid(n):
			continue
		var base: Vector2 = item.base
		var vel: Vector2 = item.vel
		n.position = base + Vector2(
			sin(_pulse * 0.7 + vel.x * 0.05) * 28.0,
			cos(_pulse * 0.55 + vel.y * 0.04) * 22.0
		)
		var s := 1.0 + 0.06 * sin(_pulse * 1.2 + vel.x)
		n.scale = Vector2(s, s)
	if _danger != null and is_instance_valid(_danger):
		var a := 0.35 + 0.25 * (0.5 + 0.5 * sin(_pulse * 3.0))
		_danger.default_color = Color(1.0, 0.35, 0.42, a)
		_danger.width = 3.0 + sin(_pulse * 4.0) * 0.8
