# Phantom Camera (Addon) — Technical Summary

Phantom Camera is a Cinemachine-inspired Godot 4 addon that manages `Camera2D`/`Camera3D` behavior declaratively through nodes instead of per-camera scripts. A single `Camera` is "possessed" by whichever `PhantomCamera` node currently has the highest `priority`, and it inherits that node's follow / look-at / tween / noise / camera-property logic.

**Installed at:** `res://addons/phantom_camera/`
**Version in project:** 4.7.1-stable editor; addon verified against it (3D path uses `physics_interpolation` features gated to Godot 4.4+).

---

## Reference Links

Official docs (save for later reference):

- Overview / what it is: <https://phantom-camera.dev/overview/what-is-this>
- Scene requirements (minimum setup): <https://phantom-camera.dev/overview/scene-requirements>
- PhantomCameraHost core node: <https://phantom-camera.dev/core-nodes/phantom-camera-host>
- PhantomCamera3D core node: <https://phantom-camera.dev/core-nodes/phantom-camera-3d>
- Noise system (general): <https://phantom-camera.dev/phantom-camera-noise>
- Noise Emitter 3D secondary node: <https://phantom-camera.dev/secondary-nodes/phantom-camera-noise-emitter-3d>
- Priority system: <https://phantom-camera.dev/priority>
- Third Person follow mode (3D): <https://phantom-camera.dev/follow-modes/third-person>
- PhantomCameraManager singleton: <https://phantom-camera.dev/phantom-camera-manager>

Example scenes shipped with the addon: `res://addons/phantom_camera/examples/example_scenes/3D/` (incl. `3d_follow_third_person_example_scene.tscn`).

---

## Node Taxonomy

| Node | Extends | Purpose |
|---|---|---|
| `PhantomCamera3D` / `PhantomCamera2D` | `Node3D` / `Node2D` | Holds camera intent (follow/look-at/tween/noise/props). "PCam". |
| `PhantomCameraHost` | `Node` | Child of the `Camera`; decides which PCam is active and applies its transform to the camera each frame. "PCamHost". |
| `PhantomCameraNoiseEmitter3D` | `Node3D` | Scene-triggerable shake applied to any active PCam sharing a noise layer. |
| `PhantomCameraTweenDirector` | `Node` | Conditional tween selection between PCams by from/to rules. |
| `PhantomCameraManager` | `Node` (autoload) | Tracks all PCams/hosts/tween-directors in the scene; routes signals. |

Supporting resources: `PhantomCameraTween` (transition), `TweenDirectorResource` (rules), `Camera3DResource` (camera prop overrides), `PhantomCameraNoise2D` / `PhantomCameraNoise3D` (shake patterns).

---

## Minimum Scene Setup (3D)

```
Camera3D
└── PhantomCameraHost        ← set-and-forget, child of the Camera
PhantomCamera3D             ← anywhere in the scene (can be a sub-scene)
    follow_target: Player
```

1. Camera + PhantomCameraHost (host must be a direct child of the Camera).
2. At least one PhantomCamera3D with a follow/look-at target.
3. The PCam with the highest `priority` takes over the Camera. Toggle a PCam's visibility in the scene tree to enable/disable it.

Camera and PCam(s) may live in separate sub-scenes as long as they're instantiated together.

---

## How It Works Internally

### PhantomCameraManager (autoload)

- Registers itself as an engine singleton (`PhantomCameraManager`) via `Engine.register_singleton`.
- `_enter_tree` sets `Engine.physics_jitter_fix = 0`.
- Tracks arrays: `phantom_camera_hosts`, `phantom_camera_2ds`, `phantom_camera_3ds`, `phantom_camera_tween_directors`.
- Broadcasts signals on add/remove/priority/visibility changes; hosts subscribe to these in `_ready`.

### PhantomCameraHost

