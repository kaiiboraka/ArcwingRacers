# Track Layout

## Design Intent

Tracks are defined by **splines** — 3D curves that encode the racing line, lap progression, start/finish, spawn/respawn points, minimap display, guide arrow behavior, and AI pathing.

A spline asset exists as a single container object containing one or more path segments. The **main spline** is the primary path where the start/finish line and player spawn (point 0) are located. All other paths are **alternate paths** that branch from and rejoin the main spline.

### The spline is the racing structure, not the whole level

Levels are more than the spline: players can leave the road, cut over hills, and explore open space. The spline only describes the **racing structure** — the road ribbon, tunnels, the AI racing line, lap/respawn data. Everything beside the road is **modeled terrain** (`.glb` per ADR 0009) with its own collision; the AI never intentionally drives off the spline except on explicitly identified alternate paths.

This is a **hybrid authoring model**: each spline segment carries a recipe that decides whether the level builder generates geometry from the spline (a road segment with a width parameter, a tunnel with a height parameter) or leaves the span blank so a hand-modeled section stands as-is. See `technical/tracks-and-splines.md` and ADR 0010 for the implementation.

---

## Cyclic Tracks (Circuits)

All circuit tracks are cyclic by default — the last point connects back to the first to form a closed loop.

- Start/Finish line and racer spawn at **point 0** of the main spline.
- Race is finished once the racer has completed the selected number of circuits (laps).

---

## Non-Cyclic Tracks (Rally / Point-to-Point)

The system also supports non-cyclic splines for point-to-point (rally) tracks.

- If no cyclic spline is found, the main spline is the one with the most points.
- Racer spawns at point 0; the finish line is at the last point.
- Race is always 1 lap regardless of the configured lap count.

---

## Branching Paths

Some tracks feature alternate paths that branch off and rejoin the main spline.

Rules:
- Splines **cannot split more than 2 times** on any single point.
- Splines **cannot join more than 4 times** on any single point.
- Paths **cannot start before and end after** the finish line on the main spline.
- Paths **cannot end at an earlier point** on the main spline than where they began.

---

## Waypoints / Lap Validation

Lap counting uses a **waypoint gating** strategy that permits branching paths and shortcuts while preventing reverse-direction lap fraud:

- **Waypoints** are placed at strategic choke points: before branch splits, after merge rejoins, and at the start/finish line. Not densely along every segment — the gaps between them are free-form.
- A racer's **last-cleared waypoint** tracks their forward progress. The next waypoint in sequence becomes active. The racer advances to it by crossing its proximity trigger — regardless of which route (main path or any branch) they took to reach it.
- This means **branching paths and shortcuts are valid**: a racer who takes an off-spline shortcut that exits ahead of the next waypoint has legitimately advanced.
- The only restriction: waypoints must be cleared in **ascending index order**. Crossing the start/finish line backward or passing a waypoint whose index is lower than the last-cleared waypoint has no effect.
- Lap is complete when cumulative forward progress passes the total spline length (i.e. clearing all waypoints in a loop and recrossing the start/finish line in the forward direction).

---

## AI Pathing

AI racers follow the spline as their primary navigation guide:

- AI target positions are sampled from the spline at a lookahead distance proportional to current speed.
- On branching paths, AI decision-making selects the optimal path based on distance, speed, and track position.
- AI difficulty manifests as variance in lookahead distance, braking aggression, and path selection quality — not just raw speed.

---

## Respawn Points

Respawn locations are defined as points along the spline. When a racer crashes or falls out of bounds, they are respawned at the most recent cleared waypoint, facing forward along the spline direction.

---

## Modular Chunk Stitching

Each biome defines a library of **reusable track segments** — pre-authored chunks of geometry with entry and exit spline connection points:

- Straights, curves, banked turns
- Tunnels, caves, overhangs
- Jumps, ramps, drop sections
- Off-road / alternate route branches
- Hazard zones (geysers, lava flows, ice patches)

A **track definition** is a sequence of segment references plus the spline connecting them. Multiple tracks in the same biome share geometry chunks but arrange them differently.

Chunk geometry may be **modeled** (a `.glb` segment, per ADR 0009) or **generated** from the spline (a recipe-flagged span, per ADR 0010) — the two coexist in the same track definition.

---

## Technical Reference

See `docs/technical/tracks-and-splines.md` for the detailed implementation reference — data format per point, traversal math, AI sampling algorithms, and minimap rendering.
