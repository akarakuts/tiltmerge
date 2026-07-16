# 🏪 TiltMerge — Google Play Store Listing

> Фаза 9. ASO-тексты (RU + EN), Data Safety, инструкции по публикации.
> Материалы готовы к загрузке в Play Console.

---

## 📌 Идентификация

| Поле | Значение |
|---|---|
| **Package name** | `com.akarakuts.tiltmerge` |
| **App name** | TiltMerge |
| **Developer** | akarakuts |
| **Category** | Puzzle |
| **Content rating** | Everyone (пройти IARC-опросник) |
| **Target audience** | 13+ (general) |
| **Default language** | en-US (с переводами ru-RU) |

---

## 📝 Short description (80 chars max)

**EN:** `Tilt your phone, merge the cubes! A fast physics puzzle.`
**RU:** `Наклоняй телефон и сливай кубики! Быстрая головоломка.`

---

## 📝 Full description

### EN (≤ 4000 chars)

```
TiltMerge — a fast, satisfying physics puzzle you can play with one hand.

🎯 HOW TO PLAY
• Tilt your phone left and right to roll the cubes.
• When two cubes of the same color collide, they MERGE into a bigger one.
• Keep merging to climb the tiers — but don't let the box overflow!
• Chain merges quickly to build a COMBO and multiply your score.

✨ FEATURES
• Unique tilt control — feel the physics in your hand
• 3 game modes: Classic (endless), Blitz (60s), Zen (relax)
• Daily Challenge — same layout for everyone, beat the leaderboard
• Combo system with juicy feedback, haptics, and glow effects
• Unlockable cube skins (no pay-to-win — cosmetics only)
• Plays in 30–90 second sessions — perfect for the commute

🧩 SIMPLE TO LEARN, HARD TO MASTER
Easy first merge. Deep positioning strategy. How high can you stack your tiers?

No account required. Plays offline. Respects your battery.

Download TiltMerge and feel the satisfying click of cubes merging together!

---
Keywords: puzzle, merge, physics, tilt, casual, offline, 2048, suika, blocks, drop
```

### RU (≤ 4000 символов)

```
TiltMerge — быстрая и приятная физическая головоломка, в которую можно играть одной рукой.

🎯 КАК ИГРАТЬ
• Наклоняй телефон влево и вправо, чтобы катить кубики.
• Когда два кубика одного цвета сталкиваются — они СЛИВАЮТСЯ в кубик побольше.
• Продолжай сливать, чтобы подниматься по уровням, — но не дай коробке переполниться!
• Сливай быстро подряд, чтобы собрать КОМБО и умножить очки.

✨ ОСОБЕННОСТИ
• Уникальное управление наклоном — почувствуй физику в руке
• 3 режима: Классика (бесконечно), Блиц (60 сек), Дзен (расслабляющий)
• Ежедневный вызов — одинаковая раскладка для всех, обгони таблицу лидеров
• Система комбо с сочной отдачей, вибрацией и свечением
• Разблокируемые скины кубиков (без pay-to-win — только косметика)
• Партии по 30–90 секунд — идеально для дороги

🧩 ПРОСТО НАУЧИТЬСЯ, СЛОЖНО ОВЛАДЕТЬ
Первое слияние легко. Глубокая стратегия позиционирования. Как высоко ты заберёшься?

Без регистрации. Играет офлайн. Береги батарею.

Скачай TiltMerge и почувствуй удовлетворяющий клик сливающихся кубиков!
```

---

## 🖼 Графика (подготовить и загрузить)

| Артефакт | Размер | Описание |
|---|---|---|
| App icon | 512×512 PNG | логотип на тёмном фоне |
| Feature graphic | 1024×500 PNG | геймплей + название |
| Phone screenshots | мин. 2, макс. 8 (16:9 или 9:16) | первые 3 — самые важные |
| Promo video | 30 сек, YouTube link | геймплей в первые 3 секунды |

**Скриншоты (концепт-тексты для каждого):**
1. «Tilt to roll» — кубики катятся от наклона
2. «Merge same colors» — два кубика сливаются со спецэффектом
3. «Don't overflow!» — тревожный момент у потолка
4. «Build combos» — шкала комбо ×5
5. «3 game modes» — иконки Classic/Blitz/Zen
6. «Daily Challenge» — таблица лидеров

---

## 🔒 Data Safety form (заполнить в Play Console)

### Data collected
| Тип | Цель | Обязательно? |
|---|---|---|
| App history (best score, settings) | App functionality | Локально, не передаётся |
| Crash logs | Analytics, измерение производительности | Опционально |
| Diagnostics (usage, events) | Analytics | Опционально |
| Device or other IDs | Analytics, реклама | Опционально |

### Data encrypted in transit
✅ Да (через Firebase/Google)

### Users can request data deletion
✅ Да (через email-контакт; локальные данные удаляются с приложением)

### Family-friendly
❌ Нет (общая аудитория, без заявки в Kids)

---

## 🌍 Локализация (локали для загрузки)
- `en-US` (по умолчанию)
- `ru-RU` (полный перевод)
- Будущие: `es`, `pt-BR`, `de`, `ja` (после soft launch по гео-данным)

---

## 🚀 Процесс публикации

1. [ ] Поднять version code в `export_presets.cfg` (обязательно для каждого обновления!)
2. [ ] Собрать **signed release AAB** локально или через CI (tag `v*`)
3. [ ] Загрузить AAB в **Production** (или сначала Internal для финальной проверки)
4. [ ] Заполнить/обновить Store Listing, Data Safety, Content Rating (IARC)
5. [ ] Выбрать **staged rollout**: 10% → 50% → 100% (наблюдать crashlytics 24–72ч)
6. [ ] После 100% — мониторить отзывы, отвечать (влияет на рейтинг)

### Staged rollout — критерии остановки
- Crash-free < 99% → **пауза rollout**
- Средняя оценка < 3.5 в первые 48ч → **пауза**, анализ отзывов
- ANR-rate выше baseline → **пауза**

---

## 📢 Маркетинг (опционально)

- [ ] Reddit: r/AndroidGaming, r/godot, r/indiegaming — пост с геймплеем
- [ ] TikTok / YouTube Shorts — 15 сек геймплея
- [ ] itch.io — бесплатная web-версия для трафика
- [ ] Indie-агрегаторы: IndieDB, TouchArcade forums
- [ ] Press kit в `/store/press/` (логотипы, скриншоты, описание)
