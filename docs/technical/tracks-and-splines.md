# Spline System — Technical Reference

> **Design intent:** See `docs/game-design/tracks/track-layout.md` for the what and why — cyclic/non-cyclic rules, branching path constraints, waypoint gating concept, AI pathing strategy, and modular chunk stitching.

Tracks are defined by **splines** — 3D curves encoding the racing line, lap progression, AI pathing, minimap display, and respawn points. A spline is a `Resource` with one main path and zero or more alternate paths. Point 0 is the start/finish line. Cyclic tracks wrap last→first; non-cyclic (rally) tracks run point 0→last, always 1 lap. Branching paths connect at split/join points with max 2 splits and 4 joins per point.

---

## Spline Resource Structure

The spline lives in a `systems/track/spline.gd` class that extends `Resource`, saved as `.tres` in `Content/Tracks/<name>/`.

```gdscript
# systems/track/spline.gd
class_name Spline extends Resource

@export var paths: Array[SplinePath]
@export var main_path_index: int = 0
@export var cyclic: bool = true

func get_main() -> SplinePath:
    return paths[main_path_index]

func get_path(index: int) -> SplinePath:
    return paths[index]
```

Each `SplinePath` holds an array of control points and metadata about branch connections:

```gdscript
class_name SplinePath extends Resource

@export var points: Array[SplinePoint]
@export var branches: Array[BranchConnection]  # points where other paths connect
```

### BranchConnection

```gdscript
class BranchConnection:
    var from_path_index: int   # this path
    var from_point_index: int  # point on this path where branch starts
    var to_path_index: int     # target path
    var to_point_index: int    # point on target path where branch ends
    var is_split: bool         # true = branch diverges, false = branch rejoins
```

---

## Per-Point Data Format

Each `SplinePoint` stores the following fields:

```gdscript
class SplinePoint:
    var position: Vector3       # world-space location
    var normal: Vector3         # surface up direction at this point
    var width: float            # track width in meters (left + right from center)
    var banking: float          # roll angle in radians (positive = right-side down)
    var flags: int              # bitfield for point type
```

### Flags Bitfield

```gdscript
enum SplinePointFlags:
    NONE          = 0
    START_FINISH  = 1 << 0  # lap line
    WAYPOINT      = 1 << 1  # lap-gating waypoint
    RESPAWN       = 1 << 2  # valid respawn location
    BRANCH_SPLIT  = 1 << 3  # AI hint: path splits here
    BRANCH_JOIN   = 1 << 4  # AI hint: paths merge here
    PIT_ENTRY     = 1 << 5  # pit lane entrance
    PIT_EXIT      = 1 << 6  # pit lane exit
```

### Width Encoding

`width` is a single float representing half-width (radius from center line). The actual playable surface extends `width` units to the left and right of the center line. This is interpolated between points so tracks can narrow (tunnel entrances) and widen (straights, pit areas).

### Banking

`banking` is the roll angle around the forward direction, in radians. Positive = right side tilts down (like a banked NASCAR turn). Interpolated between points. Banking rotates the surface normal as well.

### Surface Normal

`normal` is the world-space up vector at this point. On flat ground this is `(0, 1, 0)`. On walls or loop sections it rotates to match the surface. The hover system's raycasts use this to determine which direction is "down" when the pod is over this section.

---

## Spline Traversal

### Sampling at Parameter t

The primary operation: given a float `t` in `[0, 1]`, return the interpolated point data.

```gdscript
func sample(t: float) -> SplineSample:
    var path = get_main()
    var count = path.points.size()
    # Convert t to point index + fractional blend
    var total_segments = cyclic ? count : count - 1
    var raw_index = t * total_segments
    var i = floori(raw_index) % count
    var frac = raw_index - floor(raw_index)
    return interpolate(path, i, (i + 1) % count, frac)

func interpolate(path: SplinePath, a: int, b: int, frac: float) -> SplineSample:
    var p0 = path.points[a]
    var p1 = path.points[b]
    return SplineSample.new(
        p0.position.lerp(p1.position, frac),          # position
        p0.normal.slerp(p1.normal, frac).normalized(),# normal
        lerpf(p0.width, p1.width, frac),              # width
        lerpf(p0.banking, p1.banking, frac),          # banking
        a                                              # segment_index
    )
```

