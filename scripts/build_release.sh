#!/usr/bin/env bash
# Сборка подписанного релизного Android App Bundle в локальный каталог.
# Путь назначения берётся из файла store-upload.dir (см. store-upload.dir.example).
# Запуск: ./scripts/build_release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
DEST_FILE="store-upload.dir"

if [[ ! -f "$DEST_FILE" ]]; then
  echo "❌ Нет файла $DEST_FILE. Создай по образцу store-upload.dir.example." >&2
  exit 1
fi

DEST_DIR="$(head -1 "$DEST_FILE" | tr -d '[:space:]')"
if [[ -z "$DEST_DIR" ]]; then
  echo "❌ Пустой путь в $DEST_FILE" >&2
  exit 1
fi

if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "❌ Godot не найден в PATH (или задай GODOT=/path/to/godot)" >&2
  exit 1
fi

mkdir -p build "$DEST_DIR"
VERSION="$(grep '^config/version=' project.godot | cut -d'"' -f2)"
TAG="v${VERSION:-0.0.0}"

echo "==> Импорт проекта..."
"$GODOT" --headless --import

echo "==> Сборка подписанного Android App Bundle ($TAG)..."
"$GODOT" --headless --export-release "Android Release" "build/tiltmerge-${TAG}.aab"

echo "==> Копирование в $DEST_DIR..."
cp "build/tiltmerge-${TAG}.aab" "$DEST_DIR/"
ls -la "$DEST_DIR"/tiltmerge-*.aab

echo "✓ Готово: $DEST_DIR/tiltmerge-${TAG}.aab"
