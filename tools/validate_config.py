#!/usr/bin/env python3
"""Validate game/config/*.json: parses, required keys, value sanity. Exit 1 on error.
Add keys here when you add them to the config (see docs/03_DATA_SPEC.md)."""
import json
import math
import re
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
    "themes.json": ["default", "geometry", "backdrop", "themes"],
    "background_motion.json": ["shared", "environments"],
    "environment_world.json": ["shared", "environments"],
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



def validate_background_motion(config, errors):
    prefix = "background_motion.json: "
    shared = config.get("shared", {})
    fields = {
        "canvas_size": None, "mask_scale": None, "actor_fade": None,
        "bird_wing_hz": None, "boat_bob": None, "boat_bob_hz": None, "floe_bob_hz": None,
        "steam_puffs": None, "steam_rise": None, "steam_drift": None, "steam_radius": None,
        "fountain_drops": None, "fountain_height": None, "fountain_spread": None,
        "flag_flutter_hz": None, "beacon_period": None,
        "parallax": ["x_per_unit", "y_per_unit", "max_x", "max_y", "far_factor", "near_factor", "follow_rate"],
        "sky": ["amplitude", "angular_speed", "edge_pin"],
        "water": ["uv_amplitude", "speed", "glint_strength", "refraction_frequency", "glint_frequency", "glint_drift", "cross_wave_speed", "glint_sharpness", "cross_wave_bend"],
        "wind": ["amplitude", "speed", "spatial_frequency"],
    }
    def positive(value):
        if isinstance(value, dict):
            return bool(value) and all(positive(v) for v in value.values())
        if isinstance(value, list):
            return len(value) == 2 and all(positive(v) for v in value)
        return isinstance(value, (int, float)) and math.isfinite(value) and value > 0
    for field, children in fields.items():
        value = shared.get(field)
        if not positive(value) or (children and (not isinstance(value, dict) or set(value) != set(children))):
            errors.append(prefix + "missing/invalid shared." + field)
    if not isinstance(shared.get("mask_scale"), (int, float)) or not 0.1 <= shared["mask_scale"] <= 1:
        errors.append(prefix + "mask_scale must be 0.1..1")
    if not isinstance(shared.get("actor_fade"), (int, float)) or not 0 < shared["actor_fade"] < 0.5:
        errors.append(prefix + "actor_fade must be 0..0.5")
    environments = config.get("environments", {})
    if set(environments) != {f"v{i:03}" for i in range(1, 11)}:
        errors.append(prefix + "need motion profiles for v001-v010")
    def points(value, minimum=3, route=False):
        return isinstance(value, list) and len(value) >= minimum and all(
            isinstance(p, list) and len(p) == 2 and all(isinstance(v, (int, float)) and math.isfinite(v) for v in p)
            and (-0.2 if route else 0) <= p[0] <= (1.2 if route else 1) and 0 <= p[1] <= 1 for p in value)
    kinds = {"birds", "sailboat", "ferry", "floe", "car", "steam", "mist", "fountain", "flag", "beacon", "pollen"}
    for theme, profile in environments.items():
        sky = profile.get("sky", [])
        if not points(sky, 2) or sky[0][0] != 0 or sky[-1][0] != 1 or any(a[0] >= b[0] for a, b in zip(sky, sky[1:])):
            errors.append(prefix + theme + " sky must be an ordered horizon from x=0 to x=1")
        for field in ["water", "wind", "water_exclusions"]:
            regions = profile.get(field)
            if not isinstance(regions, list) or (field == "water" and not regions) or any(not points(p) for p in regions):
                errors.append(prefix + theme + " invalid " + field + " polygons")
        actors = profile.get("actors", [])
        if not isinstance(actors, list) or len(actors) < 3:
            errors.append(prefix + theme + " needs at least three live actors")
            continue
        for actor in actors:
            if actor.get("kind") not in kinds or not points([actor.get("start"), actor.get("end")], 2, True):
                errors.append(prefix + theme + " invalid actor kind/route")
            if not positive(actor.get("period")) or not positive(actor.get("size")) or not isinstance(actor.get("phase"), (int, float)) or not 0 <= actor["phase"] < 1:
                errors.append(prefix + theme + " invalid actor timing/size")
            color = actor.get("color", "")
            if not isinstance(color, str) or len(color) != 7 or not color.startswith("#") or any(c not in "0123456789abcdefABCDEF" for c in color[1:]):
                errors.append(prefix + theme + " invalid actor color")


