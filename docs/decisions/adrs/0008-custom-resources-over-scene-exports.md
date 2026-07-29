# ADR 0008: Custom Resources Over Scene Exports for Persistent Data

## Status
Accepted

## Context

Godot scenes store exported properties directly in the `.tscn` file. This creates several problems:

1. **Scene corruption.** A corrupted `.tscn` loses both structure and data simultaneously. Data embedded in scene files cannot be recovered independently.
2. **No reuse.** An exported value on one scene (`@export var mana_value_percent: float = 0.05`) cannot be shared with another scene — each scene has its own copy. To reuse data, you must duplicate the scene or copy-paste values.
3. **No repurposing.** A `.tscn` is a monolithic unit. You cannot take the data from one pickup scene and apply it to a different pickup scene without editing each individually.
4. **Scatter risk.** When data is split across many scene exports, there is no single source of truth. Changing a value means finding every scene that has it exported and updating each one.

The alternative — custom `Resource` subclasses serialized as `.tres` files — solves all of these but introduces the risk of accidental resource mutation at runtime (since Resources are shared references).

## Decision

### Data lives in Resources, not scene exports

Any value that represents **persistent data** (not scene-specific wiring) must be defined in a custom `Resource` class and serialized as a `.tres` file.

| Use `@export` on a node for | Use a custom Resource for |
|---|---|
| Node references (e.g., `@export var spawn_point: Marker3D`) | Data values (e.g., `mana_value_percent`, `respawn_time`) |
| Scene-specific toggles (e.g., `@export var loop: bool`) | Reusable configuration (e.g., pickup stats, vehicle stats) |
| One-off tweaks per instance | Any value that could be shared across scenes |

### Resources are read-only at runtime

A `.tres` file is a shared template. Writing to it at runtime corrupts every scene that references it. **The only exception is `@tool` scripts** that generate or edit resources in the editor context.

Per-instance variation of a resource-backed value uses a shadow property on the instance, not a mutation of the Resource:

```gdscript
# WRONG — mutates the shared .tres for all consumers
crystal.crystal_data.mana_value_percent = 0.03

# RIGHT — instance-level override, Resource stays pristine
crystal.override_percent = 0.03
```

### One scene, N data files

Scenes are generic shells. Data drives appearance, behavior, and configuration. A single `mana_crystal.tscn` works with any number of `.tres` presets (`mana_crystal_small.tres`, `mana_crystal_large.tres`, etc.). New variants are created by duplicating a `.tres` file — the scene never needs to change.

### Initialization pattern

Every scene that consumes a data Resource reads it in `_ready()` via an `_apply_data()` method:

```gdscript
@export var crystal_data: ManaCrystalResource

func _ready():
    if crystal_data:
        _apply_data()

func _apply_data():
    sprite.texture = crystal_data.sprite
    respawn_timer.wait_time = crystal_data.respawn_time
```

For runtime spawning, assign the export before `add_child()` — `_ready()` picks it up:

```gdscript
var crystal = mana_crystal_scene.instantiate()
crystal.crystal_data = preload("res://Content/Data/pickups/mana_crystal_small.tres")
add_child(crystal)   # _ready() fires, reads crystal_data
```

## Consequences

- **Positive:** Data survives scene corruption independently. A pickup `.tres` can be reassigned to a different scene without data loss.
- **Positive:** One scene file works with infinite data variants. Adding a new pickup type is a `.tres` copy + edit, no scene work.
- **Positive:** Single source of truth. Changing `mana_crystal_small.tres` updates every scene that references it.
- **Positive:** Data can be repurposed — the same `.tres` can drive pickups, UI displays, or game logic.
- **Tradeoff:** More files on disk (`.tscn` + N `.tres` files instead of one `.tscn` with inline values).
- **Tradeoff:** Requires discipline to never mutate Resources at runtime. Violations are silent and corrupt shared state — the rule must be enforced in code review.
- **Tradeoff:** Slightly more indirection at instantiation time (assign a Resource reference instead of setting raw values).
