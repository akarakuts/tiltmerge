#!/usr/bin/env bash
# Проверка паритета ключей переводов en / ru.
# Запуск: ./scripts/check_strings_parity.sh
set -euo pipefail
cd "$(dirname "$0")/.."

DIR="translations"
if [[ ! -d "$DIR" ]]; then
  echo "❌ Каталог переводов не найден ($DIR)" >&2
  exit 1
fi

python3 - "$DIR" <<'PY'
import csv, sys, pathlib
tdir = pathlib.Path(sys.argv[1])

def keys(path):
    with open(path, newline="", encoding="utf-8") as fh:
        rows = list(csv.reader(fh))
    if not rows or rows[0][0] != "key":
        print(f"❌ {path}: первая ячейка должна быть 'key'"); sys.exit(1)
    return {r[0] for r in rows[1:] if r}

csvs = sorted(tdir.glob("*.csv"))
if not csvs:
    print("❌ Нет CSV-файлов переводов"); sys.exit(1)
en = tdir / "en.csv"
if not en.exists():
    print("❌ Нет en.csv — базовый перевод"); sys.exit(1)
en_keys = keys(en)
bad = 0
for p in csvs:
    if p == en:
        continue
    k = keys(p)
    only_en = en_keys - k
    only_loc = k - en_keys
    if only_en or only_loc:
        print(f"❌ {p.name}: только в en={sorted(only_en)} только в {p.stem}={sorted(only_loc)}"); bad += 1
if bad:
    sys.exit(1)
print(f"✓ Паритет ключей: {len(en_keys)} ключей совпадают во всех {len(csvs)} переводах")
PY
