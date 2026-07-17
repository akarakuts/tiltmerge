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
"$GODOT" --headless --import

run_scene_test() {
  local scene="$1"
  local filter="$2"
  local output rc save_path
  output="$(mktemp)"
  save_path="user://tiltmerge-test-$$-${RANDOM}.json"
  if "$GODOT" --headless "$scene" -- --save-path="$save_path" --cleanup-save >"$output" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  grep -E "$filter" "$output" || true
  if [ "$rc" -ne 0 ]; then
    cat "$output" >&2
  fi
  rm -f "$output"
  return "$rc"
}

echo ""
echo "### 1. Unit + smoke тесты (TestRunner.tscn)..."
rc1=0
run_scene_test tests/TestRunner.tscn "✓|✗|TOTAL:|FAILED|SCRIPT ERROR|ERROR:" || rc1=$?

echo ""
echo "### 2. Onboarding интерактивный тест..."
rc2=0
run_scene_test tests/OnboardingTest.tscn "✓|✗|PASS|FAIL" || rc2=$?

echo ""
echo "### 3. Gameplay тест (полная симуляция, ~20s)..."
rc3=0
run_scene_test tests/GameplayTest.tscn "\[test\]|PASS|FAIL|RESULTS|GAMEPLAY" || rc3=$?

echo ""
if [ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] && [ "$rc3" -eq 0 ]; then
  echo "✅ Все тесты прошли"
  exit 0
else
  echo "❌ Тесты провалились (test_runner=$rc1 onboarding=$rc2 gameplay=$rc3)"
  exit 1
fi
