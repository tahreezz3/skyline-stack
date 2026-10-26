# HUMAN_NEEDED: requests for people

Everything the project needs from a human lives here: art, audio, music, fonts,
decisions, accounts and legal items. Agents keep working with placeholders and
never wait in chat for these.

**For humans:** pick an open request, make the thing to the spec, and save it with
**exactly** the file name shown in the `files:` line. The dashboard notices the file
and marks the request *delivered*. Then change `status` to `delivered` and add a note
if anything differs from the spec. For decisions, write your answer under the entry
and set `status: answered`.

**For agents:** add new requests at the bottom with the next free number. Keep this format,
because `tools/dashboard.py` parses it:

```
### HR-XXXX · Short title
- status: open            (open | in-progress | delivered | answered | accepted | wontdo)
- type: art | audio | music | font | design | decision | account | legal | playtest | store
- priority: P0 | P1 | P2  (P0 blocks current milestone)
- needed_for: T-XXXX, milestone
- files: `assets_inbox/...`, `assets_inbox/...`      (omit for decisions)
- requested: YYYY-MM-DD by <handle>
- spec: one paragraph; sizes, durations, formats, mood, references
```

General specs (unless an entry says otherwise): images PNG with transparency, sRGB, drawn at the
stated size (we scale down, never up). Audio WAV 48 kHz 16-bit mono, peak -1 dBFS, trimmed silence,
no reverb tails cut off. Music OGG Vorbis q6 stereo, seamless loop. Must be original work or
licensed for commercial use; put the licence or "original" in `assets_inbox/LICENSES.md`.
Art direction lives in `docs/06_ART_AUDIO_SPEC.md`.

---

### HR-0001 · Final game name
- status: open
- type: decision
- priority: P1
- needed_for: T-0603, M6
- requested: 2026-10-13 by opus55-planner
- spec: "Skyline Stack" is a working title only. Choose the final name. Check it is free on Google Play and the App Store and has no trademark conflict. It must not resemble the reference game's name.

### HR-0002 · Art direction choice
- status: answered
- type: decision
- priority: P0
- needed_for: T-0301, HR-0004..HR-0007, M3
- requested: 2026-10-13 by opus55-planner
- spec: Pick one direction from `docs/06_ART_AUDIO_SPEC.md` section 2 (A: flat pastel vector, B: chunky low-poly look rendered to 2D, C: hand-drawn storybook), or describe your own. Everything visual waits on this.
- answer (owner, 2026-10-19): "Modern simple shapes with good details; an art style that looks 3D, with effects,
  animation and design. The game level itself is 2D and fixed, not rotatable. Details in low-poly simple shapes
  with a good modern aesthetic." Recorded as the **Modern low-poly 2.5D** direction in `docs/06_ART_AUDIO_SPEC.md`
  section 2; rendering approach in `docs/adr/ADR-0006-low-poly-3d-presentation.md`.

### HR-0003 · Approve the unique hook
- status: open
- type: decision
- priority: P1
- needed_for: T-0110, M2
- requested: 2026-10-13 by opus55-planner
- spec: Read the five design briefs in `docs/design/hooks.md` (rules, effort, risks for each) and pick 1–2 to build. Recommendation from T-0110: **H2 special blocks first, then H3 daily skyline**. Write your choice (and any changes) below this entry and set `status: answered`. This is what makes the game stand apart from other stackers and is needed before store submission.

