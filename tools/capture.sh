#!/usr/bin/env bash
# Capture game frames at full resolution (720x1280) so agents can look at the visuals.
#   tools/capture.sh <out_dir> [frames] [-- game args...]
#   tools/capture.sh /tmp/shots 420 -- --autoplay
#   tools/capture.sh /tmp/tour 140 -- --tour
# Uses a temporary game/override.cfg (Godot reads it next to project.godot); removed afterwards.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:?out dir}"; FRAMES="${2:-300}"; shift 2 || true
[ "${1:-}" = "--" ] && shift
mkdir -p "$OUT"; rm -f "$OUT"/f*.png
cat > game/override.cfg <<CFG
[display]
window/size/window_width_override=720
window/size/window_height_override=1280
CFG
trap 'rm -f game/override.cfg' EXIT
perl -e 'alarm 300; exec @ARGV' "${GODOT:-godot}" --path game --write-movie "$OUT/f.png" --fixed-fps 30 --quit-after "$FRAMES" -- "$@" 2>&1 | grep -E "SCRIPT ERROR|Parse Error" || true
ls "$OUT"/f*.png | wc -l | xargs echo "frames:"
