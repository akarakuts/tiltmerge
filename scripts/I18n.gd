extends Node
## I18n (autoload singleton)
## Регистрирует переводы из скомпилированных .translation-ресурсов.
## Источник CSV — translations/{en,ru}.csv; Godot компилирует их в .translation
## при импорте, и они же подключаются автоматически через project.godot
## (locale/translations). Здесь — лишь явная страховка + применение языка.


func _ready() -> void:
	# Переводы подключаются двумя путями, и оба указывают на один и тот же
	# скомпилированный ресурс: автоматически через project.godot
	# (locale/translations) и явно ниже — как страховка, если проект открыт
	# без предымпорта. Ручной парсинг CSV удалён: он дублировал бы .translation
	# и не поддерживал запятые в значениях.
	_load_translation_resource("res://translations/en.en.translation")
	_load_translation_resource("res://translations/ru.ru.translation")
	# SaveSystem ещё может не успеть загрузить save — только OS-локаль.
	# Settings/MainMenu вызовут apply_saved_language после.
	apply_saved_language("auto")
	if OS.is_debug_build():
		print("[I18n] locale=%s" % TranslationServer.get_locale())


## Применяет язык. При "auto" берёт локаль ОС/Android (ru_RU, de_DE, zh_CN, ...)
## и автоматически подбирает ближайшую загруженную локаль с fallback на en.
## Богот сам делает matching по базовой локали, но мы явно нормализуем к
## реально загруженной, чтобы UI-индикатор языка показывал осмысленное значение,
## а не сырой "xx_YY" без перевода.
func apply_saved_language(lang: String) -> void:
	if lang == "auto" or lang == "":
		lang = _best_locale_for(OS.get_locale())
	TranslationServer.set_locale(lang)


## Подбирает ближайшую загруженную локаль к запрошенной:
##   1. точное совпадение (ru_RU == ru_RU)
##   2. базовая локаль (ru_RU → ru)
##   3. любая загруженная, начинающаяся с базы (zh_Hant → zh_TW)
##   4. fallback на "en" (locale/fallback в project.godot)
func _best_locale_for(requested: String) -> String:
	if requested.is_empty():
		return "en"
	var loaded := TranslationServer.get_loaded_locales()
	if loaded.has(requested):
		return requested
	var base := requested.split("_")[0]
	if loaded.has(base):
		return base
	for loc in loaded:
		if loc.begins_with(base):
			return loc
	return "en"


func _load_translation_resource(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var res = load(path)
	if res is Translation:
		TranslationServer.add_translation(res)