- Validates it's a child of a Camera (config warning otherwise). Only the first host child under a Camera is used.
- On 2D: force-disables `Camera2D.position_smoothing` (the addon does its own interpolation).
- **Layer matching:** `host_layers` (bitmask, default 1) must intersect the PCam's `host_layers` for the host to recognize it. Helpers: `set_host_layers_value(layer, bool)`.
- **Priority resolution:** on any `pcam_priority_changed` / visibility change / PCam add, `_find_pcam_with_highest_priority()` picks the highest-priority *visible* PCam in its layers (ties go to the later one; `>=` comparisons). Hidden PCams never become active.
- Sets `camera_3d.top_level = true` so the camera is unparented in world space and driven purely by the active PCam's output transform.
- Applies the active PCam's `process_logic(delta)` output to the Camera every frame, and runs the tween between the previous and new PCam transform.

### Interpolation Mode

`PhantomCameraHost.interpolation_mode` (AUTO=0, IDLE=1, PHYSICS=2, MANUAL=3):

- **AUTO** detects from the active PCam whether its follow/look-at target is physics-based and switches the camera's `physics_interpolation_mode` accordingly (`_check_pcam_physics`).
- **MANUAL** only advances when you call `pcam_host.process(delta)` yourself.
- Host uses `process_priority = 300` / `process_physics_priority = 300`.

### Priority & Switching

- `PhantomCamera3D.priority` (int, default 0). Changing it emits through the manager; the host re-evaluates and, if the new PCam wins, tween-attaches the camera to it.
- `priority_override` (editor-only) force-preview a PCam; ignored in exports.
- Tweens between PCams use the *newly active* PCam's `tween_resource` (duration/transition/ease). `tween_on_load` controls whether the first tween plays on scene load (default true).
- Signals: `became_active`, `became_inactive`, `tween_started`, `is_tweening`, `tween_interrupted(pcam)`, `tween_completed`, `follow_target_changed`, `look_at_target_changed`, `dead_zone_changed`, `dead_zone_reached`.

---

## PhantomCamera3D — Follow Modes

`follow_mode` enum:

| Mode | Value | Behavior |
|---|---|---|
| `NONE` | 0 | No follow logic. |
| `GLUED` | 1 | Locks onto target position exactly. |
| `SIMPLE` | 2 | Follows target + `follow_offset`, optional damping. |
| `GROUP` | 3 | Centers on the AABB of `follow_targets`; optional auto-distance. |
| `PATH` | 4 | Follows target but clamps position to closest point on a `Path3D`. |
| `FRAMED` | 5 | Dead-zone framing; only moves when target breaches bounds. |
| `THIRD_PERSON` | 6 | SpringArm3D orbit camera around the target (see below). |

Common follow params: `follow_target`, `follow_offset`, `follow_damping` + `follow_damping_value` (Vector3, ~0.1–0.25 recommended), `follow_axis_lock`, `follow_distance`, `inactive_update_mode`.

### Third Person Follow (mode 6) — relevant to Arcwing