For **Catmull-Rom** (smoother curves), interpolate between 4 consecutive points:

```gdscript
func sample_catmull(t: float) -> SplineSample:
    var path = get_main()
    var count = path.points.size()
    var total_segments = cyclic ? count : count - 1
    var raw_index = t * total_segments
    var i = floori(raw_index)
    var frac = raw_index - i
    var p0 = path.points[(i - 1 + count) % count]
    var p1 = path.points[i % count]
    var p2 = path.points[(i + 1) % count]
    var p3 = path.points[(i + 2) % count]
    var pos = catmull_rom(p0.position, p1.position, p2.position, p3.position, frac)
    var nrm = catmull_rom(p0.normal, p1.normal, p2.normal, p3.normal, frac).normalized()
    var w = catmull_rom_float(p0.width, p1.width, p2.width, p3.width, frac)
    var bank = catmull_rom_float(p0.banking, p1.banking, p2.banking, p3.banking, frac)
    return SplineSample.new(pos, nrm, w, bank, i % count)
```

### SplineSample

```gdscript
class SplineSample:
    var position: Vector3
    var normal: Vector3
    var width: float
    var banking: float
    var segment_index: int

    # Derived
    func forward() -> Vector3:   # forward direction (tangent)
        pass  # computed externally from consecutive samples
    func right() -> Vector3:     # right lateral = forward × normal
        return forward().cross(normal).normalized()
    func left() -> Vector3:
        return -right()
```

Forward direction is derived by sampling two close t-values and subtracting:

```gdscript
func sample_forward(t: float, delta: float = 0.001) -> Vector3:
    var a = sample(t - delta).position
    var b = sample(t + delta).position
    return (b - a).normalized()
```

### Projecting World Position onto Spline

Given a racer's world position, find the nearest t on the spline. Needed for lap tracking and AI.

```gdscript
func project(point: Vector3, start_t: float = 0.0, search_range: float = 0.25) -> float:
    # Brute-force search: sample at N intervals, find closest, refine with binary search
    var best_t = start_t
    var best_dist = INF
    var samples = 64
    for i in samples:
        var t = start_t - search_range + (2.0 * search_range * i / samples)
        t = wrapf(t, 0.0, 1.0) if cyclic else clampf(t, 0.0, 1.0)
        var s = sample(t)
        var d = point.distance_squared_to(s.position)
        if d < best_dist:
            best_dist = d
            best_t = t
    # Binary refinement (4 iterations)
    var step = search_range / samples
    for _ in 4:
        step *= 0.5
        for offset in [-step, step]:
            var t = wrapf(best_t + offset, 0.0, 1.0) if cyclic else clampf(best_t + offset, 0.0, 1.0)
            var d = point.distance_squared_to(sample(t).position)
            if d < best_dist:
                best_dist = d
                best_t = t
    return best_t
```

The `start_t` parameter seeds the search with the racer's last-known t (from the previous frame). This makes projection fast and stable — a racer can't teleport to the other side of the track in one frame, so the search window stays tight.

### Total Length

```gdscript
func total_length(samples_per_segment: int = 4) -> float:
    var total = 0.0
    var path = get_main()
    var steps = path.points.size() * samples_per_segment
    var prev = sample(0.0).position
    for i in steps:
        var t = float(i + 1) / steps
        var pos = sample(t).position
        total += prev.distance_to(pos)
        prev = pos
    return total
```

---

## Waypoint Gating

Waypoints are defined at strategic t-values (before splits, after merges, at start/finish). Each stores its t-position, sequence index, and activation radius:

```gdscript
class WaypointData:
    var spline_t: float          # position on main spline
    var index: int               # sequence order (0, 1, 2, ...)
    var activation_radius: float # how close the racer must pass to count
```

