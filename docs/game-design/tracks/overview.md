# Tracks

## Biome Overview

ArcwingRacers launches with at least **10 distinct biomes**, each with its own visual theme, environmental hazards, and reusable modular track segments.

| Biome | Nation | Theme | Hazards | Status |
|---|---|---|---|---|
| [TBD] | Losallia | [TBD] | [TBD] | Planned |
| [TBD] | Enria | [TBD] | [TBD] | Planned |
| [TBD] | Dowania | [TBD] | [TBD] | Planned |
| [TBD] | Stoldenia | [TBD] | [TBD] | Planned |
| [TBD] | Yafrenia | [TBD] | [TBD] | Planned |
| [TBD] | Rylaria | [TBD] | [TBD] | Planned |
| [TBD] | Ciephara | [TBD] | [TBD] | Planned |
| [TBD] | Azara | [TBD] | [TBD] | Planned |
| [TBD] | Bjønta | [TBD] | [TBD] | Planned |
| [TBD] | [TBD] | [TBD] | [TBD] | Planned |

---

## Modular Track Construction

Each biome defines a library of **reusable track segments** — pre-authored chunks of geometry with entry and exit spline connection points:

- Straights, curves, banked turns
- Tunnels, caves, overhangs
- Jumps, ramps, drop sections
- Off-road / alternate route branches
- Hazard zones (geysers, lava flows, ice patches)

A **track definition** is a sequence of segment references plus the spline connecting them. Multiple tracks in the same biome share geometry chunks but arrange them differently.

**EP1R example:** The jungle biome on Oovo IV has a volcanic cave section that's visible but inaccessible in the standard course. A separate race uses ONLY the cave segment with none of the jungle.

---

## Track Features

- **Branching paths:** Every track has at least one alternate route, usually a shortcut that trades difficulty for time.
- **Environmental hazards:** Per-biome hazards (heat, ice, water, monsters, geysers). Elemental Imbalance mode remixes which hazards appear.
- **Checkpoints:** Waypoints at choke points before/after splits and at start/finish (see [ADR 0005: Spline Track System](../decisions/adrs/0005-spline-track-system.md)).
- **Pit area:** Off-track repair zone (future — repair during race is post-launch scope).
- **Spectator areas:** Visual-only geometry not on the racing line.

---

## Tournaments & Circuits

Tracks are organized into **tournaments** that gate single-player progression. Each tournament combines tracks from multiple biomes with a specific lap count and difficulty:

1. **Amateur Circuit** — 4 races, easy difficulty, low payout
2. **Semi-Pro Circuit** — 8 races, medium difficulty
3. **Galactic Circuit** — 12 races, hard difficulty
4. **Invitational** — Single elite races with high payout and prestige
5. **Archon Races** — Roguelike tournament series (see [overview.md](overview.md))

EP1R has ~32 races across ~25 tracks. Target similar volume for launch.

---

## Spline Data

Each track's spline is a Godot Resource (`.tres`) containing:
- Main path: array of 3D control points (cyclic for circuit tracks)
- Alternate paths: array of path arrays with connection indices to the main spline
- Waypoint positions: indices along the main spline where gating occurs
- Respawn points: per-path positions
- AI lookahead distances: tunable per-segment

See [technical/tracks-and-splines.md](../technical/tracks-and-splines.md) for the detailed technical reference.
