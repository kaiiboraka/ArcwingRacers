# Pod Physics & Collision

## Collision Shape

All Arcwings (blade + wings) use **capsule** collision shapes. Keeps performance high and complexity low compared to convex hulls or per-mesh collision.

- The blade (body/chariot) and wings (engines) each get their own capsule collider.
- Both physically collide with terrain — crashes can damage or destroy either part.
- Capsule orientation: aligned with the pod's forward axis.

---

## Collision Layers

| Layer | Contents | Solid | Notes |
|---|---|---|---|
| Terrain | Ground, track surfaces, hills | Yes | Primary hover surface |
| Walls | Track walls, barriers, buildings | Yes | Wall scrapes and crashes |
| Decorative Doodads | Foliage, small props | Yes | Low-priority collisions |
| Water | Water volumes | Yes | Triggers water physics mode |
| Pod | Other Arcwings | Yes | Pod-on-pod collisions |
| Projectile | Ability projectiles | Yes | Solid to pods |
| Hazard | Fire vents, spike traps, etc. | Trigger | Area-based damage |
| Items & Pickups | Mana crystals, item boxes | Trigger | Collect on overlap |
| Boost & Interactable | Boost pads, shortcuts, doors | Trigger | Activates on overlap |

---

## Physics Body Type

**CharacterBody3D** — fully deterministic movement. All forces (hover, acceleration, boost, banking) are calculated in code and applied each frame. No engine-driven physics autopilot.

### Collision Resolution

`move_and_slide()` or `move_and_collide()` handles collision response each frame. Because CharacterBody sweeps its collision shape along the full motion vector, sub-frame tunneling through thin geometry is already handled by the sweep — the engine detects the contact and stops or slides before penetration occurs.

---

## Penetration Prevention

### Primary: Sweep-Based Detection (built-in)

Godot's `move_and_collide()` and `move_and_slide()` both perform a continuous sweep of the collision shape from the body's current position to the target position. This is effectively Option B from the brainstorm — the engine does the ray-sweep for us.

The sweep cannot fail for walls or terrain because the collider expands along the full motion delta. At extreme boost speeds the capsule length may exceed the wall thickness, but the full-sweep nature of Godot's CharacterBody CCD means a wall spanning that entire path will still be detected.

### Fallback: Dynamic Collision Scaling (Option C)

If a specific thin-geometry case does cause a miss, inflate the pod's terrain/wall collision capsule along the velocity axis as a function of speed:

```
scale = 1.0 + (speed / threshold)
```

The inflated shape exists only on the terrain/wall collision layer — pod-to-pod and projectile layers remain normal size. This prevents tunneling through thin walls during boost without making pods feel wider in traffic.

### Archived Alternatives

Option A (pre-hit slowdown) — introduces artificial braking before walls, not desired. Option D (RigidBody CCD) — moot since we chose CharacterBody.