### HR-0004 · Building storey models (4 families × 4 parts, low-poly 3D)
- status: open
- type: art
- priority: P1
- needed_for: T-0301, M3
- files: `assets_inbox/art/blocks/block_blue_floor.glb`, `assets_inbox/art/blocks/block_blue_base.glb`, `assets_inbox/art/blocks/block_blue_roof.glb`, `assets_inbox/art/blocks/block_blue_roof_trophy.glb`, `assets_inbox/art/blocks/block_red_floor.glb`, `assets_inbox/art/blocks/block_red_base.glb`, `assets_inbox/art/blocks/block_red_roof.glb`, `assets_inbox/art/blocks/block_red_roof_trophy.glb`, `assets_inbox/art/blocks/block_green_floor.glb`, `assets_inbox/art/blocks/block_green_base.glb`, `assets_inbox/art/blocks/block_green_roof.glb`, `assets_inbox/art/blocks/block_green_roof_trophy.glb`, `assets_inbox/art/blocks/block_yellow_floor.glb`, `assets_inbox/art/blocks/block_yellow_base.glb`, `assets_inbox/art/blocks/block_yellow_roof.glb`, `assets_inbox/art/blocks/block_yellow_roof_trophy.glb`
- requested: 2026-10-13 by opus55-planner; updated 2026-10-19 for the chosen low-poly 3D direction (HR-0002)
- spec: Low-poly, flat-shaded building parts in the **Modern low-poly 2.5D** style. **Match the owner's reference** `docs/art/references/owner_reference_corner_building.webp` (mood only, don't trace) and the in-game placeholders `docs/art/style_frame_building_detail.png`. floor = repeating storey (siding, pilasters, stepped cornice, mullioned windows, flower pots), base = shop-front ground storey (plinth panels, arched doors, striped awning wrapping the corners), roof = cap with rooftop props, roof_trophy = special cap with emissive accents. Square footprint (core 0.66 × 0.66, cornice ≤ 0.76), 0.6 tall, origin at bottom centre, all four sides detailed (the game turns buildings 38°), ≤ 900 / 1200 / 600 triangles. Material slots: `body`, `body_dark`, `body2`, `wall2`, `trim`, `accent`, `glass`, `pot`, `plant`, `emissive` (the game recolours them per family and lights glass at night). Each family needs a distinct window and roof pattern, not just a colour. Export glTF binary from Blender.

### HR-0005 · Crane hook model
- status: open
- type: art
- priority: P2
- needed_for: T-0105, M3
- files: `assets_inbox/art/crane/crane_hook.glb`
- requested: 2026-10-13 by opus55-planner; updated 2026-10-19 for low-poly 3D
- spec: Low-poly hook and pulley block, ≤ 200 triangles, origin at the attachment point, about 0.25 units wide, materials `trim` and `emissive` (an optional small warning light). The rope is generated by the game.

### HR-0006 · City environment models (street, buildings, cars, props)
- status: open
- type: art
- priority: P1
- needed_for: T-0301, M3
- files: `assets_inbox/art/env/env_street_tile.glb`, `assets_inbox/art/env/env_city_building_a.glb`, `assets_inbox/art/env/env_city_building_b.glb`, `assets_inbox/art/env/env_city_building_c.glb`, `assets_inbox/art/env/env_city_building_d.glb`, `assets_inbox/art/env/env_shopfront_a.glb`, `assets_inbox/art/env/env_shopfront_b.glb`, `assets_inbox/art/env/env_car_a.glb`, `assets_inbox/art/env/env_car_b.glb`, `assets_inbox/art/env/env_car_c.glb`, `assets_inbox/art/env/env_street_light.glb`
- requested: 2026-10-13 by opus55-planner; updated 2026-10-19 for the city setting (T-0309)
- spec: Low-poly, flat-shaded city kit in the same style as the tower, cozy lo-fi palette (`docs/06_ART_AUDIO_SPEC.md` §2.1c). Also wanted (current placeholders in `scripts/game/street_props.gd`, see `docs/art/style_frame_street.png`): `env_street_lamp.glb`, `env_hydrant.glb`, `env_trash_bin.glb`, `env_cafe_sign.glb`, and `assets_inbox/art/env/env_cat.glb` (sitting ginger cat, about 0.17 units tall at game scale, separate nodes `head` and `tail_1..3` for animation), `env_bench.glb`, `env_planter.glb`. See `docs/art/style_frame_day.png` and `docs/art/style_frame_street.png` for the layout the game builds procedurally today. Street tile: 4 units long along x, sidewalk/curb/road/markings, tileable. City buildings: 1–1.7 units wide, 1–7 units tall, front on +Z, window grid, cornice, rooftop prop; materials `body`, `trim`, `glass`, `glass_dark`, `roof`, `accent`; ≤ 1500 tris each. Shop fronts: ground-floor variants with awnings. Cars: about 0.72 long along x, 0.34 wide, front at +x; materials `body`, `glass`, `wheel`, `emissive` (headlights), `tail`; ≤ 400 tris. Street light: about 1.1 tall with an arm over the road (+Z), materials `pole`, `lamp`.
### HR-0007 · Effect look-dev (optional polish)
- status: open
- type: art
- priority: P2
- needed_for: T-0102, M3
- files: `assets_inbox/art/fx/fx_notes.md`
- requested: 2026-10-13 by opus55-planner; updated 2026-10-19
- spec: Effects are now generated in 3D by the game: low-poly shards for dust, gold sparkle shards plus an expanding ring for perfects, tumbling blocks for collapses, glow on emissive parts. An artist or animator should review them in the game and write concrete changes (colours, timings, sizes, extra effects such as confetti for a trophy roof) into `fx_notes.md`. Optional extra meshes go in `assets_inbox/art/fx/` with `fx_` names.

