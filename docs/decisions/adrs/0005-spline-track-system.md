# ADR 0005: Spline-Based Track System

## Status
Accepted

## Context
Tracks in EP1R are built from splines — 3D curves defining the racing line, lap progression, AI pathing, spawn points, and minimap display. The system supports cyclic (circuit) and non-cyclic (rally) configurations, branching paths, and modular chunk stitching where the same biome's geometry segments are rearranged to create multiple courses.

We need a track system that:
- Supports at least 10 biomes with modular chunk stitching
- Allows branching paths and intentional shortcuts
- Validates lap progression without penalizing alternate routes
- Drives AI pathfinding
- Provides respawn points along the track

## Decision
Adopt the spline-based track model from EP1R:

1. **Spline asset:** Each track has a spline resource containing a main path and zero or more alternate paths. The spline is a serializable Godot Resource (`.tres`) storing a list of 3D control points per path.

   > **Terminology (EP1R → Godot):** EP1R's *spline* maps to Godot `TrackSpline` (`Systems/Track/track_spline.gd`, the track container holding the main path, `alternate_paths`, `branches`, and gameplay helpers); EP1R's *path* maps to Godot `Spline` (`Systems/Track/spline.gd`, a single `Curve3D` oblivious to branches). "Spline containing paths" above is consistent under EP1R vocabulary: `TrackSpline` contains `Spline`s, linked by the `BranchConnection` graph.
2. **Main spline:** The primary circuit loop. Point 0 is the start/finish line. Racer spawns are placed near point 0 in a grid behind the line.
3. **Branching paths:** Alternate paths that diverge from and rejoin the main spline. Subject to:
   - Max 2 splits at any point
   - Max 4 joins at any point
   - No path starts before and ends after the finish line on the main spline
   - No path ends at an earlier main-spline index than where it began
4. **Waypoint gating:** Choke-point waypoints placed at strategic positions (before splits, after merges, at start/finish). Lap progress advances when the racer reaches the next waypoint in index order, regardless of which route they took. Reverse-direction waypoint crossing is ignored. This permits shortcuts while preventing backwards lap fraud.
5. **Modular chunk stitching:** Each biome defines reusable track segments (straights, curves, tunnels, jumps). A track definition is a sequence of segment references plus the spline connecting them. Multiple tournaments can use different arrangements of the same biome's segments.
6. **AI pathing:** AI racers sample target positions from the spline at a lookahead distance proportional to current speed. On branching paths, AI selects the optimal path by comparing total remaining distance.
7. **Respawn:** Respawn locations are defined per-path. On crash or out-of-bounds, the racer respawns at the most recent cleared waypoint facing forward.

## Consequences
- **Positive:** Proven system directly from the reference game — community knowledge about spline design transfers.
- **Positive:** Waypoint gating enables the shortcut-rich track design the user wants.
- **Positive:** Modular stitching gives us many tracks per biome without authoring each from scratch.
- **Tradeoff:** Spline authoring requires tooling — either a Godot editor plugin or a Blender export pipeline.
- **Tradeoff:** Spline-based AI pathing is more complex than waypoint-following but produces smoother, more natural racing lines.