- Internally spawns a `SpringArm3D` (top_level) at runtime, parents the PCam into it, and uses it as the camera target. SpringArm props driven from the PCam:
  - `spring_length` (default 1.0), `collision_mask` (default 1), `shape` (Shape3D; if unset, host auto-generates a ConvexPolygonShape3D from the camera's pyramid shape at runtime), `margin` (default 0.01).
  - If `follow_target` is set, the SpringArm excludes the target object from collision.
- Orbit rotation applied via:
  - `set_third_person_rotation_degrees(Vector3)` — use this for mouse orbit (example in addon + docs),
  - `set_third_person_rotation(Vector3)` radians,
  - `set_third_person_quaternion(Quaternion)`.
- `vertical_rotation_offset` / `horizontal_rotation_offset` (degrees) add X / Y offsets to the SpringArm rotation.
- Mouse-look recipe (from docs / `player_controller_third_person.gd`): read `get_third_person_rotation_degrees()`, adjust `x -= event.relative.y * sens` clamped to `[-89.9, 50]`, `y -= event.relative.x * sens` wrapped to `[0, 360)`, write back. Note the example updates BOTH the player PCam and an aim PCam so aim transitions seamlessly.
- The example toggles cameras by priority: aim PCam `set_priority(30)` on RMB, back to `0` on release; a ceiling PCam set to priority 30 on Space.

---

## PhantomCamera3D — Look At Modes (3D)

`look_at_mode` enum: `NONE=0`, `MIMIC=1` (copy target rotation), `SIMPLE=2` (look straight at target), `GROUP=3` (look at center of `look_at_targets`).

Params: `look_at_target`, `look_at_offset`, `look_at_damping` + `look_at_damping_value` (default 0.25), `up` / `up_target` (overrides world up). Look-at damping uses quaternion slerp-style interpolation.

> Note: Combining Follow + Look At on the same PCam prints a "not fully tested" warning.

---

## Camera Property Overrides

- `camera_3d_resource` (`Camera3DResource`) — overrides `keep_aspect`, `cull_mask`, `h_offset`, `v_offset`, `projection`, `fov`, `size`, `frustum_offset`, `near`, `far`. These properties are tweened between PCams on switch. The host snapshots the camera's previous values and interpolates only changed properties.
- `attributes` (`CameraAttributes`) — per-PCam DOF / exposure. Tweened when same attribute type (`CameraAttributesPractical` vs `CameraAttributesPhysical`); the Camera retains the last applied attribute if a subsequent active PCam has none.
- `environment` (`Environment`) — applied but **not** tweened. Prefer a `WorldEnvironment` unless a PCam truly needs its own env.

---

## Noise / Shake

Three ways to apply shake:

1. **PCam `noise` property** — assign a `PhantomCameraNoise3D` resource; runs continuously while that PCam is active (starts after its tween completes).
2. **`PhantomCameraNoiseEmitter3D`** — scene node with `noise`, `continuous`, `growth_time`, `duration`, `decay_time`, and a `noise_emitter_layer` bitmask. Call `emit()` to trigger; affects all active PCams whose `noise_emitter_layer` intersects the emitter's. Can hit the camera mid-tween. Helpers: `set_noise_emitter_layer_value()`. Editor `preview` toggle.
3. **`emit_noise(Transform3D)`** — manual noise injection for external/custom noise sources.

Layer matching: PCam `noise_emitter_layer` (default 0) ∩ emitter `noise_emitter_layer` (default 1). Enable matching layers on the PCam to be affected.

---

## Editor Features

- **Viewfinder** — in-editor overlay listing hosts/PCams; dead-zone preview; per-host collapsible lists for multi-host scenes.
- **Align with View** buttons — position/rotation/transform alignment to the current editor viewport.
- **Gizmo lines** — red = follow target, blue = look-at target (toggle via `draw_follow_line` / `draw_look_at_line`; not shown at runtime).
- **Preview noise** in editor (`_preview_noise`).

---

## Arcwing Application Notes

- The current camera setup is `CameraMount_SpringArm3D` (SpringArm3D, spring_length=12, collision_mask=7) with a child `Camera3D` (`current=true`, `doppler_tracking=PhysicsStep`) — see `docs/technical/pod-scene-hierarchy.md`.
- **Migration path:** replace the manual SpringArm3D with a `PhantomCamera3D` in THIRD_PERSON mode following the pod root: set `spring_length=12`, `collision_mask=7` (matching current), apply orbit via `set_third_person_rotation_degrees()` from input, and keep the Camera3D child under a `PhantomCameraHost`. Doppler tracking remains a Camera3D property and is untouched by the addon.
- Multi-cam pattern (from examples): keep a low-priority orbit PCam and raise a second PCam's `priority` for aim/boost/ceiling shots, then lower it to return.
- Tween-on-load: disable `tween_on_load` on a follow PCam if the camera should snap to the pod at scene start rather than fly in.
