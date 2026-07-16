#!/usr/bin/env bash
# Локальный runner тестов TiltMerge.
# Запуск: ./scripts/run_tests.sh
# Требует Godot 4.3+ в PATH (или GODOT env var).
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
echo "### 1. Unit + smoke тесты (TestRunner.tscn)..."
"$GODOT" --headless tests/TestRunner.tscn 2>&1 | grep -E "✓|✗|TOTAL:|FAILED|SCRIPT ERROR|ERROR:" || true
rc1=$?

echo ""
echo "### 2. Onboarding интерактивный тест..."
"$GODOT" --headless tests/OnboardingTest.tscn 2>&1 | grep -E "✓|✗|PASS|FAIL" || true
rc2=$?

echo ""
echo "### 3. Gameplay тест (полная симуляция, ~45s)..."
"$GODOT" --headless tests/GameplayTest.tscn 2>&1 | grep -E "\[test\]|PASS|FAIL|RESULTS|GAMEPLAY" || true
rc3=$?

echo ""
if [ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] && [ "$rc3" -eq 0 ]; then
  echo "✅ Все тесты прошли"
  exit 0
else
  echo "❌ Тесты провалились (test_runner=$rc1 onboarding=$rc2 gameplay=$rc3)"
  exit 1
fi
