#!/usr/bin/env bash
# Скриншоты TiltMerge для RuStore: 1080×1920, портрет.
# Координаты учитывают letterbox Godot keep-aspect на 1080×2400 (offset Y=240, scale=1.5).
set -euo pipefail
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUSTORE="${RUSTORE_DIR:-/Users/a.karakuts/Documents/Bars/rustore/tiltmerge}"
OUT="${PROJ}/docs/store-screenshots/store_1080x1920"
READY="${RUSTORE}/rustore-upload-ready/screenshots"
PKG="com.akarakuts.tiltmerge"
# Debug/shots APK — нужен run-as для skip onboarding
APK="${SHOTS_APK:-$PROJ/build/tiltmerge-shots.apk}"
[[ -f "$APK" ]] || APK="$PROJ/build/tiltmerge-debug.apk"
SHOT_W=1080
SHOT_H=1920
STRIP_TOP="${STRIP_STATUS_TOP_PX:-80}"

# Godot 720×1280 keep → 1080×2400: scale 1.5, letterbox top/bottom 240px
tap_content() {
  local cx="$1" cy="$2"
  local sx sy
  sx=$(python3 -c "print(int(round($cx * 1.5)))")
  sy=$(python3 -c "print(int(round($cy * 1.5 + 240)))")
  adb shell input tap "$sx" "$sy"
}

mkdir -p "$OUT" "$READY"

ensure_device() {
  if adb devices | rg -q 'emulator-.*device'; then
    return 0
  fi
  echo "==> Starting emulator Medium_Phone (headless)"
  nohup "$ANDROID_HOME/emulator/emulator" -avd Medium_Phone -no-window -no-snapshot-load \
    -no-snapshot-save -gpu swiftshader_indirect -no-audio -no-boot-anim \
    >/tmp/tiltmerge-rustore-emu.log 2>&1 &
  for i in $(seq 1 90); do
    if adb devices 2>/dev/null | rg -q 'emulator-.*device'; then
      boot=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
      [[ "$boot" == "1" ]] && return 0
    fi
    sleep 3
  done
  echo "emulator boot timeout" >&2
  exit 1
}

cap_raw() {
  local out="$1"
  adb shell input keyevent 224 2>/dev/null || true
  sleep 0.3
  adb shell screencap -p /sdcard/_tm_cap.png
  adb pull /sdcard/_tm_cap.png "$out" >/dev/null
  adb shell rm -f /sdcard/_tm_cap.png 2>/dev/null || true
}

to_store() {
  local src="$1" dst="$2"
  if command -v ffmpeg >/dev/null 2>&1; then
    local w h nh
    w=$(sips -g pixelWidth "$src" 2>/dev/null | awk '/pixelWidth/ {print $2}')
    h=$(sips -g pixelHeight "$src" 2>/dev/null | awk '/pixelHeight/ {print $2}')
    nh=$((h - STRIP_TOP))
    if [[ -n "$w" && "$nh" -gt 100 ]]; then
      ffmpeg -y -nostdin -hide_banner -loglevel error -i "$src" \
        -vf "crop=${w}:${nh}:0:${STRIP_TOP},scale=${SHOT_W}:${SHOT_H}:force_original_aspect_ratio=increase,crop=${SHOT_W}:${SHOT_H}:(iw-${SHOT_W})/2:(ih-${SHOT_H})/2" \
        -frames:v 1 "$dst"
      return
    fi
  fi
  sips -z "$SHOT_H" "$SHOT_W" "$src" --out "$dst" >/dev/null
}

seed_save() {
  # Skip onboarding + RU + swipe (для геймплея без наклона эмулятора)
  python3 - <<'PY'
import json, subprocess
try:
    raw = subprocess.check_output(
        ["adb", "shell", "run-as", "com.akarakuts.tiltmerge", "cat", "files/save.json"],
        text=True, stderr=subprocess.DEVNULL)
    data = json.loads(raw)
except Exception:
    data = {"version": 1, "settings": {}, "best_score": {}}
data["onboarding_completed"] = True
data.setdefault("settings", {})
data["settings"]["language"] = "ru"
data["settings"]["control_mode"] = "swipe"
data.setdefault("best_score", {})
if float(data["best_score"].get("classic", 0) or 0) < 120:
    data["best_score"]["classic"] = 240
with open("/tmp/tm-save-seed.json", "w") as f:
    json.dump(data, f, ensure_ascii=False)
PY
  adb push /tmp/tm-save-seed.json /data/local/tmp/save.json >/dev/null
  adb shell run-as "$PKG" cp /data/local/tmp/save.json files/save.json
}

ensure_device
[[ -f "$APK" ]] || { echo "Нет APK: $APK" >&2; exit 1; }

echo "==> Install $APK"
adb install -r "$APK"
seed_save

adb shell am force-stop "$PKG"
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 3.5

# 01 — главное меню
cap_raw "$OUT/_raw_01.png"
to_store "$OUT/_raw_01.png" "$OUT/01_ru_main_menu.png"
echo "✓ 01_ru_main_menu"

# Play (content ~350) → режимы
tap_content 360 350
sleep 1.2
cap_raw "$OUT/_raw_02.png"
to_store "$OUT/_raw_02.png" "$OUT/02_ru_modes.png"
echo "✓ 02_ru_modes"

# Classic (content ~340 при открытых режимах)
tap_content 360 340
sleep 2.5
# свайпы, чтобы кубики сдвинулись
for _ in 1 2 3 4; do
  adb shell input swipe 200 1400 880 1400 350
  sleep 1.2
  adb shell input swipe 880 1400 200 1400 350
  sleep 1.2
done
cap_raw "$OUT/_raw_03.png"
to_store "$OUT/_raw_03.png" "$OUT/03_ru_gameplay.png"
echo "✓ 03_ru_gameplay"

sleep 2
adb shell input swipe 250 1500 850 1500 300
sleep 2
cap_raw "$OUT/_raw_04.png"
to_store "$OUT/_raw_04.png" "$OUT/04_ru_gameplay_mid.png"
echo "✓ 04_ru_gameplay_mid"

# Назад в меню
adb shell input keyevent 4
sleep 1.5
# если пауза — ещё раз
adb shell input keyevent 4
sleep 1.5
# заново в меню (на случай выхода в систему)
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 2
seed_save
adb shell am force-stop "$PKG"
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 3

# Скины с главного меню (screen Y≈1089 на 1080×2400)
adb shell input tap 540 1089
sleep 2
cap_raw "$OUT/_raw_05.png"
to_store "$OUT/_raw_05.png" "$OUT/05_ru_skins.png"
echo "✓ 05_ru_skins"

rm -f "$OUT"/_raw_*.png "$OUT"/*.tmp.png 2>/dev/null || true
# убрать мусорные копии Finder
find "$OUT" "$READY" -name '* 2.png' -delete 2>/dev/null || true
mkdir -p "$READY"
cp -f "$OUT"/0*.png "$READY/"
ls -lh "$OUT"/*.png "$READY"/*.png
echo "OK screenshots → $READY"
