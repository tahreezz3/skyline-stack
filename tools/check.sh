#!/usr/bin/env bash
# Full project check. Run before marking any task done. Exit code 0 = all green.
# Steps: config validation, rule tests, autoplay smoke test, clean-room check, dashboard.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
ok_all=1
steps_json=""

run_step() {   # name, command...
  local name="$1"; shift
  echo "== $name"
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  echo "$out" | grep -vE '^Godot Engine|^\s*$' | tail -20
  if [ "$name" = "smoke" ] && echo "$out" | grep -qE 'SCRIPT ERROR|Parse Error'; then rc=1; fi
  if [ "$name" = "smoke" ] && ! echo "$out" | grep -qE 'AUTOPLAY_(SUMMARY|TIMEOUT)'; then rc=1; fi
  local v=true; [ $rc -ne 0 ] && { v=false; ok_all=0; echo "!! $name FAILED"; }
  steps_json="${steps_json}\"$name\": $v, "
}

command -v "$GODOT" >/dev/null || { echo "Godot not found (set GODOT=/path/to/godot or brew install --cask godot)"; exit 2; }

run_step config  python3 tools/validate_config.py
"$GODOT" --headless --path game --import >/dev/null 2>&1
run_step tests   "$GODOT" --headless --path game --script res://tests/run_tests.gd
run_step smoke   "$GODOT" --headless --path game -- --autoplay --seconds=90
run_step cleanroom python3 tools/cleanroom_check.py

ok_json=$([ $ok_all -eq 1 ] && echo true || echo false)
printf '{"time": "%s", "ok": %s, "steps": {%s}}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$ok_json" "${steps_json%, }" > coordination/.last_check.json
python3 tools/dashboard.py

if [ $ok_all -eq 1 ]; then echo "ALL CHECKS PASSED"; else echo "SOME CHECKS FAILED"; exit 1; fi
