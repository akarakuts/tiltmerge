#!/usr/bin/env bash
# Локальный runner тестов TiltMerge.
# Запуск: ./scripts/run_tests.sh
# Требует Godot 4.3+ в PATH (или GODOT env var).
#
# Тесты используют сцену tests/TestRunner.tscn (autoload-синглтоны инициализируются
# при загрузке сцены, в отличие от режима --script).
set -euo pipefail

GODOT="${GODOT:-godot}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "❌ Godot не найден. Установите: brew install --cask godot  (или задайте GODOT=/path/to/godot)"
  exit 1
fi

echo "### Импорт проекта..."
"$GODOT" --headless --import 2>&1 | grep -iE "error|failed" || true

echo ""
echo "### Тесты (unit + smoke) через TestRunner.tscn..."
"$GODOT" --headless tests/TestRunner.tscn 2>&1 | grep -E "✓|✗|TOTAL:|FAILED|SCRIPT ERROR|ERROR:"
rc=${PIPESTATUS[0]}

echo ""
if [ "$rc" -eq 0 ]; then
  echo "✅ Все тесты прошли"
  exit 0
else
  echo "❌ Тесты провалились (exit=$rc)"
  exit "$rc"
fi
