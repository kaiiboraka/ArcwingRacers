# Pod Scene Hierarchy

## Root

CharacterBody3D — single physics body for the entire arcwing. All collision shapes are direct children (Godot requirement).

---

## Collision Shapes

7 capsule shapes under the CharacterBody3D, each representing a destructible segment:

| Node | Segment | Shape |
|---|---|---|
| CollisionShape3D (blade) | Body / Chariot | Capsule |
| CollisionShape3D (wing_L_front) | Left wing, forward section | Capsule |
| CollisionShape3D (wing_L_mid) | Left wing, middle section | Capsule |
| CollisionShape3D (wing_L_back) | Left wing, rear section | Capsule |
| CollisionShape3D (wing_R_front) | Right wing, forward section | Capsule |
| CollisionShape3D (wing_R_mid) | Right wing, middle section | Capsule |
| CollisionShape3D (wing_R_back) | Right wing, rear section | Capsule |

Shape order (index) matters — `KinematicCollision3D.get_local_shape()` returns the index, which maps back to the segment.

---

## Visuals (spring-offset)

Each visual cluster parented to a spring-offset Node3D under the root. On collision, the spring bounces the visual relative to the root (collision shape stays put, visual shows impact). Recovers to rest pose when not hit.

```
Arcwing (CharacterBody3D)
├── CollisionShape3D (blade)
├── CollisionShape3D (wing_L_front)
├── ...
├── BladeSpring (Node3D)          ← spring offset
│   └── Blade (Node3D)            ← visual mesh
├── WingLSpring (Node3D)          ← spring offset
│   └── Wing_L (Node3D)           ← visual group
│       ├── MeshInstance3D (front)
│       ├── MeshInstance3D (mid)
│       └── MeshInstance3D (back)
├── WingRSpring (Node3D)          ← spring offset
│   └── Wing_R (Node3D)
├── HoverRaycasts (Node3D)
│   ├── RayCast3D (front_left)
│   ├── RayCast3D (front_right)
│   ├── RayCast3D (mid_left)
│   ├── RayCast3D (mid_right)
│   ├── RayCast3D (back_left)
│   └── RayCast3D (back_right)
├── CameraMount (Node3D)
├── ManaComponent (Node)
└── AbilityComponent (Node)
```

---

## Hit Detection

In `move_and_slide()` callback or `_on_body_entered`:

```
var shape_idx = slide_collision.get_local_shape()
match shape_idx:
    0: # blade
    1: # wing_L_front
    2: # wing_L_mid
    3: # wing_L_back
    4: # wing_R_front
    5: # wing_R_mid
    6: # wing_R_back
```

Each segment tracks its own health. When destroyed, the associated visual spring can detach (become a separate physics body) or play a destruction animation.

---

## Fallback

If the spring-offset fake proves insufficient for gameplay feel, each wing cluster becomes its own CharacterBody3D connected to the main body via a custom hard-coded constraint (distance + angular limits, no Godot joints). This adds significant complexity to the movement loop but provides real independent wing physics.
