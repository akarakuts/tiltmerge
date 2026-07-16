extends Node
## I18n (autoload singleton)
## Загружает CSV-файлы переводов во время выполнения и регистрирует их в TranslationServer.
## CSV-формат: первая колонка "key", далее колонки по кодам языков (en, ru, ...).
## Запускается ПЕРВЫМ среди autoloads (см. порядок в project.godot), чтобы переводы
## были доступны всем остальным autoload/сценам в их _ready.

const TRANSLATIONS_DIR := "res://translations/"


func _ready() -> void:
	_load_csv("en.csv", "en")
	_load_csv("ru.csv", "ru")
	# по умолчанию — язык ОС. Сохранённое предпочтение применит Settings.gd после.
	TranslationServer.set_locale(OS.get_locale())
	print("[I18n] translations registered (en, ru), locale=%s" % TranslationServer.get_locale())


## Применяет выбранный язык (вызывается из Settings после загрузки сохранения)
func apply_saved_language(lang: String) -> void:
	if lang == "auto" or lang == "":
		TranslationServer.set_locale(OS.get_locale())
	else:
		TranslationServer.set_locale(lang)


func _load_csv(filename: String, locale: String) -> void:
	var path := TRANSLATIONS_DIR + filename
	if not FileAccess.file_exists(path):
		push_warning("[I18n] %s not found" % path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var translation := Translation.new()
	translation.locale = locale
	# парсим CSV вручную: простейший split по строкам и запятым (без кавычек/экранирования)
	var first := true
	for line in text.split("\n", false):
		var cols := line.split(",", false)
		if first:
			first = false
			continue  # заголовок
		if cols.size() >= 2:
			translation.add_message(cols[0].strip_edges(), cols[1].strip_edges())
	TranslationServer.add_translation(translation)


func _apply_locale(lang: String) -> void:
	if lang == "auto" or lang == "":
		TranslationServer.set_locale(OS.get_locale())
	else:
		TranslationServer.set_locale(lang)
