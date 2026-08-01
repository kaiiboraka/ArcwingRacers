# Spline System — Technical Reference

> **Design intent:** See `docs/game-design/tracks/track-layout.md` for the what and why — cyclic/non-cyclic rules, branching path constraints, waypoint gating concept, AI pathing strategy, and modular chunk stitching.
>
> **Architecture decision:** See ADR 0010 (`docs/decisions/adrs/0010-spline-curve3d-and-segment-recipes.md`). The spline extends Godot's `Curve3D` and carries parallel per-point metadata arrays; per-segment mesh recipes decide where geometry is generated vs. where modeled terrain stands.

Tracks are defined by **splines** — 3D curves encoding the racing line, lap progression, AI pathing, minimap display, and respawn points. A spline is a `Curve3D`-derived `Resource` with one main path and zero or more alternate paths. Point 0 is the start/finish line. Cyclic tracks wrap last→first; non-cyclic (rally) tracks run point 0→last, always 1 lap. Branching paths connect at split/join points with max 2 splits and 4 joins per point.

The spline is only the **racing structure**, not the whole level. Recipes generate road/tunnel geometry where flagged; open shortcut terrain and bespoke set-pieces are modeled `.glb` assets that coexist as separate physics bodies (see ADR 0009). The AI never drives off-spline space.

---

## Spline Resource Structure

The spline lives in `Systems/Track/spline.gd` as a class extending `Curve3D`, saved as `.tres` in `Content/Tracks/<name>/`.

```gdscript
# Systems/Track/spline.gd
class_name Spline extends Curve3D

## Per-point half-width (left + right from center line), meters.
@export var point_widths: PackedFloat32Array
## Per-point mesh recipe (ROAD / TUNNEL / NONE).
@export var point_recipes: Array[int]
## Per-point recipe scalar (e.g. tunnel height in meters). Ignored for ROAD/NONE.
@export var point_recipe_params: Array[float]
## Per-point flags bitfield (START_FINISH, WAYPOINT, RESPAWN, BRANCH_*).
@export var point_flags: Array[int]

@export var cyclic: bool = true
```

All metadata arrays are indexed 1:1 with `Curve3D.point_count`. Native `Curve3D` methods (`add_point`, `remove_point`, `set_point_count`, `clear_points`) **cannot be overridden in GDScript** — the engine calls its internal C++ implementation directly, so script overrides are never invoked. Instead the `Spline` resource subscribes to `Curve3D.changed`, which the engine emits on every mutation (add/remove/move point, bake, tilt, closed), and reconciles the metadata arrays to `point_count` in the handler. This covers every edit path, including Path3D gizmo editing. Accessors also reconcile lazily as a safety net. See the `spline.gd` implementation for the sync contract.

### BranchConnection

Branches (multiple paths per track) are **deferred** — ADR 0010 keeps the first pass to a single main path. When branches land, they follow the model from ADR 0005:

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

`Curve3D` provides per-point **position**, **in/out handles** (Catmull-Rom/Cubic smoothing), and **tilt** (rotation about the forward axis). Our metadata adds the rest:

| Field | Source | Meaning |
|---|---|---|
| `position` | `Curve3D` | World-space location of the point |
| `in` / `out` | `Curve3D` | Curve smoothing handles (leave zero for raw spline) |
| `tilt` | `Curve3D` | Banking — roll angle in radians, positive = right-side down |
| `width` | `point_widths[i]` | Track half-width in meters (left + right from center) |
| `recipe` | `point_recipes[i]` | Mesh to generate on the span AFTER this point |
| `recipe_param` | `point_recipe_params[i]` | Per-recipe scalar (e.g. tunnel height) |
| `flags` | `point_flags[i]` | Bitfield for point type |
| `normal` | derived | Surface up direction, from tangent × tilt (see below) |

### Width Encoding

`width` is a single float representing half-width (radius from center line). The actual playable surface extends `width` units to the left and right of the center line. Interpolated between points so tracks can narrow (tunnel entrances) and widen (straights, pit areas).

### Banking

`banking` is stored as `Curve3D` tilt — the roll angle around the forward direction, in radians. Positive = right side tilts down (like a banked NASCAR turn). Interpolated between points. Banking rotates the surface normal as well.

### Surface Normal

The surface up vector at a sample is derived from the forward tangent and the banked lateral:

