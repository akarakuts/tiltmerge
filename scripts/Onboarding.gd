extends Control
## Onboarding — 3 шага: наклон / слипание / не дать достичь верха.
## Фаза 3. Простые слайды, кнопка GOT IT → MainMenu.

var _step: int = 0
var _steps: Array = ["onboarding.step1", "onboarding.step2", "onboarding.step3"]

@onready var _title: Label = $VBox/Title
@onready var _body: Label = $VBox/Body
@onready var _next: Button = $VBox/Next
@onready var _dots: Label = $VBox/Dots


func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	_title.text = tr("onboarding.title")
	_next.pressed.connect(_on_next)
	_show_step()


func _show_step() -> void:
	_body.text = tr(_steps[_step])
	var dots_arr: Array = []
	for i in range(_steps.size()):
		dots_arr.append("●" if i == _step else "○")
	_dots.text = "  ".join(dots_arr)
	_next.text = tr("onboarding.start") if _step == _steps.size() - 1 else "→"


func _on_next() -> void:
	AudioManager.play_sfx("button")
	_step += 1
	if _step >= _steps.size():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	_show_step()