A racer's lap progress is tracked as:

```gdscript
var last_cleared_waypoint: int = -1   # index of most recent waypoint passed
var lap_count: int = 0
var spline_t: float = 0.0             # current projected position on main spline
```

Each frame:

```gdscript
func update_lap_progress(racer_t: float):
    # Find the next waypoint the racer should clear
    var next_wp = waypoints[last_cleared_waypoint + 1]

    # Check if racer has passed it (moving forward)
    if racer_t > next_wp.spline_t - next_wp.activation_radius:
        last_cleared_waypoint += 1

        # If we cleared the last waypoint AND crossed start/finish, lap complete
        if last_cleared_waypoint == waypoints.size() - 1:
            if crossed_start_finish(racer_t):
                lap_count += 1
                last_cleared_waypoint = -1  # reset for next lap
```

Key rule: **only forward progression counts**. If `racer_t` drops below the last-cleared waypoint (e.g. going backward), nothing happens — the waypoint is NOT de-cleared. This prevents lap fraud via reverse driving.

Branching paths are naturally handled: a racer who takes a shortcut that exits past the next waypoint's t-value will clear that waypoint when they pass its t-threshold on the main spline. No special branch logic needed.

---

## AI Sampling

### Lookahead Target

```gdscript
func get_ai_target(racer_t: float, lookahead_distance: float) -> Vector3:
    # Convert linear lookahead distance to a t delta
    var total_len = total_length()
    var t_delta = lookahead_distance / total_len
    var target_t = racer_t + t_delta
    if cyclic:
        target_t = fmod(target_t, 1.0)
    else:
        target_t = min(target_t, 1.0)
    return sample(target_t).position
```

`lookahead_distance` is the key difficulty parameter:
- **Easy AI:** long lookahead (smoother, slower reaction to curves → wider turns, slower cornering)
- **Hard AI:** short lookahead (tighter line, brakes earlier, accelerates sooner out of turns)

The AI's `AiLookAhead` stat (from EP1R data at struct offset 264) is stored as a **squared distance** — the debug menu applies `sqrt()` at display time. Internally this means `lookahead_distance = sqrt(ai_lookahead_squared)`.

### Steering Toward Target

```gdscript
func get_steering_input(racer_position: Vector3, target: Vector3, forward: Vector3) -> float:
    var to_target = (target - racer_position).normalized()
    var cross = forward.cross(to_target)
    # cross.y > 0 = target is to the right, < 0 = to the left
    return clampf(cross.y * steering_gain, -1.0, 1.0)
```

### Branch Path Selection

When approaching a `BRANCH_SPLIT` point, the AI evaluates all downstream paths:

```gdscript
func select_branch(racer_t: float, ai_difficulty: float) -> int:
    var branch_point = find_nearest_branch(racer_t)
    if branch_point == null:
        return -1

    var best_path = -1
    var best_score = -INF

    for conn in branch_point.connections:
        var target_path = paths[conn.to_path_index]
        var remaining_distance = estimate_path_distance(target_path, conn.to_point_index)
        var shortcut_bonus = 0.0
        if remaining_distance < estimate_main_distance(branch_point.from_point_index):
            shortcut_bonus = 20.0  # reward shortcuts

        var risk = 0.0
        if conn.is_split:
            risk = evaluate_path_risk(target_path, conn.to_point_index)

        # Higher difficulty AI weighs shortcut bonus more, risk less
        var score = shortcut_bonus * ai_difficulty - risk * (1.0 - ai_difficulty)
        if score > best_score:
            best_score = score
            best_path = conn.to_path_index

    return best_path
```

### Boost Decision

AI boosts when:
1. The upcoming segment is straight (low curvature for the next ~0.5s of travel)
2. Heat is below 70%
3. Not actively braking for a turn

### Brake Decision