### HR-0008 · Sound effects set
- status: open
- type: audio
- priority: P1
- needed_for: T-0103, T-0302, M3
- files: `assets_inbox/audio/sfx_block_release.wav`, `assets_inbox/audio/sfx_block_land.wav`, `assets_inbox/audio/sfx_block_land_sloppy.wav`, `assets_inbox/audio/sfx_perfect.wav`, `assets_inbox/audio/sfx_combo_start.wav`, `assets_inbox/audio/sfx_combo_tick_loop.wav`, `assets_inbox/audio/sfx_combo_bank.wav`, `assets_inbox/audio/sfx_collapse.wav`, `assets_inbox/audio/sfx_miss_fall.wav`, `assets_inbox/audio/sfx_life_lost.wav`, `assets_inbox/audio/sfx_tower_complete.wav`, `assets_inbox/audio/sfx_ui_tap.wav`
- requested: 2026-10-13 by opus55-planner
- spec: Durations: release 0.3 s (crane clack), land 0.4 s (solid thud), land_sloppy 0.5 s (thud plus creak), perfect 0.6 s (bright chime, pitch is raised per combo step in code), combo_start 1.0 s (whoosh up), combo_tick_loop 1.0 s seamless loop (ticking that we speed up), combo_bank 1.5 s (coins/crowd cheer), collapse 1.5–2 s (rumble with a few blocks tumbling), miss_fall 1.0 s (falling whistle, no impact), life_lost 0.8 s (soft negative), tower_complete 2–3 s (short fanfare), ui_tap 0.1 s. Playful and warm, not harsh.

### HR-0009 · Music loops
- status: open
- type: music
- priority: P2
- needed_for: T-0302, M3
- files: `assets_inbox/music/music_menu_loop.ogg`, `assets_inbox/music/music_round_loop.ogg`, `assets_inbox/music/music_city_loop.ogg`
- requested: 2026-10-13 by opus55-planner
- spec: Menu loop 60–90 s, relaxed. Round loop 90–120 s, upbeat but not frantic, around 100–115 BPM, with a version that can be layered for combo time if possible (optional extra file `music_round_combo_layer.ogg`, same length and tempo). City loop 90–120 s, calm. All seamless loops.

### HR-0010 · UI font
- status: open
- type: font
- priority: P2
- needed_for: T-0303, M3
- files: `assets_inbox/fonts/ui_font.ttf`, `assets_inbox/fonts/ui_font_LICENSE.txt`
- requested: 2026-10-13 by opus55-planner
- spec: A rounded, bold, readable display font under SIL OFL or a paid commercial licence, with Latin Extended and Cyrillic (Chinese handled separately later). Include the licence file.

### HR-0011 · App icon
- status: open
- type: art
- priority: P1
- needed_for: T-0601, M6
- files: `assets_inbox/store/icon_1024.png`, `assets_inbox/store/icon_adaptive_foreground.png`, `assets_inbox/store/icon_adaptive_background.png`
- requested: 2026-10-13 by opus55-planner
- spec: 1024×1024 master icon, plus Android adaptive icon layers at 432×432 (keep the subject inside the central 264×264 safe zone).

