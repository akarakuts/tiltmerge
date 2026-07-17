extends Node
## I18n (autoload singleton)
## Регистрирует переводы из CSV (и из .translation, если уже в Project Settings).
## CSV: колонка key + locale; поля с запятыми — в кавычках.

const TRANSLATIONS_DIR := "res://translations/"


func _ready() -> void:
	_load_csv("en.csv", "en")
	_load_csv("ru.csv", "ru")
	_load_translation_resource("res://translations/en.en.translation")
	_load_translation_resource("res://translations/ru.ru.translation")
	# SaveSystem ещё может не успеть загрузить save — только OS-локаль.
	# Settings/MainMenu вызовут apply_saved_language после.
	apply_saved_language("auto")
	print("[I18n] locale=%s" % TranslationServer.get_locale())


func apply_saved_language(lang: String) -> void:
	if lang == "auto" or lang == "":
		var os_locale := OS.get_locale()
		# ru_RU → ru, en_US → en
		if os_locale.begins_with("ru"):
			TranslationServer.set_locale("ru")
		elif os_locale.begins_with("en"):
			TranslationServer.set_locale("en")
		else:
			TranslationServer.set_locale(os_locale)
	else:
		TranslationServer.set_locale(lang)


func _load_translation_resource(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var res = load(path)
	if res is Translation:
		TranslationServer.add_translation(res)


func _load_csv(filename: String, locale: String) -> void:
	var path := TRANSLATIONS_DIR + filename
	if not FileAccess.file_exists(path):
		push_warning("[I18n] %s not found" % path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var translation := Translation.new()
	translation.locale = locale
	var first := true
	for line in text.split("\n", false):
		line = line.strip_edges()
		if line.is_empty():
			continue
		if first:
			first = false
			continue
		var key := ""
		var msg := ""
		var comma := line.find(",")
		if comma < 0:
			continue
		key = line.substr(0, comma).strip_edges()
		msg = line.substr(comma + 1).strip_edges()
		# снять окружающие кавычки CSV
		if msg.length() >= 2 and msg.begins_with("\"") and msg.ends_with("\""):
			msg = msg.substr(1, msg.length() - 2).replace("\"\"", "\"")
		if not key.is_empty():
			translation.add_message(key, msg)
	TranslationServer.add_translation(translation)
