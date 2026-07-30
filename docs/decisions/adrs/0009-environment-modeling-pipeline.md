# ADR 0009: Environment Modeling Pipeline — GLB-Only, No Wrapper Scenes

## Status
Accepted

## Context

Early in the project, environment models (doodads, terrain props) went through a pipeline that generated separate `.tscn` wrapper scenes:

1. Maya → `.glb`
2. Generator script reads `.glb`, bakes trimesh collision shapes
3. Generator writes a new `.tscn` with a `StaticBody3D` root + `CollisionShape3D` children + `[instance]` of the `.glb`
4. Levels reference the wrapper `.tscn`

This created a persistent desync problem: when the `.glb` was re-exported from Maya, the wrapper `.tscn` contained stale collision data. An import script and later an EditorPlugin were attempted to auto-regenerate on reimport, but writing companion files from within the import pipeline caused recursive reimport errors.

The fundamental issue was treating the `.glb` as a "raw asset" that needed a separate physics wrapper, rather than treating it as a self-contained scene.

## Decision

### Environment `.glb` files are used directly as scenes

No wrapper `.tscn` files, no import scripts, no EditorPlugin. Each `.glb` is dragged directly into levels and works out of the box.

### Structure in the Import settings

The `.glb` root keeps its imported type (typically `Node3D` or whatever the DCC exported). **The root is NOT changed to `StaticBody3D`.**

Physics is configured through Godot's built-in import settings:

- Per-`MeshInstance3D` nodes are set to generate collision in the Import dock's node tree
- Each mesh generates a `StaticBody3D` + `CollisionShape3D` child nested under the visual node

The resulting hierarchy in every level instance is:

```
.glb root (Node3D)
├── MeshInstance3D "trunk"
│   └── StaticBody3D (collision)
│       └── CollisionShape3D
└── MeshInstance3D "leaves"
    └── StaticBody3D (collision)
        └── CollisionShape3D
```

### Why this works for static environment props

The common rule "root must be a physics body" applies to **dynamic entities** (`CharacterBody3D`, `RigidBody3D`), where:

- `move_and_slide()` / forces / impulses move the `CollisionObject3D` node's transform. A `RigidBody3D` buried under a generic `Node3D` would move its child while leaving the root behind, causing transform desync.
- Dynamic simulation requires predictable center-of-mass calculations relative to the body's local origin. Nested transforms make this unpredictable.

For **static environment props**, none of this applies:

- `StaticBody3D` collision shapes are calculated in world space by the physics engine. Tree depth has no effect on performance or collision detection.
- The colliders are never moved at runtime — they exist only to provide collision surfaces for dynamic bodies.

### Maya export pipeline

Models are exported from Maya using a MEL script that wraps the BabylonJS glTF exporter:

- Select any group or mesh
- One button press
- Script originates the selection (resets transforms to identity)
- Exports a clean `.glb`

Godot detects the file change on disk, reimports the `.glb`, and every level instance that references it automatically picks up both the updated geometry **and** regenerated collision shapes.

## Consequences

- **Positive:** No desync between visual mesh and collision data — they're generated from the same import pass.
- **Positive:** No wrapper `.tscn` files to manage, delete, or regenerate.
- **Positive:** Zero manual steps after initial import configuration. Maya export → Godot reimport is fully automatic.
- **Positive:** Levels reference `.glb` files directly. When the source changes, every instance across all levels updates simultaneously.
- **Positive:** No import scripts or EditorPlugins to maintain.
- **Tradeoff:** Each `.glb` must have its Import settings configured once — per-node collision generation is not inherited from a template.
- **Tradeoff:** The nested `StaticBody3D` children under visual nodes is unconventional and may surprise developers accustomed to flat `StaticBody3D` hierarchies. This is harmless for static geometry but would be incorrect for dynamic bodies.