def validate_environment_world(config, errors):
    prefix = "environment_world.json: "
    shared = config.get("shared", {})
    def number(n):
        return isinstance(n, (int, float)) and math.isfinite(n)
    def vec(v, positive=False):
        return isinstance(v, list) and len(v) == 3 and all(number(n) and (n > 0 if positive else True) for n in v)
    required = ["cloud_gap", "cloud_bands", "clouds_per_band", "cloud_depth", "cloud_width", "cloud_speed", "cloud_size", "cloud_projection_bias", "water_size", "water_center", "water_wave_amplitude", "water_wave_speed", "water_glint", "ground_bounds", "river_bounds", "foundation_size", "foundation_y", "boat_bob", "boat_bob_speed", "steam_rise", "steam_drift", "steam_puffs", "steam_radius", "bird_flap_speed", "fountain_drops", "fountain_height", "flag_speed", "flag_amplitude", "sky_height_range", "sky_horizon", "sun_position", "sun_radius", "mesh_sides", "cloud_depth_step", "boat_roll_amplitude", "bird_roll_amplitude", "steam_wobble"]
    for key in required:
        value = shared.get(key)
        if not (number(value) or isinstance(value, list) and value and all(number(n) for n in value)):
            errors.append(prefix + "missing/invalid shared." + key)
    for key in ["cloud_gap", "cloud_bands", "clouds_per_band", "cloud_width", "sky_height_range", "mesh_sides"]:
        if not number(shared.get(key)) or shared[key] <= 0:
            errors.append(prefix + key + " must be positive")
    profiles = config.get("environments", {})
    if set(profiles) != {f"v{i:03}" for i in range(1, 11)}:
        errors.append(prefix + "need ten world environments")
    kinds = {"tree", "pine", "cypress", "mountain", "hill", "karst", "cliff", "snow_island", "ice", "hedge", "flowers", "column", "fountain", "bridge", "cable_bridge", "wall", "fence", "pier", "tank", "stack", "refinery", "harbor_crane", "igloo", "lighthouse", "watchtower", "manor", "office", "palace", "fort", "pagoda", "prison", "cottage"}
    actor_kinds = {"birds", "car", "sailboat", "ferry", "floe", "flag", "fountain", "steam", "beacon"}
    for theme, profile in profiles.items():
        colors = profile.get("colors", {})
        for value in [profile.get("sky_top"), profile.get("sky_bottom")] + list(colors.values()):
            if not isinstance(value, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
                errors.append(prefix + theme + " invalid color")
        if profile.get("water") not in {"river", "sea"}:
            errors.append(prefix + theme + " invalid water layout")
        for feature in profile.get("features", []):
            if feature.get("kind") not in kinds or not vec(feature.get("position")) or not vec(feature.get("size"), True) or not number(feature.get("rotation")):
                errors.append(prefix + theme + " invalid world feature")
        for patch in profile.get("patches", []):
            if patch.get("material") not in colors or not vec(patch.get("lo")) or not vec(patch.get("hi")) or any(a >= b for a, b in zip(patch["lo"], patch["hi"])):
                errors.append(prefix + theme + " invalid world patch")
        for actor in profile.get("actors", []):
            if actor.get("kind") not in actor_kinds or not vec(actor.get("start")) or not vec(actor.get("end")) or not number(actor.get("period")) or actor["period"] <= 0 or not number(actor.get("size")) or actor["size"] <= 0 or not number(actor.get("phase")) or not 0 <= actor["phase"] < 1:
                errors.append(prefix + theme + " invalid world actor")


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
        for key in ["name_key", "description_key", "architecture", "scenery", "palette", "background"]:
            if key not in theme:
                errors.append(f"themes.json: {theme.get('id')} missing {key}")
        if theme.get("architecture") not in architectures or theme.get("scenery") not in sceneries:
            errors.append(f"themes.json: unknown architecture/scenery in {theme.get('id')}")
        if set(theme.get("palette", {})) != palette_keys:
            errors.append(f"themes.json: incomplete palette in {theme.get('id')}")
        background = theme.get("background", {})
        lighting = background.get("lighting", {})
        for key in ["key_color", "ambient_color", "rim_color"]:
            if key not in lighting:
                errors.append(f"themes.json: {theme.get('id')} missing lighting.{key}")
        colors = list(theme.get("palette", {}).values()) + [lighting.get(k, "") for k in ["key_color", "ambient_color", "rim_color"]]
        texture = background.get("texture", "")
        if not texture.startswith("res://assets/backgrounds/") or not texture.endswith(".png") or not (CONFIG.parent / texture.removeprefix("res://")).is_file():
            errors.append(f"themes.json: missing local background texture {texture!r}")
        if background.get("sun_style") not in {"none", "natural_gold"}:
            errors.append(f"themes.json: unsupported sun_style in {theme.get('id')}")
        if not background.get("reference", "").endswith(".png"):
            errors.append(f"themes.json: missing reference provenance in {theme.get('id')}")
        for key in ["key_position", "rim_position"]:
            values = lighting.get(key, [])
            if not isinstance(values, list) or len(values) != 3 or any(not isinstance(v, (int, float)) for v in values) or values == [0, 0, 0]:
                errors.append(f"themes.json: lighting.{key} must be a nonzero 3D vector")
        for key in ["key_energy", "ambient_energy", "rim_energy", "window_glow"]:
            if not isinstance(lighting.get(key), (int, float)) or lighting[key] < 0:
                errors.append(f"themes.json: invalid lighting.{key} in {theme.get('id')}")
        for color in colors:
            if not isinstance(color, str) or len(color) != 7 or not color.startswith("#") or any(c not in "0123456789abcdefABCDEF" for c in color[1:]):
                errors.append(f"themes.json: invalid hex color {color!r}")
        if set(theme) - {"id", "name_key", "description_key", "architecture", "scenery", "palette", "background"}:
            errors.append("themes.json: themes may contain presentation fields only")
    geometry = themes.get("geometry", {})
    for key in ["half_width", "round_radius", "round_sides", "cornice_width", "roof_height", "window_columns", "rope_width", "sling_height"]:
        value = geometry.get(key)
        if not isinstance(value, (int, float)) or value <= 0:
            errors.append(f"themes.json: geometry.{key} must be positive")
    if not isinstance(geometry.get("yaw_degrees"), (int, float)):
        errors.append("themes.json: geometry.yaw_degrees must be numeric")
    backdrop = themes.get("backdrop", {})
    if not isinstance(backdrop.get("overscan"), (int, float)) or not 1 <= backdrop["overscan"] <= 1.1:
        errors.append("themes.json: backdrop.overscan must be 1..1.1")
    if not isinstance(backdrop.get("distance"), (int, float)) or not 0 < backdrop["distance"] < 255:
        errors.append("themes.json: backdrop.distance must fit inside the camera far plane")
    for key, value in data.get("round_hud.json", {}).items():
        if not key.startswith("_") and (not isinstance(value, (int, float)) or value <= 0):
            errors.append(f"round_hud.json: {key} must be positive")
    validate_background_motion(data.get("background_motion.json", {}), errors)
    validate_environment_world(data.get("environment_world.json", {}), errors)
    for e in errors:
        print("config error:", e)
    print("config: OK" if not errors else f"config: {len(errors)} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
