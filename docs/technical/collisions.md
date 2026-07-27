# Collisions

2D collision and physics-query correctness rules — gotchas that produce silent failures rather than errors. See `technical/code-standards.md` for the general 2D Physics, Rendering, & Camera conventions (movement via `CharacterBody2D`, layer/Z-index rules).

---

## Triggers

- `Area2D` detects entry/exit from any overlapping physics body — `StaticBody2D`, `CharacterBody2D`, `RigidBody2D` — as long as `monitoring` is enabled on the Area2D and `monitorable` is enabled on the target.
- Both sides must match `collision_layer`/`collision_mask` bits, or nothing fires — silently, with no warning.
- `BodyEntered`/`BodyExited` fire for physics bodies; `AreaEntered`/`AreaExited` fire for other Areas. Mixing these up (listening for `BodyEntered` on an Area-vs-Area setup) is a common "why doesn't my trigger fire" bug.

## Direct Collisions

- `CharacterBody2D` (see code-standards.md) exposes contact data via `GetSlideCollisionCount()`/`GetSlideCollision(index)` after `MoveAndSlide()` — no signal needed for kinematic-vs-kinematic contact.
- `RigidBody2D` contact reporting is off by default — `contact_monitor` must be enabled and `max_contacts_reported` raised above 0, or `body_entered`/`body_exited` never fire even with a real overlap.

## Query Correctness

- **Raycasts do not detect a collider the ray starts inside of, by default.** `PhysicsRayQueryParameters2D` has a `hit_from_inside` flag (default `false`) — set it `true` if a query legitimately needs to originate inside a shape.
- **`RayCast2D` nodes default to `enabled = false`.** A ray with no visible errors that never reports a hit — check this first.
- **`RayCast2D` nodes default to `collide_with_bodies = true`, `collide_with_areas = false`.** Flip `collide_with_areas` on deliberately if a sensor needs to catch Area2D triggers too.
- **`intersect_shape()`/`intersect_point()` (via `PhysicsDirectSpaceState2D`) take a `max_results` parameter (default 32) and silently drop hits past that count** — no error, no warning. Size it for the worst realistic case (e.g. max actors that could plausibly overlap one hitbox), not the common case.
- **Results from `intersect_shape()`/`intersect_point()` are not sorted by distance.** `intersect_ray()` returns a single closest hit by nature (it's a line query), but multi-result queries need manual sorting if "closest wins" logic is required.
- **Use the project's `LayerNames` autoload constants, never raw bitmask integers**, when setting `collision_layer`/`collision_mask` in code. Hand-writing `1 << 3` instead of the named constant is a silent-wrong-layer bug waiting to happen.

## Decision Rubric

| Question | Use |
|---|---|
| "Is anything here right now?" | `Area2D.get_overlapping_bodies()`/`get_overlapping_areas()`, or `PhysicsDirectSpaceState2D.intersect_point()` |
| "What's the nearest thing along this line?" | `RayCast2D` node, or `intersect_ray()` for one-off code-driven queries |
| "What's the nearest thing along this volume?" | `ShapeCast2D` node, or `intersect_shape()` (sort results manually) |
| "Everything in this area?" | `intersect_shape()` with `max_results` sized appropriately, or an `Area2D`'s overlap lists |

See `technical/code-standards.md`'s note on reserving `PhysicsDirectSpaceState2D` for advanced, purely code-driven queries — prefer scene-tree nodes (`RayCast2D`, `ShapeCast2D`, `Area2D`) for anything editor-placeable.
