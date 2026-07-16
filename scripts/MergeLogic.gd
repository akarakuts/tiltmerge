extends Node
## MergeLogic
## Слушает MergeBus.merge_requested, выполняет слияние:
##   - удаляет 2 старых кубика
##   - спавнит новый tier+1 в точке контакта (или супер-эффект для max tier)
##   - начисляет очки, обновляет комбо, эмитит merge_completed
##
## Очки = base_score[new_tier] * combo_multiplier.
## Комбо: растёт за слияния в течение combo_window; иначе сбрасывается.
## Фаза 5: burst-анимация + floating score text.

const CubeScenePath := "res://scenes/Cube.tscn"

var score: int = 0
var combo_count: int = 0
var _combo_timer: float = 0.0
var _combo_window: float = 2.0
var _combo_multipliers: Array = [1.0, 1.0, 1.5, 2.0, 3.0, 5.0]

signal score_changed(new_score: int, delta: int)
signal combo_changed(combo_count: int, multiplier: float)

var _scene_root: Node2D = null  # куда добавлять новые кубики


func setup(scene_root: Node2D) -> void:
	_scene_root = scene_root
	_combo_window = float(GameConfig.cfg.combo.window_sec)
	_combo_multipliers = GameConfig.cfg.combo.multipliers.duplicate()
	MergeBus.merge_requested.connect(_on_merge_requested)


func reset() -> void:
	score = 0
	combo_count = 0
	_combo_timer = 0.0


func _physics_process(delta: float) -> void:
	if combo_count > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo_count = 0
			combo_changed.emit(0, _multiplier_for(0))


func _on_merge_requested(a: Node, b: Node) -> void:
	if not (is_instance_valid(a) and is_instance_valid(b)):
		return
	var old_tier: int = a.tier
	var new_tier: int = old_tier + 1
	var pos: Vector2 = (a.global_position + b.global_position) * 0.5

	# комбо растёт
	combo_count += 1
	_combo_timer = _combo_window
	var mult: float = _multiplier_for(combo_count)
	combo_changed.emit(combo_count, mult)

	# удаляем старые
	a.queue_free()
	b.queue_free()

	var delta_score: int
	if new_tier > GameConfig.max_tier():
		# супер-эффект: лопается, большой бонус, новый кубик не создаётся
		var super_mult: float = float(GameConfig.cfg.merge.super_bonus_multiplier)
		delta_score = int(GameConfig.tier_data(old_tier).score) * int(super_mult)
		_spawn_floating_text(pos, "+%d SUPER!" % delta_score, Color.GOLD)
	else:
		# спавним новый кубик
		var new_cube = _spawn_cube(new_tier, pos)
		if new_cube.has_method("spawn_merge_burst"):
			new_cube.spawn_merge_burst()
		MergeBus.merge_completed.emit(new_cube, old_tier, new_tier, pos)
		delta_score = int(GameConfig.tier_data(new_tier).score) * int(mult)
		var txt: String = "+%d" % delta_score if mult <= 1.0 else "+%d x%.1f" % [delta_score, mult]
		_spawn_floating_text(pos, txt, GameConfig.color_for_tier(new_tier) if mult <= 1.0 else Color.GOLD)

	score += delta_score
	score_changed.emit(score, delta_score)


func _spawn_floating_text(pos: Vector2, text: String, color: Color) -> void:
	if _scene_root == null:
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28 + min(20, text.length()))
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.position = pos
	lbl.z_index = 50
	_scene_root.add_child(lbl)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y - 80, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(lbl.queue_free)


func _spawn_cube(tier: int, pos: Vector2) -> Node:
	var scene := load(CubeScenePath) as PackedScene
	var cube = scene.instantiate()
	_scene_root.add_child(cube)
	cube.global_position = pos
	cube.setup(tier)
	return cube


func _multiplier_for(count: int) -> float:
	if count <= 0:
		return 1.0
	var idx: int = min(count, _combo_multipliers.size() - 1)
	return float(_combo_multipliers[idx])
