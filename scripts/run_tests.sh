#!/usr/bin/env bash
# Локальный runner тестов TiltMerge.
# Запуск: ./scripts/run_tests.sh
# Требует Godot 4.3 в PATH (или GODOT env var).
set -euo pipefail

GODOT="${GODOT:-godot}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "❌ Godot не найден. Установите: brew install --cask godot  (или задайте GODOT=/path/to/godot)"
  exit 1
fi

echo "### 1. Unit-тесты (test_config.gd)"
"$GODOT" --headless --script tests/test_config.gd
unit_rc=$?

echo ""
echo "### 2. Smoke-тест (smoke_test.gd)"
"$GODOT" --headless --script tests/smoke_test.gd
smoke_rc=$?

echo ""
if [ "$unit_rc" -eq 0 ] && [ "$smoke_rc" -eq 0 ]; then
  echo "✅ Все тесты прошли"
  exit 0
else
  echo "❌ Тесты провалились (unit=$unit_rc smoke=$smoke_rc)"
  exit 1
fi