```gdscript
func sample_normal(sample_pos: Vector3, forward: Vector3, bank: float) -> Vector3:
    var lateral = forward.cross(Vector3.UP).normalized()
    var rot = Basis(forward, bank)
    return rot * lateral.cross(forward).normalized()
```

On flat ground this is `(0, 1, 0)`. On walls or loop sections it rotates to match the surface. The hover system's raycasts use this to determine which direction is "down" when the pod is over this section. **Note:** the current hover raycasts in `PodController.gd` align to world up — reading spline banking into the hover system is the pending banking-model work in `technical/pod-hover-system.md`.

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

### Segment Recipes

`point_recipes[i]` names the mesh the generator builds on the span from point `i` to point `i+1`:

| Recipe | Generated geometry | Extra param |
|---|---|---|
| `NONE` | Nothing — modeled terrain stands as-is. Spline still drives racing line / AI / lap / respawn here. | — |
| `ROAD` | Ribbon surface + side walls, width from `point_widths`, following spline (banking via tilt). | — |
| `TUNNEL` | Ribbon + side walls + roof (tube), width from `point_widths`. | `recipe_param[i]` = tunnel height in meters |

Spans between two flagged points infer their recipe from the trailing point. Recipe metadata is read by the generator (see **Mesh Generation** below) and by gameplay only through flags.

---

## Spline Traversal

Because `Spline extends Curve3D`, traversal uses Godot's baked sampling rather than hand-rolled math. Configure baking explicitly — the system's fidelity (banking/tunnel interpolation) depends on it:

```gdscript
@export var bake_interval: float = 0.25   # meters between baked samples
@export var baking_cubic: bool = true      # cubic (Catmull-Rom) vs linear
```

### Sampling at Offset

**Curve3D baked sampling is local-space** — positions come back relative to the curve's owning `Path3D` origin, and query points must be converted into that local space first. Use the world-space wrappers on `TrackSpline` (`sample_world`, `sample_forward_world`, `sample_normal_world`, `project_world`) for gameplay queries.

```gdscript
# World-space position at a distance along the spline (via the TrackSpline node)
var pos: Vector3 = track_spline.sample_world(offset)
# World-space forward direction at a distance
var fwd: Vector3 = track_spline.sample_forward_world(offset)
# World-space up vector (normal) at a distance
var up: Vector3 = track_spline.sample_normal_world(offset)
```

