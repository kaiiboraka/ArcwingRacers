# ADR 0010: Spline as Curve3D-Extended Resource with Per-Segment Mesh Recipes

## Status
Accepted

## Context

ADR 0005 commits the project to a spline-based track system. That ADR left the authoring form open — it names two tradeoffs: "Spline authoring requires tooling — either a Godot editor plugin or a Blender export pipeline."

The open questions at implementation time:

1. **Spline data model.** `technical/tracks-and-splines.md` sketched `Spline extends Resource` with custom interpolation, projection, and length math. That reimplements what Godot's `Curve3D` already provides (baked sampling, closest-point projection, length, per-point tilt).
2. **Level geometry is bigger than the spline.** Levels are not flat skinny roads. They include open shortcut areas beside the road, hills, and alternate routes the AI never takes. The spline cannot be the sole source of the level mesh — it only describes the racing structure (road, tunnels, AI line, lap/respawn data). The surrounding space is modeled terrain.
3. **Generated mesh vs. modeled mesh.** The user's test level is awkwardly stitched duplicate meshes. The desire is to author criss-cross paths, ramps, tunnels, and tight turns with splines, while leaving open space and bespoke set-pieces to modeled `.glb` geometry.

## Decision

### 1. `Spline` extends `Curve3D`

The spline resource subclasses Godot's `Curve3D` instead of a bare `Resource`:

- Free geometry math: `sample_baked()`, `get_closest_point()`, `get_closest_offset()`, `get_baked_length()`, baked points.
- Free authoring: place a `Path3D` node, assign a `Spline` to its `curve` property, and the built-in `Path3D` editor gizmos edit the spline directly in the viewport. No custom editor plugin needed for point placement.
- Per-point `Curve3D` **tilt** maps directly to the spline's `banking` field — it is the surface roll angle at each point.

The spline carries **parallel per-point metadata arrays** that `Curve3D` does not model:

```gdscript
@export var point_widths: PackedFloat32Array   # half-width, left/right of center line
@export var point_recipes: Array[TrackSegmentRecipe]
@export var point_recipe_params: Array[float]  # per-recipe scalar (e.g. tunnel height)
@export var point_flags: Array[int]            # bitfield: START_FINISH, WAYPOINT, RESPAWN, ...
```

These are kept aligned with `point_count`. Native `Curve3D` methods cannot be overridden in GDScript (the engine calls its C++ implementation, ignoring script overrides), so alignment is driven by the resource's `changed` signal — `Curve3D` emits it on every point mutation — plus lazy repair on access (clamp index, pad on append).

### 2. Per-segment mesh recipes

Each point carries a `TrackSegmentRecipe` (an enum). Recipes describe what mesh the spline generator builds **between this point and the next**:

| Recipe | Meaning |
|---|---|
| `NONE` | No generated geometry — the modeled terrain/level mesh stands as-is. The spline still provides the racing line, AI path, and lap/respawn data here. |
| `ROAD` | Generate a flat ribbon surface + side walls, width from `point_widths`, follows the spline (including banking via tilt). |
| `TUNNEL` | Generate a tube: ribbon + side walls + roof, width and height from the point's recipe param. |

The spline is the **skeleton**: it generates geometry only where a recipe says so, and everywhere else the modeled `.glb` terrain owns the space. This is the hybrid the user described — spline freely used as track basis, with blank recipe segments falling through to authored models.

### 3. Generated road and modeled terrain coexist as separate physics bodies

Per ADR 0009, modeled terrain is `.glb` with per-mesh generated collision (nested `StaticBody3D` under visual nodes). Generated road segments are their own `StaticBody3D` + `CollisionShape3D` (trimesh) built from the spline ribbon.

The pod hovers via raycasts against whatever static bodies exist, so it does not care which body owns a given surface. Overlaps are harmless — the raycast reports the first hit. This resolves the "which is the ground" question: **both** are the ground, depending on where the player is.

### 4. Generated geometry round-trips to the DCC

Godot 4's built-in `GLTFDocument` can export generated `ArrayMesh` data to `.glb`. So a spline-generated road section can be baked into a `.glb` and opened in Maya/Blender for polish, then re-imported as modeled terrain if desired. The two pipelines are not one-way.

### 5. Spline remains the data source for gameplay

Regardless of recipe, every spline point feeds gameplay:

- Racing line / AI lookahead sampling (`sample_baked`)
- Lap gating and progress (waypoint flags, closest-point projection)
- Respawn positions (respawn flag + sample)
- Minimap flattening (X/Z projection)

Geometry generation is purely additive visual/physics output on top of this.

## Consequences

- **Positive:** No custom interpolation/projection/length math to write or maintain — `Curve3D` is battle-tested and used by the editor itself.
- **Positive:** Point authoring works out of the box with `Path3D` gizmos; the editor plugin surface area is limited to a generator (bake geometry) and inspector display of metadata.
- **Positive:** Levels gain open space naturally — the spline only describes racing structure, modeled terrain fills the rest.
- **Positive:** Hybrid per-segment recipes mean no forced all-or-nothing choice between generated and modeled geometry.
- **Tradeoff:** Parallel metadata arrays must stay aligned with `point_count`. Desync is repaired lazily on access, but a full re-sync after editor edits is required to keep the arrays trustworthy.
- **Tradeoff:** Generated trimesh collision for long tracks is heavier than hand-placed primitives; LOD / coarse-collision per-segment remains a future optimization.
- **Tradeoff:** `Curve3D` baking uses its own sampling parameters (`bake_interval`, cubic vs. linear); the track system must configure these explicitly or sampling fidelity for banking/tunnels may be coarse.
- **Supersedes part of:** `technical/tracks-and-splines.md`'s "Spline Resource Structure" and "Spline Traversal" sections, which assumed a custom `Resource` with hand-rolled Catmull-Rom. That doc must be updated to the `Curve3D`-based model (see follow-up).
