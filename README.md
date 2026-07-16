# 🎮 TiltMerge

> Быстрая физическая головоломка для Android: наклоняй телефон — одинаковые кубики слипаются и переходят на следующий уровень (вдохновлено 2048/Threes/Suika Game).

<p align="center"><strong>Жанр:</strong> hyper-casual / casual puzzle &nbsp;•&nbsp; <strong>Платформа:</strong> Android &nbsp;•&nbsp; <strong>Движок:</strong> Godot 4.3+ &nbsp;•&nbsp; <strong>Сессия:</strong> 30–90 сек</p>

---

## 🎯 Суть игры

1. Сверху падают цветные кубики 3 цветов: 🔴 🔵 🟡
2. Ты **наклоняешь телефон** влево/вправо (или свайпом) — кубики катятся по дну коробки
3. Два одинаковых сталкиваются → **слипаются** → переходят на уровень выше
4. Места мало: коробка переполняется снизу вверх → **game over**
5. Цепочки слипаний за 2 сек → **комбо-мультипликатор**

---

## 📂 Структура проекта

```
tiltmerge/
├── project.godot          # Конфиг Godot 4 + настройки Android-экспорта
├── scenes/                # .tscn сцены (Main, MainMenu, GameOver...)
├── scripts/               # .gd скрипты (GDScript)
├── assets/                # Графика, аудио, шрифты (НЕ в git, кроме исходников)
│   ├── graphics/
│   ├── audio/
│   └── fonts/
├── data/                  # Data-driven баланс (config.json, skins.json...)
├── shaders/               # .gdshader эффекты (glow, trail)
├── tests/                 # Unit-тесты логики
├── docs/                  # GDD.md, BALANCE.md, PRIVACY.md
├── store/                 # Материалы для стора (описания, скриншоты)
└── .github/workflows/     # CI: автосборка APK/AAB
```

---

## 🚀 Запуск локально

### 1. Установить Godot 4.3+

```bash
# macOS (через brew)
brew install --cask godot

# или вручную: https://godotengine.org/download
```

### 2. Открыть проект

Открой папку `tiltmerge/` в Godot → **Import** → выбери `project.godot`.

### 3. Запустить

Нажми **F5** (главная сцена `scenes/MainMenu.tscn` уже задана).

---

## 🤖 Роль ZCode в проекте

| Делает ZCode (AI-агент) | Делает человек (🧑‍💼 HUMAN) |
|---|---|
| Код на GDScript | Иконки, арт, музыка |
| Сцены `.tscn`, конфиги | Аккаунт Google Play ($25) |
| GDD, баланс, docs | Тест на реальных устройствах |
| Сборка/CI/тесты | Публикация и маркетинг |
| Локализация | Keystore и подпись релиза |

Подробный roadmap по фазам — в [`docs/GDD.md`](docs/GDD.md).

---

## 📋 Roadmap релиза

- [x] **Фаза 0** — Pre-production: структура, GDD, баланс
- [ ] **Фаза 1** — Прототип механики (наклон + слипание)
- [ ] **Фаза 2** — Core Loop / MVP
- [ ] **Фаза 3** — UI & Onboarding
- [ ] **Фаза 4** — Meta & Удержание
- [ ] **Фаза 5** — Juice & Полировка
- [ ] **Фаза 6** — Сборка & CI
- [ ] **Фаза 7** — QA
- [ ] **Фаза 8** — Soft Launch
- [ ] **Фаза 9** — Global Release

---

## 📄 Лицензия

Proprietary. © 2026 TiltMerge.
