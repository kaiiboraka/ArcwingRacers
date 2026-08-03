# Plan: Wing Open/Close Animations (state ladder + turn/pitch/tilt drive)

Status: 🔄 IN PROGRESS (2026-08-03). Make the Arcwing pod's wing open/close animations
play per the user's corrected spec using the 6-animation library in
`Content/Animations/Arcwing.res`: 4 idles (Closed, Squeezed, Open, Full) + 2 transitions
(Opening, Closing), cycling one state every 0.5s.

## Corrected spec (user feedback, supersedes the docs' general wording)

- **Default rest is Open**, not Closed. (Scene autoplay is `Arcwing/Idle_Open` on both
  wings — matches.)
- **The two wings animate independently.** Each has its own openness/state.
- **Turn (yaw):** "one opens, one closes." The wing on the INSIDE of the turn goes to
  **Squeezed** (never Closed); the OUTSIDE wing transitions toward **Full** and STAYS
  Full while the turn is held, then transitions back to Open on release.
- **Tilt (roll):** the wing toward the ground fully closes (→ **Closed**), the wing in
  the air fully opens (→ **Full**) — whichever side is up gets opened, the other closes.
- **Full** is used only for extra-large openings: airborne nose-up, the turn-open side,
  and the tilt air-side.
- **Closed** is reserved for nose-down while airborne and the tilt ground-side.
- Pitch (nose up/down) affects BOTH wings symmetrically and only while airborne.
- **Boost charge** ("tipping the nose forward on the ground while charging"): while in
  `BoostState.CHARGING` and `READY` both wings go to **Squeezed** (the charge stance —
  nose-down is what triggers charging, so this doubles as the grounded-nose-down look).
  Only once **BOOSTING** do both wings go to **Full**. `NORMAL` / `OVERHEAT` use the
  plain rest/turn/pitch/tilt drive.
- **Grounded nose-down** (pitch input while grounded, before it reaches the charge
  deadzone): both wings squeeze toward **Squeezed** (min with the rest target), never Closed.

## Background / verified facts

- Live library = `res://Content/Animations/Arcwing.res` (binary, `uid://cgtuava0eboh0`),
  referenced by `Arcwing.tscn:9` and preloaded in `PodController.gd:288`
  (`const ARCWING_ANIMS : AnimationLibrary = preload("uid://cgtuava0eboh0")`).
  `Arcwing.tres` is stale (old L_wing rig) — ignore.
- `PodController.gd` has `LeftWing_anim_player` / `RightWing_anim_player`
  (`$Visuals/Wing_Left/AnimationPlayer` / `Wing_Right/...`), and `_ready()` adds the
  `Arcwing` library to both (guarded by `has_animation_library("Arcwing")` — the scene
  already wires the library, so the guard prevents a double-add error).
- Animation contents (verified via MCP `animation_manage get`):
  - `Arcwing/Idle_Closed`, `Idle_Squeezed`, `Idle_Open`, `Idle_Full` — 0.1s, 70 tracks.
  - `Arcwing/Opening` (1.5s) keys at t=0/0.5/1.0/1.5 whose poses exactly equal the four
    idles: t=0.0 → Closed, t=0.5 → Squeezed, t=1.0 → Open, t=1.5 → Full.
  - `Arcwing/Closing` (1.5s) is `Opening` reversed (Full→Open→Squeezed→Closed).
- Drive signals:
  - `turn_frac = clampf(_yaw_rate / max_turn_rate, -1.0, 1.0)` (`PodController.gd:612-614`).
    `turn_frac > 0` = LEFT turn (verified against `_wing_tilt`: turn_frac ≤ 0 → left
    up / right down = right turn per the vertical-shift doc). Inside wing = the side the
    pod turns toward. `_yaw_rate` is ramped, so the open holds while held and decays on release.
  - Pitch convention: `input.pitch > 0` = nose UP, `< 0` = nose DOWN.
  - Tilt convention (from `_tilt`, `target_tilt_roll = -input.tilt * ...`):
    `input.tilt > 0` = roll RIGHT → right wing down (ground side) / left wing up (air side).
- Hook point: `_wing_open_anim(delta, input)` call after `_wing_tilt` in `_physics_process`.

## Design

Continuous per-wing openness `_wing_left_open` / `_wing_right_open` in [0,1] mapped to
the 4-state ladder (state n = n/3: Closed 0, Squeezed 1/3, Open 2/3, Full 1), rendered
through the actual transition animations (never snapping straight to an idle).

