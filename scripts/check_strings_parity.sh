#!/usr/bin/env bash
# Проверка паритета ключей переводов en / ru.
# Запуск: ./scripts/check_strings_parity.sh
set -euo pipefail
cd "$(dirname "$0")/.."

EN="translations/en.csv"
RU="translations/ru.csv"

if [[ ! -f "$EN" || ! -f "$RU" ]]; then
  echo "❌ Не найдены файлы переводов ($EN / $RU)" >&2
  exit 1
fi

python3 - "$EN" "$RU" <<'PY'
import csv, sys
en, ru = sys.argv[1], sys.argv[2]

def keys(path):
    with open(path, newline="", encoding="utf-8") as fh:
        rows = list(csv.reader(fh))
    if not rows or rows[0][0] != "key":
        print(f"❌ {path}: первая ячейка должна быть 'key'"); sys.exit(1)
    return {r[0] for r in rows[1:] if r}

en_keys, ru_keys = keys(en), keys(ru)
only_en = en_keys - ru_keys
only_ru = ru_keys - en_keys
if only_en:
    print(f"❌ Есть в en, нет в ru: {sorted(only_en)}"); sys.exit(1)
if only_ru:
    print(f"❌ Есть в ru, нет в en: {sorted(only_ru)}"); sys.exit(1)
print(f"✓ Паритет ключей: {len(en_keys)} совпадают (en/ru)")
PY
