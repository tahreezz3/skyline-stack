# Reference background revision

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

Each theme's `background.texture` is a local imported Texture2D. A camera-parented unshaded quad samples that image at its original colors. The shader uses aspect-cover cropping with a bottom-centre anchor, keeping the ground clearing visible without stretching the artwork. `backdrop.overscan` covers edge seams. No procedural sun, sky, mountain or generic skyline is composited over it.

`background.lighting` supplies the live 3D modules' key/ambient/rim color, energy and directions. Daytime has neutral fill; sunset scenes have warm light from the reference's right side. Camera height does not change the selected reference lighting. Background art is a static scenic plate; the tower, cable, hoist, modules and feedback remain animated independently. No collision, scoring, balance, progression, save, theme selection or HUD changes are made.

## Verification

- `test_background_art.gd`: all ten local assets load as Godot textures, have unique content, support portrait resolution and have explicit reference-lighting profiles.
- Theme tour: checks selected background paths, stable lighting after a large camera-height change, independent live modules and portrait layouts.
- `tools/check.sh`: complete existing rule, autoplay and UI checks plus the background contracts.
- Native gallery: `godot --path game --script res://tools/theme_tour.gd -- --gallery-only --screenshots=/tmp/skyline-backgrounds` captures actual rendered ground/tower views for comparison with the source references. Gallery mode covers rendering/layout; the standard headless tour retains real-click input checks separately. Native resizing waits for a stable aspect before taking a frame.

Android device testing is still separate. The renderer loads only the selected environment, with no runtime network request or image generation.
