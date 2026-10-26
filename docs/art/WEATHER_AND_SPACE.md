# Weather and the climb to space

T-0318 adds the owner's ten requested cosmetic weather conditions to every building theme. A round picks one condition using a private random generator. It keeps that choice on ascent, descent, pause and resume. Sunny, Clear, Cloudy, Rainy, Snowy, Windy, Foggy, Thunderstorms, Tornadoes and Hurricanes have independent cloud coverage, sky tint and effects. Storms are a little rarer than ordinary weather; all weights are configurable.

Weather changes rendering only. There are no wind forces, collisions, lightning damage, rain friction, new lives/scoring rules, or effects on crane speed. Existing module lighting stays bright and readable. Rain, snow, gusts, haze and distant lightning render behind the tower and HUD. The distant tornado and spiral hurricane are original world-space cloud geometry. They remain at their world coordinates as the camera leaves the landscape.

The ascent is continuous rather than a level switch. Default camera heights:

| Height in world units | Presentation |
|---|---|
| 0–14 | Theme atmosphere and the round's weather |
| 14–28 | Gradually bluer upper atmosphere |
| 18–30 | Weather and atmospheric cloud meshes fade out |
| 22–42 | Atmosphere blends into a navy star field |
| 42+ | Full space; no precipitation, haze or atmospheric clouds |

One floor is 0.6 world units. Accounting for camera framing, space begins around 40 floors and is complete around 70–75 floors in Endless. An Earth-like ocean/land planet, a banded ringed gas giant and a cratered moon occupy fixed world positions at successive heights. The camera passes them just like the lower landscape. Distant procedural stars continue at unlimited heights and shift with altitude. Returning downward restores the same planets, atmosphere, weather and landscape; it never rerolls the round.

`atmosphere.json` holds tuning; `atmosphere_state.gd` selects cosmetic weather and samples reversible height transitions. `atmosphere_view.gd` builds original planet/cyclone meshes and configures the sky and weather shaders. It receives only a paused presentation time and camera height/aspect. It has no gameplay state, physics, input or save references. The weather particle field is an infinite camera-relative volume with altitude coordinates; scenery and planets are outside the camera hierarchy. No full background images are used.

Pause freezes every animation through the existing explicit clock. Reduced Motion uses a stable weather/planet pose and suppresses lightning; essential tower camera tracking and altitude transitions still work. Lightning is a slow, small distant bolt without a full-screen flash or thunder audio.

Preview a particular round weather without saving a new setting:

```bash
godot --path game -- --weather=snowy --visual-seed=42
godot --path game --script res://tools/atmosphere_tour.gd -- --screenshots=/tmp/atmosphere --frames=144 --weather-frames=48
```

The weather IDs are `sunny`, `clear`, `cloudy`, `rainy`, `snowy`, `windy`, `foggy`, `thunderstorms`, `tornadoes`, `hurricanes`. Invalid IDs use the random choice. The seed and override are developer command-line controls only. The tour exports each condition and a 125-floor climb from actual rounds, with saves disabled; it compares gameplay outcomes, pause and Reduced Motion pixels, fixed world anchors, reverse transitions and portrait resizing. Headless mode runs the same logical integration checks without image capture. Native previews are in `docs/art/previews/weather.webp` and `space-ascent.webp`/`.mp4`.

Mobile performance remains part of the existing device-QA task; desktop exports use the Apple M1 Mobile renderer. Static scenery remains batched, the weather volume is one textureless draw, cloud pools are bounded, and only the selected cyclone mesh is built.
