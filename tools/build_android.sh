#!/usr/bin/env bash
# Build an Android APK from the command line. See docs/BUILD_ANDROID.md.
#   tools/build_android.sh            -> game/build/skyline-stack-debug.apk (debug-signed, for testing)
#   tools/build_android.sh install    -> also installs on a USB-connected phone via adb
# Release builds (signed AAB) arrive in T-0601 and need the keystore from HR-0014.
set -euo pipefail
cd "$(dirname "$0")/.."

JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
DEBUG_KEYSTORE="${DEBUG_KEYSTORE:-$HOME/.android/debug.keystore}"
GODOT="${GODOT:-godot}"
export JAVA_HOME ANDROID_HOME
export PATH="$JAVA_HOME/bin:$PATH"
SETTINGS="$HOME/Library/Application Support/Godot/editor_settings-4.7.tres"

for p in "$JAVA_HOME/bin/java" "$ANDROID_HOME/build-tools" "$DEBUG_KEYSTORE"; do
  [ -e "$p" ] || { echo "missing: $p (see docs/BUILD_ANDROID.md 'One-time setup')"; exit 2; }
done
[ -f "$SETTINGS" ] || "$GODOT" --headless --path game --quit >/dev/null 2>&1 || true

# Point Godot's editor settings at the SDK, JDK and debug keystore (local machine settings, not in the repo).
python3 - "$SETTINGS" "$JAVA_HOME" "$ANDROID_HOME" "$DEBUG_KEYSTORE" <<'PY'
import re, sys
path, java, sdk, ks = sys.argv[1:]
s = open(path).read()
def put(key, val):
    global s
    line = f'{key} = "{val}"'
    if re.search(rf'^{re.escape(key)} = .*$', s, re.M):
        s = re.sub(rf'^{re.escape(key)} = .*$', line.replace('\\', '\\\\'), s, flags=re.M)
    else:
        s = s.rstrip("\n") + "\n" + line + "\n"
put("export/android/java_sdk_path", java)
put("export/android/android_sdk_path", sdk)
put("export/android/debug_keystore", ks)
put("export/android/debug_keystore_user", "androiddebugkey")
put("export/android/debug_keystore_pass", "android")
open(path, "w").write(s)
PY

mkdir -p game/build
"$GODOT" --headless --path game --import >/dev/null 2>&1 || true
rm -f game/build/skyline-stack-debug.apk
"$GODOT" --headless --path game --export-debug "Android Debug" build/skyline-stack-debug.apk 2>&1 \
  | grep -vE '^\s*$|^Godot Engine|^ADDING:|cannot connect to daemon' | tail -8
APK=game/build/skyline-stack-debug.apk
[ -f "$APK" ] || { echo "BUILD FAILED: no APK"; exit 1; }
echo "APK: $APK ($(du -h "$APK" | cut -f1))"
"$ANDROID_HOME/build-tools/"*/apksigner verify --print-certs "$APK" | head -3

if [ "${1:-}" = "install" ]; then
  "$ANDROID_HOME/platform-tools/adb" install -r "$APK"
fi
