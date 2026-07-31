# Pod Hover System

## Overview

The pod hovers above terrain using 4 spring-raycasts at the corners. Each raycast applies a damped spring force proportional to its compression — like a springy stilt or jetstream pushing up from the ground. This is the primary source of the hover feel.

---

## Raycast Layout

4 raycasts, one at each corner of the pod chassis:

```
    FRONT
  L•     •R
  |       |
  L•     •R
    BACK
```

Each raycast:
- Fires downward from its mounting point on the pod
- Rest length = pod's **Hover Height** stat (a fixed per-racer stat in the EP1R model)
- Detects terrain, walls, and any solid-collision surface
- Only applies spring force when a surface is within range

The hover rays double as the **grounded detector**. A ray is "compressing" when within `hover_height + grounded_band`; if the pod was already grounded it stays grounded while *any* ray is in that band (latch/hysteresis), otherwise it grounds only when a ray is actually compressing (`hover_height - dist > 0`). No separate grounded collision area or ray is needed. Nose-pitch gravity modulation applies **always** (grounded or not) via fixed `gravity_nose_up` / `gravity_nose_down` values — see Air Control in `pod-handling-and-boost.md`.

---

## Spring Model

Each active raycast applies a force each frame:

```
compression = rest_length - raycast_distance
if compression > 0:
    spring_force = compression * spring_stiffness
    damp_force = compression_velocity * spring_damping
    total_force = spring_force - damp_force
```

- **spring_stiffness** — tunable constant, same for all pods. Controls how "hard" the hover feels. High = rigid, low = bouncy.
- **spring_damping** — tunable constant. Controls how quickly the pod settles after a bounce.
- **compression_velocity** — rate of change of compression from frame to frame (derivative of compression).
- Forces are applied at the raycast's world-space contact point to produce natural torque (compression on one side lifts that corner).

---

## Uneven Terrain

Each raycast operates independently. On uneven ground:
- A raycast over a dip extends further → less compression → less upward force on that corner → pod tilts into the dip naturally
- A raycast over a bump compresses more → more upward force → pod rises over the bump

No special logic needed — the spring physics handles it automatically.

---

## Banking (TBD — needs playtesting)

Banking behavior during turns is not yet settled. Reference observations from EP1R:

- In normal play, turning shifts the engines vertically in world space — the turn-side engine drops and the opposite engine rises (left turn: left engine down, right engine up; right turn: right engine down, left engine up). See `docs/technical/pod-handling-and-boost.md#visual-engine-vertical-shift`.
- The body (blade) responds to wing movement — wings drag the blade, not the other way around.
- EP1R's dual-controller mode (secret N64 feature) maps each engine to its own joystick: both forward = accel + nose down, both back = brake + nose up, opposite directions = turn. This reveals engine-independent physics under the hood.

**Architecture placeholder:** The hover system handles suspension only. Banking rotation (if any) will be applied by the handling system on top of the hover forces. The two can be developed independently — the hover springs work with or without banking rotation applied from outside.

Once EP1R playtesting notes are taken, this doc will be updated with the banking model.
