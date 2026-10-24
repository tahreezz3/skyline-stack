#!/usr/bin/env python3
"""Validate game/config/*.json: parses, required keys, value sanity. Exit 1 on error.
Add keys here when you add them to the config (see docs/03_DATA_SPEC.md)."""
import json
import sys
from pathlib import Path

CONFIG = Path(__file__).resolve().parent.parent / "game" / "config"

REQUIRED = {
    "tower_rules.json": [
        "snap_window", "max_offset", "miss_offset", "first_block_zone", "stable_offset", "collapse_interval_s", "residents_max",
        "wobble_window", "wobble_gain", "lives", "collapse_costs_life", "fall_kill_depth",
        "block.width", "block.height",
        "combo.bar_seconds", "combo.drain_base", "combo.drain_extra", "combo.drain_full_at",
        "combo.height_step", "combo.bonus_factor", "combo.count_cap", "combo.height_mult_cap",
        "crane.amplitude", "crane.speed", "crane.speed_per_block", "crane.speed_max", "crane.gap_blocks", "crane.gravity", "crane.follow_speed",
        "sway.speed", "sway.scale", "sway.max",
    ],
    "block_types.json": ["types"],
    "themes.json": ["default", "geometry", "scenery_layout", "themes"],
    "round_hud.json": ["margin", "heart_pixel", "heart_spacing", "meter_width", "meter_height", "meter_segments", "badge_height", "bottom_clearance", "endless_page_floors", "counter_digits", "population_font_size", "pause_size", "combo_width", "combo_height"],
    "levels.json": ["levels"],
    "city_map.json": ["width", "height", "disabled", "rules"],
    "economy.json": ["interstitial.min_rounds_before_first", "interstitial.every_n_rounds", "interstitial.min_seconds_between",
                     "rewarded.continue_per_round", "rewarded.continue_lives", "rewarded.double_reward_multiplier"],
    "feel.json": [
        "view",
        "shake.land", "shake.land_sloppy", "shake.frequency", "shake.perfect", "shake.collapse_per_block", "shake.miss", "shake.max", "shake.decay",
        "camera_kick.perfect", "camera_kick.decay", "squash.amount", "squash.time",
        "particles.dust_count", "particles.dust_life", "particles.sparkle_count", "particles.sparkle_life",
        "combo_bar.pulse_hz", "combo_bar.warn_below",
        "audio.perfect_pitch_step", "audio.perfect_pitch_max_steps", "audio.combo_tick_pitch_min", "audio.combo_tick_pitch_max",
    ],
}
BLOCK_KEYS = ["id", "name_key", "colour", "accent", "target_height", "roof_people", "star_population", "star_roof_people", "unlock_population"]


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
    prev = -1
    for level in lv.get("levels", []):
        if "level" not in level or "population" not in level:
            errors.append(f"levels.json: entry missing level/population: {level}")
        elif level["population"] <= prev:
            errors.append("levels.json: population thresholds must strictly increase")
        else:
            prev = level["population"]
    themes = data.get("themes.json", {})
    entries = themes.get("themes", [])
    theme_ids = [t.get("id") for t in entries]
    if theme_ids != [f"v{i:03}" for i in range(1, 11)]:
        errors.append("themes.json: need unique ordered themes v001-v010")
    if themes.get("default") not in theme_ids:
        errors.append("themes.json: default theme must exist")
    architectures = {"classical", "glass", "pagoda", "palace", "fort", "ice", "prison", "office", "factory", "lighthouse"}
    sceneries = {"garden", "skyline", "river", "courtyard", "fortress", "arctic", "compound", "campus", "harbor", "coast"}
    palette_keys = {"body", "shadow", "trim", "glass", "accent", "gold"}
    for theme in entries:
        for key in ["name_key", "description_key", "architecture", "scenery", "palette", "sky_top", "sky_bottom", "landscape"]:
            if key not in theme:
                errors.append(f"themes.json: {theme.get('id')} missing {key}")
        if theme.get("architecture") not in architectures or theme.get("scenery") not in sceneries:
            errors.append(f"themes.json: unknown architecture/scenery in {theme.get('id')}")
        if set(theme.get("palette", {})) != palette_keys:
            errors.append(f"themes.json: incomplete palette in {theme.get('id')}")
        colors = list(theme.get("palette", {}).values()) + [theme.get(k, "") for k in ["sky_top", "sky_bottom", "landscape"]]
        for color in colors:
            if not isinstance(color, str) or len(color) != 7 or not color.startswith("#") or any(c not in "0123456789abcdefABCDEF" for c in color[1:]):
                errors.append(f"themes.json: invalid hex color {color!r}")
        if set(theme) - {"id", "name_key", "description_key", "architecture", "scenery", "palette", "sky_top", "sky_bottom", "landscape"}:
            errors.append("themes.json: themes may contain presentation fields only")
    geometry = themes.get("geometry", {})
    for key in ["half_width", "round_radius", "round_sides", "cornice_width", "roof_height", "window_columns", "rope_width", "sling_height"]:
        value = geometry.get(key)
        if not isinstance(value, (int, float)) or value <= 0:
            errors.append(f"themes.json: geometry.{key} must be positive")
    if not isinstance(geometry.get("yaw_degrees"), (int, float)):
        errors.append("themes.json: geometry.yaw_degrees must be numeric")
    layout = themes.get("scenery_layout", {})
    for key in ["row_depths", "row_scales", "row_parallax", "row_horizons", "haze"]:
        values = layout.get(key, [])
        if not isinstance(values, list) or len(values) != 3 or any(not isinstance(v, (int, float)) for v in values):
            errors.append(f"themes.json: scenery_layout.{key} needs three numeric entries")
    for key in ["row_extent", "row_spacing"]:
        if not isinstance(layout.get(key), (int, float)) or layout[key] <= 0:
            errors.append(f"themes.json: scenery_layout.{key} must be positive")
    counts = layout.get("floor_counts", [])
    if not counts or any(not isinstance(v, int) or v < 1 for v in counts):
        errors.append("themes.json: scenery floor counts must be positive integers")
    for key, value in data.get("round_hud.json", {}).items():
        if not key.startswith("_") and (not isinstance(value, (int, float)) or value <= 0):
            errors.append(f"round_hud.json: {key} must be positive")
    for e in errors:
        print("config error:", e)
    print("config: OK" if not errors else f"config: {len(errors)} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
