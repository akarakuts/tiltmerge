# 🚀 Soft Launch Guide — TiltMerge

> Фаза 8. Код аналитики и A/B-тестов готов; публикация и сбор метрик выполняются вручную.

---

## ✅ Что уже реализовано в коде

| Артефакт | Назначение |
|---|---|
| `scripts/Analytics.gd` | Опциональная обёртка аналитики: game_start/game_over/merge/daily/skin |
| `scripts/ABTest.gd` | A/B-флаги с детерминированным распределением когорт |
| `data/ab_config.json` | Флаги: spawn_speed (normal/fast), onboarding_style |
| `GameManager.gd` | Analytics-вызовы встроены в start_game/end_game (с duration) |
| `project.godot` | Analytics + ABTest autoloads |

## 🔧 Что нужно сделать вручную

### 1. Опционально подключить Firebase
- [ ] Создать проект в [Firebase Console](https://console.firebase.google.com)
- [ ] Добавить Android-приложение: `com.akarakuts.tiltmerge`
- [ ] Скачать `google-services.json` → НЕ коммитить (в .gitignore)
- [ ] Интегрировать [GodotFirebase](https://github.com/GodotNuts/GodotFirebase) плагин
- [ ] Включить **Google Analytics** и **Crashlytics**

### 2. Настроить A/B-эксперименты
- [ ] Проверить `data/ab_config.json` (веса когорт)
- [ ] В Firebase Remote Config / A/B Testing — повторить те же флаги

### 3. Публикация в Internal/Closed Testing
- [ ] Загрузить signed AAB в Play Console → **Closed Testing → Alpha/Beta**
- [ ] Выбрать страны soft launch: Филиппины, Бразилия, Индонезия (дешёвая CPI)
- [ ] Пригласить 100–500 тестировщиков

### 4. Метрики для отслеживания (цели)

| Метрика | Цель | Где смотреть |
|---|---|---|
| Retention D1 | ≥ 40–45% | Firebase Analytics → Retention |
| Retention D7 | ≥ 12–15% | Firebase Analytics → Retention |
| Средняя сессия | ≥ 4–5 мин | Firebase → Engagement |
| Crash-free | ≥ 99.5% | Crashlytics |
| Время до game over | 30–60 сек | кастомное событие game_over.duration_sec |
| Drop-off точка | — | funnels: menu→play→first_merge→game_over |

### 5. Решение по итогам
- Метрики ≥ цели → **переходим к Phase 9 (Global Release)**
- Retention D1 < 35% → **возврат**: правка core loop (Phase 2/3), итерация баланса `data/config.json`
- Crashlytics красный → фикс до релиза

---

## 📊 События аналитики (для дашборда)

```
game_start     {mode, control}
game_over      {score, mode, merges, max_tier, duration_sec}
merge          {new_tier, combo}
daily_played   {streak}
skin_selected  {skin}
```

A/B-когорта пользователя читается через `ABTest.get("spawn_speed")` и должна быть отправлена как **user property** в Firebase.

---

## ⏱ Таймлайн soft launch
- **Неделя 1:** публикация, мониторинг крашей, быстрые фиксы
- **Неделя 2:** сбор retention D1/D7
- **Неделя 3–4:** A/B-тесты, калибровка баланса по данным
- **Ворот:** метрики в цели → global release
