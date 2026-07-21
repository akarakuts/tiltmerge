extends Node2D
## MergeFX — короткие весёлые вспышки/искры при слиянии кубиков.

func burst(pos: Vector2, color: Color, amount: int = 10) -> void:
	if bool(SaveSystem.data.settings.get("reduce_motion", false)):
		return
	for i in amount:
		_spawn_spark(pos, color, i)


func super_burst(pos: Vector2) -> void:
	burst(pos, Color(1.0, 0.85, 0.25, 1.0), 18)
	burst(pos, Color(1.0, 0.45, 0.55, 1.0), 10)


func _spawn_spark(origin: Vector2, color: Color, seed_i: int) -> void:
	var spark := Polygon2D.new()
	var s := 4.0 + (seed_i % 4)
	spark.polygon = PackedVector2Array([
		Vector2(0, -s * 1.6), Vector2(s * 0.7, 0), Vector2(0, s * 1.6), Vector2(-s * 0.7, 0)
	])
	spark.color = color.lightened(0.15)
	spark.z_index = 40
	spark.global_position = origin
	add_child(spark)
	var ang := TAU * float(seed_i) / 12.0 + randf() * 0.4
	var dist := 40.0 + randf() * 70.0
	var target := origin + Vector2(cos(ang), sin(ang)) * dist
	var tw := spark.create_tween()
	tw.set_parallel(true)
	tw.tween_property(spark, "global_position", target, 0.35 + randf() * 0.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(spark, "modulate:a", 0.0, 0.4)
	tw.tween_property(spark, "scale", Vector2(0.2, 0.2), 0.4)
	tw.chain().tween_callback(spark.queue_free)
