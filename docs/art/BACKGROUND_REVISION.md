# Living reference environments

T-0315 replaces the shared purple sun, muted lighting, low-poly hills and repeated tower rows with ten distinct environment-only art assets based on the owner's visual references. The central playable tower, carried/falling modules, crane, effects and HUD remain separate live Godot elements. The reference images containing gameplay/UI are not shipped as backgrounds.

The assets were produced with the built-in image generation tool, using each owner reference as an edit target: remove tower, floating floor, crane and all HUD; reconstruct the surrounding environment; preserve the source scenery, composition, bright color and natural time of day. Complete prompts and project paths are in [generation-prompts.json](backgrounds/generation-prompts.json). Provenance and hashes are in [asset-manifest.json](backgrounds/asset-manifest.json); asset terms are recorded in `assets_inbox/LICENSES.md`.

| Theme | Environment retained from the reference | Lighting |
|---|---|---|
| v001 Manor | French manor, formal gardens, fountain, river, bridge and distant village | Clear blue daytime |
| v002 Corporate | Varied glass skyscrapers, river, cable bridge and tree-lined urban plazas | Clear blue daytime |
| v003 Traditional Chinese | Karst cliffs, pagodas, arched bridge, glowing river and junk boat | Cream/gold sun and peach sunset |
| v004 Palace | Blue domes, gold details, royal castle, turquoise river and ceremonial courtyard | Clear blue daytime |
| v005 Fort | Castle on a cliff, crenellated walls, banners, river bridges and forested valley | Clear blue daytime |
| v006 Igloo | Snowy mountains, glaciers, ice bay, igloo huts, piers and snow-covered trees | Crisp sunny blue/white |
| v007 Prison | Coastal compound, low concrete blocks, fenced exercise yards and watchtowers | Clear blue daytime |
| v008 Office | Contemporary river city, cable bridge, landscaped campus and warm reflections | Bright late afternoon |
| v009 Factory | Refinery pipes/tanks/stacks, illuminated steam, cargo harbor and ships | Natural golden sunset |
| v010 Lighthouse | Rocky coast, red-roof cottages, small distant lighthouse, boats and pier | Natural golden ocean sunset |

## Rendering

T-0316 turns the reference plates into living 2.5D environments. The original artwork is the scenic foundation; separate sky, water and cloth masks, camera depth and independent vector actors provide motion. This is a layered illustration renderer, not a reconstruction of every painted building as 3D geometry.

Each theme's `background.texture` is a local imported Texture2D. A camera-parented unshaded quad samples that image at its original colors and composites the live environment actor texture. The shader uses aspect-cover cropping with a bottom-centre anchor, keeping the ground clearing visible without stretching the artwork. `backdrop.overscan` covers edge seams. No generic sun, mountain or skyline is added. Conservative sky masks let existing clouds drift while pinning architecture, mountain edges and natural sunset suns. Shoreline masks confine subpixel refraction and changing glints to water; exclusion polygons protect piers, boats and other occluders. Blue-channel masks animate existing royal/fort banners. The camera samples near scenery with a greater offset than distant scenery as it moves; this depth offset is bounded at endless heights.

`background.lighting` supplies the live 3D modules' key/ambient/rim color, energy and directions. Daytime has neutral fill; sunset scenes have warm light from the reference's right side. Camera height does not change the selected reference lighting. The tower, cable, hoist, modules and feedback remain independent from the living environment. No collision, scoring, balance, progression, save, theme selection or HUD changes are made.

### Independent scene activity

| Theme | Live details |
|---|---|
| v001 Manor | Fountain jets/droplets/rings, garden pollen and birds |
| v002 Corporate | River ferry with wake, bridge traffic and birds |
| v003 Traditional Chinese | River sailboat, drifting mist and birds |
| v004 Palace | Existing banners flutter, river ferry and two distant bird flocks |
| v005 Fort | Existing flags/banners flutter, river boat and birds |
| v006 Igloo | Drifting/bobbing ice floes, chimney vapor and birds |
| v007 Prison | Yard patrol vehicle, distant sea traffic and birds |
| v008 Office | River ferry, road traffic and birds |
| v009 Factory | Three independent rising/drifting steam emitters, harbor traffic and birds |
| v010 Lighthouse | Sailing boat, pulsing lighthouse beacon and birds |

`background_motion.gd` owns an explicit elapsed clock and eased camera offset. No environment animation uses shader `TIME`, system time, randomness or gameplay state mutation. Pausing freezes clock/depth and the actor render texture; Reduced Motion uses time zero, no refraction/cloth/cloud movement and zero camera depth. Returning to normal motion resumes the previous clock without adding paused elapsed time.

`living_background.gd` draws original small vector actors into a transparent 720×1280 SubViewport. Only the selected environment is instantiated. It redraws once when its explicit clock changes and remains disabled on stationary frames. Route endpoints fade to hide loop resets. Artistic primitive vertices live in the renderer; tunable positions, dimensions, rates, periods, color and fitted masks live in `config/background_motion.json`. Its mask texture is rasterized from these vector polygons once per round; the original art files are unchanged.

## Verification

- `test_background_motion.gd`: deterministic frame-rate-independent timing, bounded depth, pause/reduced-motion/resume, actor route loops and individually fitted masks for all ten environments.
- `background_motion_tour.gd`: actual round pause flow and accessibility checks in all themes. Native rendering additionally checks that live frames differ and Reduced Motion frames are pixel-identical; optional fixed-time exports freeze gameplay and advance only the background.
- `test_background_art.gd`: all ten local assets load as Godot textures, have unique content, support portrait resolution and have explicit reference-lighting profiles.
- Theme tour: checks selected background paths, stable lighting after a large camera-height change, independent live modules and portrait layouts.
- `tools/check.sh`: complete existing rule, autoplay and UI checks plus the background contracts.
- Native gallery: `godot --path game --script res://tools/theme_tour.gd -- --gallery-only --screenshots=/tmp/skyline-backgrounds` captures actual rendered ground/tower views for comparison with the source references. Gallery mode covers rendering/layout; the standard headless tour retains real-click input checks separately. Native resizing waits for a stable aspect before taking a frame.

Animated preview: `previews/living-environments.mp4` (all ten) and `previews/living-environments.webp` (Manor, Factory and Lighthouse). Generate source frames with `godot --path game --script res://tools/background_motion_tour.gd -- --screenshots=/tmp/motion --frames=72` (12 fps, six seconds).

Android device performance and visual testing are still separate. The renderer loads only the selected environment, with no runtime network request or image generation.
