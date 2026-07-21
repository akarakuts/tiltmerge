# TiltMerge

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

English: [README.md](README.md)

**TiltMerge** — быстрая физическая головоломка для Android: наклоняй телефон, чтобы одинаковые кубики слипались и переходили на следующий уровень (вдохновлено 2048 / Threes / Suika Game). Стек: **Godot 4.3+**, **GDScript**.

## Возможности

- **Core loop** — кубики падают сверху; наклон (или свайп) катит их; одинаковый **tier** сливается в следующий; переполнение за линию потолка — game over (с коротким grace-периодом).
- **Управление** — акселерометр как основной ввод; свайп/тач — fallback для десктопа и эмулятора; A/D или ←/→ для отладки.
- **Тактика** — превью следующего кубика, **reroll** за комбо, окно комбо-мультипликатора (~2 с).
- **Режимы** — Classic, Blitz (60 с), Zen (без game over), Daily (seed + цель по tier).
- **Мета** — локальные рекорды, достижения, скины, онбординг (интерактивный или слайды по A/B), локализация на 23 языка с авто-определением локали Android.
- **Juice** — haptics, тряска камеры, squash/stretch, glow, всплывающие очки, SFX/музыка (ассеты опциональны).
- **Баланс data-driven** — tiers, спавн, tilt, комбо и режимы в `data/config.json` (см. `docs/BALANCE.md`).

## Требования и сборка

Как в [README.md](README.md): Godot 4.3+ с Android export templates, JDK 17+, Android SDK (min API 24), пакет `com.akarakuts.tiltmerge`.

```bash
# Редактор: открыть project.godot → F5 (сценa scenes/MainMenu.tscn)

./scripts/run_tests.sh
godot --headless --path . --export-debug "Android Debug" build/tiltmerge-debug.apk
```

Подпись **release** — в англ. README, раздел [Release signing](README.md#release-signing). Чеклист публикации: [docs/RELEASE_CHECKLIST.ru.md](docs/RELEASE_CHECKLIST.ru.md), soft launch: [docs/SOFT_LAUNCH.md](docs/SOFT_LAUNCH.md). Финальный ручной gate описан в [Android device QA](docs/DEVICE_QA.ru.md).

## CI (GitHub Actions)

Как в англ. README: [Build Android](.github/workflows/build.yml) — import, gdlint, тесты, parity переводов, debug APK; по тегу `v*` — релиз с подписанным AAB при наличии секретов (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`).

## Структура проекта

| Путь | Назначение |
|------|------------|
| `scenes/` | Меню, игра, настройки, онбординг, скины, лидерборд |
| `scripts/Cube.gd`, `MergeLogic.gd`, `Spawner.gd`, `TiltController.gd` | Ядро геймплея |
| `scripts/Game.gd` | Режимы, HUD, game over |
| `scripts/GameConfig.gd` | Загрузка `data/config.json` / `skins.json` |
| `data/config.json` | Источник истины по балансу |
| `tests/` | Unit + gameplay + onboarding |
| `docs/` | GDD, BALANCE, PRIVACY, soft launch, checklist |
| `store/` | Тексты витрины |

## Тесты и скрипты

```bash
python3 -m pip install -r requirements-dev.txt
./scripts/check_quality.sh
```

Quality gate запускает линтер GDScript, проверки релизной конфигурации и переводов, затем весь headless-набор. В CI используется эта же команда.

```bash
./scripts/run_tests.sh
python3 scripts/validate_release.py
./scripts/check_strings_parity.sh
```

| Скрипт | Назначение |
|--------|------------|
| `scripts/check_quality.sh` | Полный quality gate для локальной разработки и CI |
| `scripts/run_tests.sh` | Headless-набор тестов Godot |
| `scripts/validate_release.py` | Проверки релизной конфигурации |
| `scripts/check_strings_parity.sh` | Паритет ключей переводов (все языки vs en) |
| `scripts/build_release.sh` | Экспорт подписанного AAB по пути из `store-upload.dir` |
| `scripts/generate_sounds.py` | Генерация WAV-заглушек |
| `scripts/generate_assets.py` | Иконки / графика для стора |

Подробнее — разделы Testing и Scripts в [README.md](README.md).

## Контакты

**Aleksey Karakuts** — [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

## Лицензия

Программа распространяется на условиях **GNU GPLv3** — полный текст в файле [`LICENSE`](LICENSE).

Copyright (C) 2026 Aleksey Karakuts &lt;aleksey@karakuts.com&gt;
