extends Node
## BackHandler — Android Back / жест «назад» ведёт на предыдущий экран, а не закрывает приложение.

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back()


func handle_back() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if scene.has_method("handle_android_back"):
		scene.handle_android_back()
		return
	# запасной маршрут по пути сцены
	var path := str(scene.scene_file_path)
	if path.ends_with("MainMenu.tscn") or path.ends_with("Boot.tscn"):
		get_tree().quit()
	elif path.ends_with("Game.tscn"):
		pass
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
