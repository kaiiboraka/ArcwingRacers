# Model & Level Setup Checklist

> Reference reminder for the steps taken every time a new **model** is imported or a new **level** is built. Companion to ADR 0009 (`../decisions/adrs/0009-environment-modeling-pipeline.md`): that ADR records *why* `.glb` files are used directly with import-time collision; this note is the exact per-node/per-resource settings to apply in the Import dock and Scene tree.

Apply the settings below under Import → per-node (the Import dock shows a node tree when the imported scene is open).

---

## Import scenes (the `.glb` / `.fbx` root)

Both static `.glb` and dynamic/animated `.fbx` imports must have:

| Setting | Value | Notes |
|---|---|---|
| **Generate LODs** | ON | default |
| **Create Shadow Meshes** | ON | default |
| **Light Baking** | **Static Lightmaps** | ⚠️ not the default — normally just "Static" |
| **Lightmap texel size** | **0.2** | default |
| **Animation Import** | **Off** | |
| **Materials Extract** | **Keep Internal** | default |

---

## Per `MeshInstance3D`

| Setting | Value | Notes |
|---|---|---|
| **Generate Physics** | ON | |
| **Occluder** | **Mesh + Occluder** for LARGE objects, else **Disabled** (default) | |
| **Physics** | `BodyType: StaticBody3D` (usually) | |
| **Physics → ShapeType** | **Decompose Convex** for shape accuracy, **Single Convex** for a general shape, else **Box** / **Cylinder** based on shape | |
| **Layer** | set to the appropriate physics layers | |
| **Visibility Range → End** | **1000 m** | |
| **Visibility Range → End Margin** | **100 m** | |
| **Visibility Range → Fade Mode** | **Disabled** (default) | |
| **Occluder Simplification Distance** | **0.1** (default) | see below |

### Occluder Simplification Distance

Uses 3D units (meters). Dictates the distance threshold for merging vertices on the generated occluder mesh.

Godot renders occluders on CPU. Fewer vertices equals faster frame times. Low-resolution internal buffer means perfect shape matching is unnecessary.

- **0.1 (Default)** — Aggressive simplification. Merges vertices within 10 cm. Good baseline. Use for standard terrain slabs and thick walls.
- **0.01** — Conservative simplification. Keeps shape perceptually identical to the visual mesh. Use if the default (0.1) causes false negatives — visible objects popping out of existence near mesh edges.
- **0.0** — Disables distance simplification; only merges exact duplicate vertices. Avoid; causes high CPU load. Use only for a custom, hand-optimized low-poly proxy mesh.
- **2.0 (Max)** — Extreme simplification. Merges vertices within 2 m; destroys edge shapes. Only for colossal, solid background structures (entire mountains) where the exact silhouette is irrelevant.

**Strategy:** push the value higher until false negatives occur, then stop and lower slightly. Maximize the value to save CPU. *(The user holds final judgment on any value change.)*

---

## Per Mesh

| Setting | Value |
|---|---|
| **Generate → Shadow Meshes** | Enable |
| **Generate → Lightmap UV** | Enable |
| **Generate → LODs** | Enable |
| **Must have a dummy material assigned in Maya** | |

---

## Per Material

| Setting | Value |
|---|---|
| **Use External** | Enabled: **On** |
| **Path** | `Content/Materials/M_<material-name>.tres` |

---

## Per Level

Every level built:

- **Skybox scene** — premade; has the skybox preview script and lets the sky texture be switched easily. Contains:
  - a **Directional Light** that must be customized to match the skybox light source;
  - **WorldEnvironment** settings including the **fog** that must also be customized.
- **LightmapGI** — set **Quality: High**. Supersampling not necessarily needed.
- **TrackSpline** — routes created for all paths the AI must take or that need to be on the minimap.
- **StartingLine** scene.
- **WorldFloor** — not a scene yet; planned. A `StaticBody3D` with a `WorldBoundary` node for the ground, plus matching nodes for the 4 outer walls of the level (one per lateral direction) so there is no out-of-bounds sideways.
- The actual level doodads and terrain.

### After the level geometry changes

After significantly changing the level geometry, select the **LightmapGI** node and click **Bake Lightmaps**, then physically rerun it.

---

## Open Items

- TODO: track spline data needs a flag for whether a spline should be included on the minimap. Some spline data will exist for secret shortcuts that should be hidden from the map.