**Per-wing target each frame** (`_wing_open_target`), starting from `wing_open_rest_pose`
(2/3 = Open):

1. **Pitch (airborne only, both wings):** nose-up lerps toward Full, nose-down lerps
   toward Closed, by `minf(|pitch| * wing_open_pitch_gain, 1.0)`. No effect grounded.
2. **Turn differential (`turn_mag = |turn_frac| * turn_gain`, applied only when > 0):**
   - Inside wing: `min(target, lerp(rest, Squeezed, turn_mag))` → Squeezed at full turn.
   - Outside wing: `max(target, lerp(rest, Full, turn_mag))` → Full at full turn.
3. **Tilt differential (`tilt_frac = |_tilt_roll| / tilt_max_angle`, applied only when > 0):**
   - Air-side wing: `max(target, lerp(rest, Full, tilt_frac))` → Full.
   - Ground-side wing: `min(target, lerp(rest, Closed, tilt_frac))` → Closed.
4. **Grounded nose-down:** `grounded_nose_down = min(-input.pitch, 1)` when grounded and
   `input.pitch < 0`; `min(target, lerp(rest, Squeezed, grounded_nose_down))` → Squeezed.
5. **Boost-state override (highest priority):** `CHARGING`/`READY` → both Squeezed;
   `BOOSTING` → both Full. Returned immediately, bypassing rest/turn/pitch/tilt.

The `turn_mag`/`tilt_frac > 0` guards keep the differentials from clamping the symmetric
pitch drive when no turn/tilt is active (a plain airborne nose-up opens BOTH wings to Full).

**Movement & render** (`_drive_wing_open`, per wing):
- `cur = move_toward(cur, target, wing_open_step_rate * delta)` — `step_rate = 2/3` per
  second crosses one state boundary (1/3) every 0.5s.
- Moving up → play `Arcwing/Opening`, seek `cur * 1.5` each frame.
- Moving down → play `Arcwing/Closing`, seek `(1 - cur) * 1.5` each frame.
- Settled at a state (|cur − n/3| ≤ 0.04 and target ≈ cur) → snap cur to n/3, play the
  matching idle so the wing holds fixed.
- Each wing tracks its own `_wing_cur_anim`, so during a turn one player can be playing
  `Closing` (inside → Squeezed) while the other plays `Opening` (outside → Full).
- `_ready()` (`_apply_wing_open_rest`): snap rest to the nearest state, play that idle on
  both players (overrides the scene's `Idle_Open` autoplay with the same result).

## Exports (`PodController.gd`, `@export_category("Wing Motion")`)

- `wing_open_turn_gain : float = 1.0` — multiplier on |turn_frac| → turn differential depth.
- `wing_open_pitch_gain : float = 1.0` — fraction of full nose deflection toward
  Full/Closed (airborne only). 1.0 = full nose-up → Full, full nose-down → Closed.
- `wing_open_step_rate : float = 0.6667` — openness units/sec (1 state per 0.5s at default).
- `wing_open_rest_pose : float = 2.0 / 3.0` — neutral openness (default Open; the pod's
  parked look).

## State vars

- `_wing_open : Array[float]` — `[left, right]` openness in [0,1], init to rest.
- `_wing_cur_anim : Array[StringName]` — `[left, right]` current animation name
  (per-wing re-play guard).

## Hook

- `_physics_process` (after `_wing_tilt`): `_wing_open_anim(delta, input);`
- Functions: `_apply_wing_open_rest`, `_wing_open_anim`, `_wing_open_target`,
  `_drive_wing_open`, `_play_wing_anim`. Consts: `WING_OPEN_IDLE_ANIMS`,
  `WING_OPEN_SNAP_EPS`, `WING_OPEN_STATE_{CLOSED,SQUEEZED,OPEN,FULL}`.
  `_wing_open_target(is_inside, is_air_side, pitch, turn_mag, tilt_frac,
  grounded_nose_down = 0.0, boost_open = -1.0)`.

## Verification

1. Edit `PodController.gd`; parse-check via MCP (`script_manage find_symbols`).
2. Report expected behavior to the user; the user runs the game and confirms feel/cadence.
   The agent does NOT test gameplay (see agent-rules.md).
3. Tune `wing_open_*` exports from feel.

## Out of scope

- Per-part individual openness beyond the two-wing differential (library has a single
  wing state ladder).
- `set_track_modes.gd` / `mirror.gd` retargeting (separate earlier task; stale `.tres` target).
