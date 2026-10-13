#!/usr/bin/env python3
"""Validate game/config/*.json: parses, required keys, value sanity. Exit 1 on error.
Add keys here when you add them to the config (see docs/03_DATA_SPEC.md)."""
import json
import sys
from pathlib import Path

CONFIG = Path(__file__).resolve().parent.parent / "game" / "config"

REQUIRED = {
    "tower_rules.json": [
        "snap_window", "max_offset", "miss_offset", "stable_offset", "collapse_interval_s", "residents_max",
        "wobble_window", "wobble_gain", "lives", "fall_kill_depth",
        "block.width", "block.height",
        "combo.bar_seconds", "combo.drain_base", "combo.drain_extra", "combo.drain_full_at",
        "combo.height_step", "combo.bonus_factor",
        "crane.amplitude", "crane.speed", "crane.speed_per_block", "crane.speed_max", "crane.gap_blocks", "crane.gravity",
        "sway.speed", "sway.scale", "sway.max",
    ],
    "block_types.json": ["types"],
    "levels.json": ["levels"],
}
BLOCK_KEYS = ["id", "name_key", "colour", "target_height", "roof_people", "star_population", "star_roof_people", "unlock_population"]


def get(d, dotted):
    for part in dotted.split("."):
        if not isinstance(d, dict) or part not in d:
            raise KeyError(dotted)
        d = d[part]
    return d


def main() -> int:
    errors = []
    data = {}
    for name, keys in REQUIRED.items():
        path = CONFIG / name
        try:
            data[name] = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"{name}: {exc}")
            continue
        for k in keys:
            try:
                get(data[name], k)
            except KeyError:
                errors.append(f"{name}: missing key '{k}'")
    r = data.get("tower_rules.json")
    if r and not errors:
        if not (r["snap_window"] < r["stable_offset"] < r["max_offset"] < r["miss_offset"]):
            errors.append("tower_rules.json: need snap_window < stable_offset < max_offset < miss_offset")
        if r["lives"] < 1 or r["residents_max"] < 1 or r["wobble_window"] < 1:
            errors.append("tower_rules.json: lives, residents_max, wobble_window must be >= 1")
    b = data.get("block_types.json")
    if b:
        ids = set()
        for t in b.get("types", []):
            for k in BLOCK_KEYS:
                if k not in t:
                    errors.append(f"block_types.json: type {t.get('id', '?')} missing '{k}'")
            ids.add(t.get("id"))
        lv = data.get("levels.json", {})
        for level in lv.get("levels", []):
            for u in level.get("unlocks", []):
                if u not in ids:
                    errors.append(f"levels.json: level {level.get('level')} unlocks unknown type '{u}'")
    for e in errors:
        print("config error:", e)
    print("config: OK" if not errors else f"config: {len(errors)} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
