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
- status: open
- type: decision
- priority: P0
- needed_for: T-0301, HR-0004..HR-0007, M3
- requested: 2026-10-13 by opus55-planner
- spec: Pick one direction from `docs/06_ART_AUDIO_SPEC.md` section 2 (A: flat pastel vector, B: chunky low-poly look rendered to 2D, C: hand-drawn storybook), or describe your own. Everything visual waits on this.

### HR-0003 · Approve the unique hook
- status: open
- type: decision
- priority: P1
- needed_for: T-0110, M2
- requested: 2026-10-13 by opus55-planner
- spec: Read the candidate hooks in `docs/01_GDD.md` section 6 and pick 1–2 to build. This is what makes the game stand apart from other stackers and is needed before store submission.

### HR-0004 · Building block sprites (4 colours × 4 parts)
- status: open
- type: art
- priority: P1
- needed_for: T-0301, M3
- files: `assets_inbox/art/blocks/block_blue_floor.png`, `assets_inbox/art/blocks/block_blue_base.png`, `assets_inbox/art/blocks/block_blue_roof.png`, `assets_inbox/art/blocks/block_blue_roof_trophy.png`, `assets_inbox/art/blocks/block_red_floor.png`, `assets_inbox/art/blocks/block_red_base.png`, `assets_inbox/art/blocks/block_red_roof.png`, `assets_inbox/art/blocks/block_red_roof_trophy.png`, `assets_inbox/art/blocks/block_green_floor.png`, `assets_inbox/art/blocks/block_green_base.png`, `assets_inbox/art/blocks/block_green_roof.png`, `assets_inbox/art/blocks/block_green_roof_trophy.png`, `assets_inbox/art/blocks/block_yellow_floor.png`, `assets_inbox/art/blocks/block_yellow_base.png`, `assets_inbox/art/blocks/block_yellow_roof.png`, `assets_inbox/art/blocks/block_yellow_roof_trophy.png`
- requested: 2026-10-13 by opus55-planner
- spec: One storey of a building seen from the front. floor = repeating middle storey, base = ground-floor storey (door, shop front), roof = final cap, roof_trophy = fancier cap for a perfect tower. Canvas 480×288 px (5:3, the block's footprint is exactly the canvas width; roofs may add up to 192 px of height above, so roof canvases are 480×480 with the storey aligned to the bottom). Silhouette must read at 120 px wide. Colours: blue, red, green, golden-yellow families.

### HR-0005 · Crane hook and rope
- status: open
- type: art
- priority: P2
- needed_for: T-0105, M3
- files: `assets_inbox/art/crane/crane_hook.png`, `assets_inbox/art/crane/crane_rope.png`
- requested: 2026-10-13 by opus55-planner
- spec: Hook 160×160 px, the attachment point at bottom centre. Rope 16×128 px, tiles vertically without seams.

### HR-0006 · Background layers
- status: open
- type: art
- priority: P1
- needed_for: T-0301, M3
- files: `assets_inbox/art/background/bg_sky.png`, `assets_inbox/art/background/bg_far_city.png`, `assets_inbox/art/background/bg_near_city.png`, `assets_inbox/art/background/bg_clouds.png`
- requested: 2026-10-13 by opus55-planner
- spec: Portrait parallax set, 1080×1920 px each. Sky is a vertical gradient that can be tinted for height (day at ground, dusk and stars as the tower grows). Far and near city layers are skylines along the bottom with transparent sky. Clouds are 1080×1920 with 4–6 separate clouds on transparency.

### HR-0007 · Ground, dust and debris effects
- status: open
- type: art
- priority: P2
- needed_for: T-0102, M3
- files: `assets_inbox/art/fx/ground_foundation.png`, `assets_inbox/art/fx/dust_puff.png`, `assets_inbox/art/fx/sparkle_star.png`, `assets_inbox/art/fx/debris_chunk.png`
- requested: 2026-10-13 by opus55-planner
- spec: Ground strip 1080×320 px (plaza with the foundation slab at centre, 480 px wide). Dust puff 256×256 soft cloud for landings. Sparkle star 128×128 for perfects. Debris chunk 96×96 for collapses.

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
- spec: After T-0104 produces a debug APK, play 10+ rounds on a real phone and answer the questions in `docs/08_TESTING.md` section 4 (feel of the snap window, crane speed, collapse fairness, combo excitement). Write answers below this entry.
