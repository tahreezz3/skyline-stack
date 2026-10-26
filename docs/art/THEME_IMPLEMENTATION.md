# Ten architectural themes

T-0314 implements the owner's v001-v010 package as original procedural 3D meshes, with local pixel HUD icons. Select **Architecture theme** on the tower selection screen, then choose an unlocked tower family. All ten cosmetics are available immediately. Theme choice lasts for this app session, including Play again, returning to the menu and Endless. Relaunching starts with v001 Manor; `--theme=v010` can override it for previews. Cosmetics do not add save fields or change the four progression families. Completed city-map towers retain their existing family representation.

## Source reconciliation

The supplied `CODEX_MASTER_PROMPT_Hybrid_System.md`, `PLACEMENT_RULES_Hybrid_System.md` and Word brief explicitly require the original hybrid system; older README, HUD, art and theme text still says precision-only. The hybrid documents are the implementation baseline. The owner confirmed the v001-v010 theme scope during implementation. No precision-only or trimming mode was introduced. `tower_rules.json`, frozen test fixtures and all core/progression/save scripts remain unchanged.

Live rules remain: perfect below 0.06; stack through 0.35; collapse above 0.35 and below 1.0; miss at or above 1.0. First-floor offsets through 0.62 are accepted as stable after the miss check. Population continues to use residents, banked combo rewards, collapse losses and roof rewards. It does not become a flat +15 reward.

## Theme inventory

| ID | Theme | Architecture and setting |
|---|---|---|
| v001 | Manor | Ivory walls, blue arched windows, cornices, symmetric garden shrubs |
| v002 | Corporate | Blue glass grid, silver mullions and modern skyline |
| v003 | Traditional Chinese | Red timber, curved tiled eaves, lanterns, river and distant hills |
| v004 | Palace | Cream stone, gold detailing, arched windows and courtyard columns |
| v005 | Fort | Pale masonry, battlements, narrow arches, banners and perimeter walls |
| v006 | Igloo | Faceted rounded ice, snow caps, blue arches, icy water and mountains |
| v007 | Prison | Concrete, barred windows, railings, compound walls and watchtowers |
| v008 | Office | Glass, gray frames, warm window glow and planted terraces/campus |
| v009 | Factory | Steel frames, pipes, safety red, tanks and harbor water |
| v010 | Lighthouse | Round white/red modules, circular railings, lantern crown and rocky coast |

The live tower modules remain procedural interpretations of the references. T-0315 replaces the initial procedural backgrounds with detailed environment-only artwork edited from each owner reference; see `BACKGROUND_REVISION.md`. Full reference compositions are not shipped as backgrounds or sprites. Active, falling, placed and toppled modules share the selected theme's mesh/materials; its ground floor adds a matching door, and its completion crown uses matching architecture. Background scenery now comes from independent reference-matched art with neutral daylight or golden-hour lighting; the shared purple sun and procedural hills/rows have been removed. Theme decorations never enter collision or placement calculations.

## Shared HUD

Three original red pixel hearts sit at upper-left (lost hearts dim). A blue numeric badge and one segmented blue meter sit at lower-left. **The number is completed floors; the meter is height / target height.** In Endless, the meter cycles through a configurable 20-floor page, while the number continues increasing. This avoids suggesting that block width changes in the full-width hybrid system. The small gold person icon and population counter sit at lower-right; the counter pads to at least five digits without truncating larger scores. The existing combo timer remains a small strip below it. Pause stays upper-right, with the existing pause/resume, rewarded continue and results flows.

Portrait stretch uses `expand` so narrow and tall displays render their actual aspect without letterboxing. The HUD anchors to the viewport edges and leaves the playfield transparent to input. The crane has an independent striped hoist and suspension cables attached to the carried module's top corners; slings retract visually upon release.

## Implementation and checks

- `config/themes.json` is the cosmetic catalog, palette, mesh dimensions and reference background/lighting configuration. `ThemeCatalog` resolves unknown IDs to the configured default.
- `theme_kit.gd` builds geometry using the existing `building_kit.gd` triangle builder. Fixed normalized fractions describe original mesh topology, while configurable dimensions remain in JSON.
- `config/round_hud.json` contains HUD layout and display parameters.
- `test_themes.gd` checks catalog integrity, full-width mesh envelopes, floor heights and live hybrid boundaries.
- `tools/theme_tour.gd` checks real theme selection/start clicks, all ten renderers, matching active/placed modules, a single resolution per release, HUD bounds at narrow/tall portrait sizes and restart reset. It never writes the player's save.

```sh
tools/check.sh
godot --headless --path game --script res://tools/theme_tour.gd
godot --path game --script res://tools/theme_tour.gd -- --screenshots=/tmp/skyline-themes
godot --path game -- --autoplay --theme=v003 --seconds=60
```

New English labels have draft Spanish and German translations covered by HR-0018. This task does not complete final artist delivery T-0301 or on-device visual/performance QA.
