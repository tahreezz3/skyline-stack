# World environments and tower ascent

T-0317 replaces the camera-attached scenic image after the owner pointed out that the scene stayed unchanged as the tower rose. The game now builds original 3D ground, waterways, buildings, bridges, foliage and local activity. These stay at fixed world coordinates. The same camera that follows the tower moves past them, revealing rooftops, then sky and higher cloud bands. Falling/collapse camera descent returns to the same landscape.

The infinite atmosphere alone follows the camera; it contains a procedural theme palette and the three reference-appropriate natural sunset suns (or natural sunshine in Sunny weather). No complete scenic image is sampled. The previous paintings remain in the repository as art references with their original provenance. The new scenes have a code-native low-poly appearance; their component detail is separate from the old painted artwork.

| Theme | World objects |
|---|---|
| Manor | Blue-roof manor, formal hedges, flower beds, cypress trees, fountain and river bridge |
| Corporate | Different-height glass buildings, roads/plaza, cable bridge, ferry and traffic |
| Chinese | Karst pillars, tiered pagodas, arched river bridge, sailboat and birds |
| Palace | Blue domes, gold finials, royal buildings, cypress avenue, bridge, flags and ferry |
| Fort | Cliff-top castle, crenellated walls, blue flags, bridge and river boat |
| Igloo | Snow islands, ice huts, glaciers, piers, snow trees, drifting floes and vapor |
| Prison | Concrete blocks, fenced compound, watchtowers, patrol car and distant sea traffic |
| Office | Glass campus, varied office heights, landscaped plaza, bridge and river ferry |
| Factory | Tanks, refinery platforms/pipes, chimneys, harbor crane, piers, steam and ship |
| Lighthouse | Rock islands, cottages, lighthouse/beacon, pier, sailboat and sea |

`environment_world.json` stores all layouts, colors and motion tuning. `world_environment_kit.gd` creates normalized artistic model topology; `world_environment.gd` batches static models and runs independent actor/cloud pools. There are no background physics bodies. Lighting and gameplay modules retain their established profiles.

Verification includes mesh/layout/pause contracts, actual camera projections at 0/6/12/20/40 floors and restored framing after descent for all ten themes, native frame differences for world activity, and pixel-identical Reduced Motion output at a stationary camera. Reduced Motion keeps essential gameplay camera movement.

```bash
godot --path game --script res://tools/environment_climb_tour.gd -- --screenshots=/tmp/ascent --frames=96
```

This captures every theme at ground, low and high tower stages and exports an eight-second 12 fps ascent through 24 floors with the real height-framing function. `previews/world-ascent.mp4` shows all ten; `previews/world-ascent.webp` shows Manor, Factory and Lighthouse. Historical `living-environments.*` previews show the superseded image-plate implementation.


T-0318 adds a round's random cosmetic weather, upper-atmosphere fade and the climb into stars/planets. Ground/landmarks keep the same world-space behavior. See [WEATHER_AND_SPACE.md](WEATHER_AND_SPACE.md) for all ten conditions, altitude thresholds, architecture and preview commands.
