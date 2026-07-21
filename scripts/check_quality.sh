#!/usr/bin/env bash
# Единый локальный и CI quality gate. Требует Godot 4.3+ и зависимости
# из requirements-dev.txt (python3 -m pip install -r requirements-dev.txt).
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v gdlint >/dev/null 2>&1; then
  echo "❌ gdlint не найден. Установи: python3 -m pip install -r requirements-dev.txt" >&2
  exit 1
fi

echo "### GDScript lint..."
find scripts tests -name '*.gd' -print0 | xargs -0 gdlint

echo "### Release configuration..."
python3 scripts/validate_release.py

echo "### Translation parity..."
./scripts/check_strings_parity.sh

echo "### Godot tests..."
./scripts/run_tests.sh

echo "✅ Quality gate passed"
