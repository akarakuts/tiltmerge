extends Node
## Boot — точка входа: без вспышки меню сразу ведёт на онбординг или MainMenu.

func _ready() -> void:
	if not GameConfig.is_ready:
		await GameConfig.config_loaded
	if not bool(SaveSystem.data.get("onboarding_completed", false)):
		get_tree().change_scene_to_file("res://scenes/Onboarding.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func handle_android_back() -> void:
	get_tree().quit()
