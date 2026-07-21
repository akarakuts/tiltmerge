extends Node
## BackHandler — Android Back / жест «назад» → предыдущий экран, не выход из приложения.
##
## Почему раньше «складывало» приложение:
## 1) quit_on_go_back нужно глушить и в рантайме (не только в project.godot);
## 2) GO_BACK иногда приходит дважды — второй раз уже на MainMenu вызывал quit();
## 3) надёжнее слушать Window.go_back_requested + KEY_BACK.

var _busy: bool = false
var _cooldown_sec: float = 0.0
## После ухода со вложенного экрана на меню — не выходим по Back сразу
## (защита от двойного GO_BACK).
var _quit_block_sec: float = 0.0
const _COOLDOWN := 0.45
const _QUIT_BLOCK := 1.0


func _enter_tree() -> void:
	# Как можно раньше, до первой сцены.
	if get_tree() != null:
		get_tree().set_quit_on_go_back(false)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_disable_system_quit()
	var root := get_tree().root
	if root != null and not root.go_back_requested.is_connected(_on_go_back_requested):
		root.go_back_requested.connect(_on_go_back_requested)


func _process(delta: float) -> void:
	if _cooldown_sec > 0.0:
		_cooldown_sec = maxf(0.0, _cooldown_sec - delta)
	if _quit_block_sec > 0.0:
		_quit_block_sec = maxf(0.0, _quit_block_sec - delta)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			handle_back()
		NOTIFICATION_APPLICATION_RESUMED:
			_disable_system_quit()


func _on_go_back_requested() -> void:
	handle_back()


func _disable_system_quit() -> void:
	var tree := get_tree()
	if tree != null:
		tree.set_quit_on_go_back(false)


## Вызывать из вложенных экранов перед уходом в MainMenu.
func block_quit_briefly() -> void:
	_quit_block_sec = _QUIT_BLOCK
	_cooldown_sec = maxf(_cooldown_sec, _COOLDOWN)


func can_quit_app() -> bool:
	return _quit_block_sec <= 0.0


func _unhandled_input(event: InputEvent) -> void:
	# Только аппаратный/жестовый KEY_BACK. ui_cancel (Esc) не трогаем —
	# его уже использует пауза в игре.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BACK or event.physical_keycode == KEY_BACK:
			handle_back()
			get_viewport().set_input_as_handled()


func handle_back() -> void:
	if _busy or _cooldown_sec > 0.0:
		return
	_busy = true
	_cooldown_sec = _COOLDOWN
	_disable_system_quit()

	var scene := get_tree().current_scene
	if scene == null:
		_busy = false
		return

	if scene.has_method("handle_android_back"):
		scene.handle_android_back()
		_busy = false
		return

	var path := str(scene.scene_file_path)
	if path.ends_with("MainMenu.tscn") or path.ends_with("Boot.tscn"):
		if can_quit_app():
			get_tree().quit()
	elif path.ends_with("Game.tscn"):
		pass
	else:
		block_quit_briefly()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	_busy = false
