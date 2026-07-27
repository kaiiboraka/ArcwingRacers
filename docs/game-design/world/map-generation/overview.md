# Map Generation

## Overview

Each game has a **randomly generated map**. No two sessions are identical.

## Generation Order

Tile Clusters (see below) are placed first, with a required minimum distance enforced between them. The rest of the map is filled in afterward. `[TBD: exact fill algorithm for the remaining tiles isn't specified]`

`[Source: hand-written-notes.txt]` That minimum-distance rule applies specifically to the **3 major locations** — Town, Castle, Swamp — which must be kept far apart from each other. **Minor locations** (Hermit, caves, Prison, Farm, etc.) are filled in randomly anywhere on the map with no such spacing requirement.

## Standard Map Template

A baseline map size and terrain-seed budget for a standard playable map:

- **Size:** at least 75×75 tiles `[TBD: exact size is trial-and-error tuned, not fixed]`
- **Forests:** 2–5 seeds
- **Hills:** 2–3 seeds
- **Mountain ranges:** 2–3 seeds (each with 2–3 caves `[TBD: cave count per range unconfirmed]`)
- **Rivers:** 1–2 seeds
- **Lakes:** at least 1

## Spawn Points

Three locations act as spawn points for new characters entering the map:

| Spawn Point | Spawns |
|---|---|
| Castle | Gate Guards |
| Town | Thieves |
| Swamp Cauldron | Vipers |

## Terrain Types

| Tile | Movement Effect | Notes |
|---|---|---|
| Impassable rocks | Blocks all | Hard obstacle |
| Castle walls | Blocks all | Surrounds the King's Castle |
| Swamp trees | Blocks all (mostly) | Surrounds the Witch's Lair |
| Hills | Slows Vipers and Thieves | Traversable but slower |
| Forest trees | Slows Vipers and Thieves | Traversable but slower |
| Water | Vipers: passable; Thieves: blocked | Strategic divide |
| Houses | Vipers: blocked; Thieves: can hide | One Thief per house; richer Thief evicts occupant |

## Special Locations

The following are randomly placed on every map:

- **King's Castle** — primary goal for Thieves
- **Witch's Lair** — primary goal for Vipers
- **Hermit** — hint-giver NPC
- **Side Quest Entrance** — leads to a dungeon/separate area; two pools — character-specific quest entrances (unique per character, tied to that character's run) and a general pool of randomly-spawned entrances usable on any run (see `world/locations/side-quest-entrance.md`)
- **Secret Treasure Cave** — hidden, appears temporarily after a specific trigger (see `world/locations/secret-cave.md`)

## Map Edges

Map edges **wrap around** both vertically and horizontally. See `systems/map-wrapping.md` for implementation details.

## Tile Clusters

Multi-tile groups placed as a unit during the generation order described above, each themed to one of the two special locations:

- **Swamp cluster** (around the Witch's Lair): Rotted Tree, Marsh, Swamp Thicket Wall, Cauldron. A wide outer ring with randomly-generated swamp seeds surrounds the inner grove (see `world/locations/swamp-entrance.md` for the inner grove's fixed layout).
- **Castle cluster** (around the King's Castle): Wall, Tower, Torch, Gate (the Gate tile triggers the Castle Entrance scripted encounter — see `gameplay/scripted-encounters/guard-opens-castle-gates.md`).
- **Town cluster:** has an entry trigger tile and a Thief spawn point.
- **Prison cluster:** `[TBD: no further detail in source material — see world/locations/prison.md]`
- **Farm cluster:** `[TBD: no further detail in source material — see world/locations/farm.md]`

## Additional Environment Tiles

Tiles from source material not yet reflected in the Terrain Types table above:

| Tile | Notes |
|---|---|
| Prison | Part of the Prison cluster (see Tile Clusters above). `[TBD: relationship to existing Prison Guard/Captive NPCs — see gameplay/npcs/]` |
| Mountain | Distinct from plain impassable rock — the Bomb consumable (`loot/loot-types.md`) spawns a cave when used on a Mountain tile. |
| Cave | Triggers a Cave Entrance scripted event. `[TBD: cave floor rendering — source itself flags this unresolved: "Cave floor or black?? Stalagmite doodads?"]` |
| Hermit Shack | Home tile for the Hermit NPC (`world/locations/`). |
| Tree of Knowledge of Good and Evil | Passing over this tile "eats the berries," making every character on screen glow with friend/foe colors. The **Elder Berries** consumable (see `loot/loot-types.md`) grants the same effect on demand. |

`[TBD]` Elder Berries is not yet listed in `loot/loot-types.md`'s consumable catalog — add it there; effect: same friend/foe glow as the Tree of Knowledge tile.

## Tile Speed

Character movement speed is modified by the terrain of the tile they're on. Different character types can be affected differently by the same tile (blocks one, slows another, etc. — see the Vipers/Thieves split in the Terrain Types table above).

`[TBD — open design question from source material, not yet resolved]`: For a Viper (a multi-tile body), is movement speed determined by the tile under its head, or the slowest tile under any part of its body? Source material also questions whether per-tile speed variance is worth the complexity versus a flat, static speed modifier applied equally to all characters.

## Level Assets

Sub-area tile/prop sets referenced by name in source material, not yet detailed elsewhere:

- **Castle Courtyard:** Steps, Floor Stones, Walls, Palace Door.
- **Palace:** Walls, Floor Stones, Floor Carpet, Warrior Statues, Throne, Banners, Candelabra.
- **Cave:** Cave Walls (floor treatment `[TBD]`, see Additional Environment Tiles above).
- **Swamp:** `[TBD: no asset list given beyond the Tile Clusters above]`