### HR-0012 · Store listing graphics
- status: open
- type: store
- priority: P2
- needed_for: T-0603, M6
- files: `assets_inbox/store/feature_graphic_1024x500.png`
- requested: 2026-10-13 by opus55-planner
- spec: Google Play feature graphic 1024×500. Screenshots will be captured from the game in T-0603. Needs final art first.

### HR-0013 · Studio name, package id and Google Play account
- status: open
- type: account
- priority: P1
- needed_for: T-0601, M6
- requested: 2026-10-13 by opus55-planner
- spec: Decide the studio/publisher name and the Android package id (e.g. `com.yourstudio.skylinestack`; it can never change after release). Create the Google Play Console developer account (one-time fee, identity verification takes days, so start early). Write the package id below.

### HR-0014 · Android signing keystore
- status: open
- type: account
- priority: P1
- needed_for: T-0601, M6
- requested: 2026-10-13 by opus55-planner
- spec: Create the upload keystore (the T-0601 doc has the command), store it and its passwords in a password manager plus an offline backup. **Never put it in this repo or the inbox.** Tell agents only the environment variable names that point to it.

### HR-0015 · Ads and analytics accounts
- status: open
- type: account
- priority: P2
- needed_for: T-0501, T-0503, M5
- requested: 2026-10-13 by opus55-planner
- spec: Create the AdMob account and app, then provide the app id and ad unit ids (rewarded, interstitial) below. Agents use Google's public test ids until then. Decide on an analytics provider (Firebase or GameAnalytics) and create the project.

### HR-0016 · Privacy policy and legal entity
- status: open
- type: legal
- priority: P1
- needed_for: T-0504, M5
- requested: 2026-10-13 by opus55-planner
- spec: A hosted privacy policy URL covering ads, analytics and purchases, the legal entity name and a contact email. Needed for store listing and consent screens.

### HR-0017 · Device playtest of core feel
- status: open
- type: playtest
- priority: P1
- needed_for: T-0101, T-0104, M1
- requested: 2026-10-13 by opus55-planner
- spec: **The debug APK is ready.** Build it with `tools/build_android.sh` (or ask an agent) and install it as described in `docs/BUILD_ANDROID.md` "Installing on a phone". First confirm that tapping drops the block (T-0104 needs this confirmation). Then play 10+ rounds on a real phone and answer the questions in `docs/08_TESTING.md` section 5 and the open questions at the end of `docs/balance/TUNING_LOG.md` (feel of the snap window, crane speed, collapse fairness, combo excitement). Write answers below this entry.

### HR-0018 · Review Spanish and German translations
- status: open
- type: design
- priority: P2
- needed_for: T-0304, M3
- requested: 2026-10-13 by opus55-a7k2
- spec: `game/localisation/strings.csv` has English plus Spanish and German drafts written by an AI. A native speaker should review the `es` and `de` columns (tone: friendly, short, game-like), fix them directly in the CSV, keep every `%d`/`%s` placeholder, and set this to `answered`. Preview a language with `godot --path game -- --lang=es`. Also decide which languages ship at launch (add columns for more).

HR-0018 follow-up (2026-10-24, T-0314): also review the new `THEME_*`, `HUD_PAUSE` and `HUD_METER_HELP` Spanish/German drafts. Preserve the `%d` floor-page placeholder.

### HR-0019 · Restore GitHub authentication and sync the recovered game
- status: open
- type: account
- priority: P2
- needed_for: T-0005, T-0006, T-0314, T-0315, T-0316, T-0317, shared-repository sync
- requested: 2026-10-24 by codex-p8m4
- spec: This checkout cannot authenticate HTTPS GitHub operations (`could not read Username`). Authenticate Git for this repository and push the recovered October 24 work and October 26 startup fix from `istiaque_leon`, or sync them from an authenticated checkout. Do not force-push shared history. Implementation is complete locally; this request only covers repository synchronization.

HR-0019 follow-up (2026-10-26, T-0006): local `main` retains all October 24 theme/background commits. Recovery merges this history into `istiaque_leon` together with T-0005. Preserve both branches and the existing GitHub Desktop stash; synchronize the merge after authenticating Git.

HR-0019 follow-up (2026-10-26, T-0317): also synchronize the world-space scenery/camera-ascent implementation and previews on istiaque_leon. CLI HTTPS authentication remains unavailable.
