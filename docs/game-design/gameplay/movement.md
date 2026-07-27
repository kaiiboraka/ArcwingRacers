# Movement

## Core Rule

**You are always moving straight.** If you run into an impassable tile, you just stop — making you easy snake food. Vipers move faster than Thieves.

## Speed Modifiers

Speed can be boosted or lowered through Consumables, Equipment, Terrain modifiers, and Status Effects:

| Modifier | Effect |
|---|---|
| Viper size | Gets faster as it grows bigger |
| Viper digesting food | Gets slower while digesting |
| Thief speed potion | Temporarily run faster |
| Hills | Slower for both Vipers and Thieves |
| Forest trees | Slower (same as hills) |
| Swamp tiles | Slow humans; no impact on Vipers |

Understanding these speed effects and using them strategically is a core part of V&T gameplay — particularly during chases.

## Terrain Rules

| Tile | Viper | Thief |
|---|---|---|
| Impassable rocks / castle walls / swamp trees | Blocked | Blocked |
| Hills / forest trees | Slowed | Slowed |
| Water | Passable | Impassable (blocked) |
| Houses | Cannot enter | Can hide inside (stops movement; only one Thief per house; richer Thief evicts weaker one) |
| Viper bodies | Can move over (including own body) | Blocked — can be corralled by a hunting Viper |

## Viper-Specific

- Vipers cannot turn backwards — they must make a U-Turn (turn left twice, or right twice).
- The Viper's tongue flicks in warning when something approaches just off-screen.

### Layering (Sprite Depth) When Vipers Overlap

`[Source: hand-written-notes.txt]` Vipers can move across and over themselves (their own long body/tail) and across other Vipers' bodies — this needs a layer-depth system to decide who renders on top:

- **The Viper moving into another Viper is always drawn on top.** There's no ambiguous case of both moving into each other simultaneously — a **head-on-head collision** instead causes the bigger Viper to snap (attempt to bite) the other, which resolves the conflict before a layering decision is even needed.
- Crawling over another segment (your own tail or a different Viper's) reads visually as a **raised bump** passing over the body underneath.
- Mechanically, only the **head** segment actively decides its own layer each move. Each body segment, and finally the tail, **inherits the layer of the tile it's moving into** as it follows the path the head already took — "follow the leader," propagated one tile at a time down the body.

### Self-Tail Protection

`[Source: hand-written-notes.txt]` A Viper can protect itself from being eaten by other Vipers by driving its head (or any body segment) over its own tail — the tail isn't bitable while a head or body segment is overlapping it. See `gameplay/player-characters/viper-gameplay.md`'s Eating Vipers section for the normal tail-lock/chase rules this protects against.

## Thief-Specific

- Thieves can make immediate reversals.
- Thieves are blocked by Viper bodies, which enables the tactic of **corralling** — a hunting Viper closing in to wall off a Thief's escape routes.
- When a lone Thief enters a house, they stop moving until they swipe to move out.
- Only one Thief can occupy a house at a time. A richer Thief evicts the current occupant in the direction they were moving (or a random passable direction).

## Map Edges

Map edges wrap around both vertically and horizontally. See `systems/map-wrapping.md` for details.