AI brakes when:
1. Upcoming curvature exceeds a threshold (tight turn ahead)
2. Current speed would make the turn impossible to hold
3. Lookahead point is within a danger zone (approaching another racer from behind at higher speed)

---

## Minimap Rendering

The minimap is a 2D projection of the 3D spline. It shows the track layout from a top-down view, never terrain, always oriented "up" (not rotating with the camera).

### Flattening 3D to 2D

```gdscript
func flatten_to_2d(step_count: int = 200) -> PackedVector2Array:
    var points_2d: PackedVector2Array = []
    var bounds = compute_bounds()
    var size = max(bounds.size.x, bounds.size.z)

    for i in step_count:
        var t = float(i) / step_count
        var s = sample(t)
        # Drop Y (height), keep X and Z
        var flat = Vector2(s.position.x, s.position.z)
        # Normalize to [0, 1] relative to track bounds
        flat.x = (flat.x - bounds.position.x) / size
        flat.y = (flat.y - bounds.position.z) / size
        points_2d.append(flat)

    return points_2d
```

The flattened points are rendered as a line (or filled polygon using width data). The minimap texture is generated once per track at load time and cached.

### Four Minimap Modes

1. **Spline zoomed out:** Full-track view — all paths visible at once. Cyclic tracks show the entire loop. Useful for overview.

2. **Spline zoomed in:** Close-up around the player (20-30% of the total spline centered on the player's current t). Shows upcoming turns and nearby racers. The camera framing follows the player's t.

3. **Vertical position comparison:** Side-view projection (Y vs Z or Y vs X). Shows altitude differences — who's above/below. Useful on tracks with elevation changes, multi-level sections, and shortcuts that go over/under.

4. **Screen-circling progress map:** The spline is drawn as an arc on the edge of the screen (like a bezel). Each racer is a dot on this arc. Shows relative position at a glance without taking up screen center. The arc fills clockwise as the race progresses (0% → 100%).

### Minimap Orientation

All modes are **always oriented "up"** — north-up relative to the track, not rotating with the camera or pod. This gives a stable spatial reference.

### Rear-View Mirror

The minimap mirrors in the rear-view camera (when look-behind is held). The minimap itself is horizontally flipped for the rear-view display, matching the driver's reversed perspective.

---

## Respawn Points

Respawn points are `SplinePoint` entries flagged `RESPAWN`. On crash or out-of-bounds:

```gdscript
func get_respawn_position(racer) -> Transform3D:
    var wp_index = racer.last_cleared_waypoint
    var t = waypoints[wp_index].spline_t
    var s = sample(t)
    var fwd = sample_forward(t)
    # Place pod at center of track, at the spline position, facing forward
    var pos = s.position + s.normal * hover_height
    var basis = Basis.looking_at(fwd, s.normal)
    return Transform3D(basis, pos)
```

---

## Authoring Pipeline

Spline data is authored in two ways:

1. **Godot editor plugin** — a custom `@tool` script in `addons/spline_editor/` that lets designers place and edit spline points in the 3D viewport. The plugin serializes to the `Spline` resource format.

2. **Runtime assembly** (modular tracks) — a track definition references a sequence of segment `.tscn` files plus connection metadata. At load time, the segment meshes are stitched and a new `Spline` resource is assembled from the segment endpoints. This is how the modular chunk system works.

The `Spline` resource is a standalone `.tres` file, not embedded in the scene. This allows the same spline to be shared between gameplay logic and editor tooling, and enables runtime spline assembly.

---

## Summary

- `SplinePoint` stores position, normal, width, banking, and flags
- Interpolation is straight lerp or Catmull-Rom for smooth curves
- `project()` uses last-known-t seeding for fast nearest-point lookups
- Waypoint gating at strategic t-values enables branching paths and shortcuts
- AI uses lookahead distance (squared internally per EP1R) for difficulty scaling
- Minimap flattens X/Z, drops Y, always orients up
- 4 minimap modes: zoomed out, zoomed in, vertical comparison, screen-circling
- Respawns snap to nearest cleared waypoint, center of track