Raw local-space access (mesh generation, which runs in the spline's own frame) uses the `Spline`/`Curve3D` methods directly:

```gdscript
var spline: Spline = track_spline.get_spline()
var local_pos: Vector3 = spline.sample_baked(offset, true)   # cubic
var local_fwd: Vector3 = spline.sample_forward(offset)        # tangent, local
```

Forward direction can be derived from two close samples:

```gdscript
func sample_forward(spline: Spline, offset: float, delta: float = 0.01) -> Vector3:
    var a = spline.sample_baked(offset - delta)
    var b = spline.sample_baked(offset + delta)
    return (b - a).normalized()
```

### Projecting World Position onto Spline

`Curve3D` provides this natively with `get_closest_point()` / `get_closest_offset()`, both **local-space**:

```gdscript
# World point → nearest offset on the spline (via the TrackSpline node)
var offset: float = track_spline.project_world(world_point)

# Raw local-space equivalent (world_to_local first)
var local_point: Vector3 = track_spline.to_local(world_point)
var local_offset: float = spline.get_closest_offset(local_point)
```

For cyclic tracks, wrap the returned offset into `[0, total_length)` when comparing lap progress.

### Total Length

```gdscript
var total_len: float = spline.get_baked_length()
```

### Parameter t vs. Offset

Older drafts of this doc used a normalized `t ∈ [0,1]`. With `Curve3D`, prefer **absolute offset in meters** (`get_closest_offset`, `sample_baked`) — it is what the engine bakes and what `get_closest_offset` returns. Convert to/from normalized `t` only where a formula calls for it:

```gdscript
func t_to_offset(spline: Spline, t: float) -> float:
    return t * spline.get_baked_length()

func offset_to_t(spline: Spline, offset: float) -> float:
    return offset / spline.get_baked_length() if spline.get_baked_length() > 0.0 else 0.0
```

---

## Mesh Generation

The generator (`Systems/Track/track_mesh_generator.gd`, `@tool`) bakes spline spans into `ArrayMesh`:

1. Sample the spline densely (bake interval), producing position + forward + normal + width + recipe per sample.
2. For each span, build a triangle strip: left/right edges offset by `width` along the (banked) lateral axis.
3. Extrude walls upward from the edges (ROAD), and a roof connecting the walls (TUNNEL, using `recipe_param` height).
4. Emit a `StaticBody3D` + `CollisionShape3D` (trimesh) mirroring the visual mesh — this is the physical ground the pod hovers over on generated sections.

Generated geometry is exported to `.glb` via `GLTFDocument` when a section should be polished in a DCC; otherwise it regenerates from the spline on edit.

---

## Waypoint Gating

Waypoints are defined at strategic offsets (before splits, after merges, at start/finish). Each stores its spline offset, sequence index, and activation radius:

```gdscript
class WaypointData:
    var spline_offset: float       # distance along spline
    var index: int                 # sequence order (0, 1, 2, ...)
    var activation_radius: float   # how close the racer must pass to count
```

A racer's lap progress is tracked as:

```gdscript
var last_cleared_waypoint: int = -1   # index of most recent waypoint passed
var lap_count: int = 0
var spline_offset: float = 0.0        # current projected offset on spline
```

Each frame:

```gdscript
func update_lap_progress(racer_offset: float):
    var next_wp = waypoints[last_cleared_waypoint + 1]
    if racer_offset > next_wp.spline_offset - next_wp.activation_radius:
        last_cleared_waypoint += 1
        if last_cleared_waypoint == waypoints.size() - 1:
            if crossed_start_finish(racer_offset):
                lap_count += 1
                last_cleared_waypoint = -1
```

Key rule: **only forward progression counts**. If `racer_offset` drops below the last-cleared waypoint (e.g. going backward), nothing happens — the waypoint is NOT de-cleared. This prevents lap fraud via reverse driving. Branching paths are naturally handled: a racer who takes a shortcut that exits past the next waypoint's offset clears that waypoint when they cross its threshold on the main spline.

---

## AI Sampling

### Lookahead Target

```gdscript
func get_ai_target(racer_offset: float, lookahead_distance: float) -> Vector3:
    var target_offset = racer_offset + lookahead_distance
    if cyclic:
        target_offset = fmod(target_offset, get_baked_length())
    else:
        target_offset = min(target_offset, get_baked_length())
    return sample_baked(target_offset)
```

`lookahead_distance` is the key difficulty parameter:
- **Easy AI:** long lookahead (smoother, slower reaction to curves → wider turns, slower cornering)
- **Hard AI:** short lookahead (tighter line, brakes earlier, accelerates sooner out of turns)

The AI's `AiLookAhead` stat (from EP1R data at struct offset 264) is stored as a **squared distance** — the debug menu applies `sqrt()` at display time. Internally `lookahead_distance = sqrt(ai_lookahead_squared)`.

### Steering Toward Target

```gdscript
func get_steering_input(racer_position: Vector3, target: Vector3, forward: Vector3) -> float:
    var to_target = (target - racer_position).normalized()
    var cross = forward.cross(to_target)
    # cross.y > 0 = target is to the right, < 0 = to the left
    return clampf(cross.y * steering_gain, -1.0, 1.0)
```

### Branch Path Selection

When approaching a `BRANCH_SPLIT` point, the AI evaluates all downstream paths (deferred until branches exist):

```gdscript
func select_branch(racer_offset: float, ai_difficulty: float) -> int:
    var branch_point = find_nearest_branch(racer_offset)
    if branch_point == null:
        return -1
    var best_path = -1
    var best_score = -INF
    for conn in branch_point.connections:
        var target_path = paths[conn.to_path_index]
        var remaining_distance = estimate_path_distance(target_path, conn.to_point_index)
        var shortcut_bonus = 0.0
        if remaining_distance < estimate_main_distance(branch_point.from_point_index):
            shortcut_bonus = 20.0
        var risk = 0.0
        if conn.is_split:
            risk = evaluate_path_risk(target_path, conn.to_point_index)
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

The minimap is a 2D projection of the 3D spline. It shows the track layout from a top-down view, never terrain. The minimap rotates so the player's forward direction is always "up" — the player is fixed at center, the map moves around them. See `technical/minimap.md` for the full implementation.

### Flattening 3D to 2D

```gdscript
func flatten_to_2d(spline: Spline, step_count: int = 200) -> PackedVector2Array:
    var points_2d: PackedVector2Array = []
    var length = spline.get_baked_length()
    var bounds = compute_bounds(spline)
    var size = max(bounds.size.x, bounds.size.z)
    for i in step_count:
        var offset = length * float(i) / step_count
        var pos = spline.sample_baked(offset)
        # Drop Y (height), keep X and Z
        var flat = Vector2(pos.x, pos.z)
        flat.x = (flat.x - bounds.position.x) / size
        flat.y = (flat.y - bounds.position.z) / size
        points_2d.append(flat)
    return points_2d
```

The 2D points are rendered procedurally each frame via `_draw()` — no pre-baked texture. See `technical/minimap.md` for the full rendering implementation.

### Four Minimap Modes

1. **Spline zoomed out:** Full spline visible in the minimap frame. Player is at center, map rotates so forward is "up."
2. **Spline zoomed in:** Same display, tighter zoom (~30% of total spline centered on player). Shows upcoming turns and nearby racers more precisely.
3. **Vertical position comparison:** A vertical bar chart on the right side of the screen. Player is fixed at center. Nearby racers appear as horizontal bars whose offset from center shows how far ahead/behind they are on the spline.
4. **Screen-circling progress map:** The entire spline is mapped to the screen perimeter. Each racer's icon orbits along the edge at their spline offset. Further-ahead positions have higher Z-index.

### Minimap Orientation

The minimap rotates so the player's forward direction is always "up." The player icon is fixed at center; the spline and other racers move around them. When the player looks behind, the minimap mirrors to maintain this orientation.

### Rear-View Mirror

When the player looks behind, the minimap still rotates so the player's forward direction is "up" — the minimap inverts to match the reversed camera direction, maintaining the consistent orientation rule.

---

## Respawn Points

Respawn points are points flagged `RESPAWN`. On crash or out-of-bounds:

```gdscript
func get_respawn_position(spline: Spline, racer) -> Transform3D:
    var wp_index = racer.last_cleared_waypoint
    var offset = waypoints[wp_index].spline_offset
    var pos = spline.sample_baked(offset)
    var fwd = sample_forward(spline, offset)
    var up = Vector3.UP
    # Place pod at center of track, at the spline position, facing forward
    var spawn_pos = pos + up * hover_height
    var basis = Basis.looking_at(fwd, up)
    return Transform3D(basis, spawn_pos)
```

---

## Authoring Pipeline

Spline data is authored in two ways:

1. **Editor-first (`Path3D` gizmos)** — a `Path3D` node in the level scene gets a `Spline` assigned to its `curve` property. The built-in `Path3D` editor gizmos place and move points in the 3D viewport. Per-point metadata (width, recipe, flags) is edited via the Inspector arrays; the `TrackSpline` node script (see `Systems/Track/track_spline.gd`) keeps the arrays synced on point edits and triggers re-generation of road geometry.

2. **Runtime assembly** (modular tracks) — a track definition references a sequence of segment `.tscn` files plus connection metadata. At load time, the segment meshes are stitched and a new `Spline` resource is assembled from the segment endpoints. This is how the modular chunk system works. (ADR 0010 defers branch/multi-path support; single-path assembly works today.)

The `Spline` resource is a standalone `.tres` file, not embedded in the scene. This allows the same spline to be shared between gameplay logic and editor tooling, and enables runtime spline assembly. **Recipes tagged `NONE` leave geometry to modeled `.glb` terrain (ADR 0009); recipes tagged `ROAD`/`TUNNEL` generate geometry from the spline.**

---

## Summary

- `Spline extends Curve3D` — geometry math and Path3D authoring come free from the engine
- Per-point metadata arrays (width, recipe, recipe param, flags) run parallel to `point_count`
- `tilt` = banking; `normal` derived from tangent × banked lateral
- Recipes (`NONE` / `ROAD` / `TUNNEL`) decide where geometry is generated vs. modeled terrain
- Generated road + modeled terrain coexist as separate physics bodies; pod hovers on whichever is present
- Traversal via `sample_baked`, `get_closest_offset`, `get_baked_length`; offsets in meters, not normalized `t`
- Waypoint gating at strategic offsets enables branching paths and shortcuts
- AI uses lookahead distance (squared internally per EP1R) for difficulty scaling
- Minimap flattens X/Z, drops Y, always orients up
- Respawns snap to nearest cleared waypoint, center of track
- Branches (multiple paths) deferred — see ADR 0010
