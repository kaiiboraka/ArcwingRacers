# Plan: Wing Open/Close Animations (state ladder + turn/pitch drive)

Status: 🔄 IN PROGRESS (2026-08-03). Make the Arcwing pod's wing open/close animations
play as described in `docs/technical/pod-handling-and-boost.md` (Mechanical Opening
section) using the 6-animation library in `Content/Animations/Arcwing.res` that the
user authored: 4 idles (Closed, Squeezed, Open, Full) + 2 transitions (Opening,
Closing), cycling one state every 0.5s.

New requirement added this session: **nose-up opens the wings more, nose-down closes
them more** — pitch joins turn rate as a drive input.

## Background / verified facts

- Live library = `res://Content/Animations/Arcwing.res` (binary, `uid://cgtuava0eboh0`),
  referenced by `Arcwing.tscn:9` and preloaded in `PodController.gd:288`
  (`const ARCWING_ANIMS : AnimationLibrary = preload("uid://cgtuava0eboh0")`).
  `Arcwing.tres` is stale (old L_wing rig) — ignore.
- `PodController.gd:286-287` already has `LeftWing_anim_player` / `RightWing_anim_player`
  (`$Visuals/Wing_Left/AnimationPlayer` / `Wing_Right/...`), and `_ready()` (340/345)
  adds the `Arcwing` library to both. Scene `autoplay` on both players is `Arcwing/Idle_Open`.
- Both wings are instances of `SM_Wing_Left.fbx` (right mirrored), so track paths are
  identical on both players → drive both with the same animation + seek time.
- Animation contents (verified via MCP `animation_manage get` on the live player):
  - `Arcwing/Idle_Closed`, `Idle_Squeezed`, `Idle_Open`, `Idle_Full` — 0.1s, 70 tracks.
  - `Arcwing/Opening` (1.5s) keys at t=0/0.5/1.0/1.5 whose poses exactly equal the four
    idles (verified on `Skeleton3D:arm_root` rotation and `sail_root` rotation):
    t=0.0 → Closed, t=0.5 → Squeezed, t=1.0 → Open, t=1.5 → Full.
  - `Arcwing/Closing` (1.5s) is `Opening` reversed (Full→Open→Squeezed→Closed).
- Drive signal already computed in `_wing_tilt` / `_chassis_sway`:
  `turn_frac = clampf(_yaw_rate / max_turn_rate, -1.0, 1.0)` (`PodController.gd:595-597`).
- Pitch convention (from `_hover`/`_steer`/`_tilt`): `input.pitch > 0` = nose UP,
  `input.pitch < 0` = nose DOWN.
- Existing `# TODO(mechanical-opening)` block at `PodController.gd:650-674` is the planned
  hook point (call next to `_wing_tilt` in `_physics_process:366`) and documents the
  doc's intent: open with turn rate, hold while held, decay on neutral.

## Design

Continuous openness `_wing_open : float` in [0,1] mapped to the 4-state ladder, rendered
through the actual transition animations (never snapping straight to an idle).

- **Target openness per frame:** `target = clampf(absf(turn_frac) * turn_gain + input.pitch * pitch_gain, 0, 1)`.
  - `turn_frac` ramped yaw rate (docs: open with turns, hold while held, decay on neutral).
  - `input.pitch` nose-up (open more) / nose-down (close more) — new requirement.
- **Movement:** `_wing_open = move_toward(_wing_open, target, step_rate * delta)` with
  `step_rate = 2.0/3.0` per second → crosses one state boundary (1/3 openness) every 0.5s,
  matching the user's cadence. Driven by a physics-process accumulator, not playback speed,
  so it stays deterministic.
- **Render:**
  - Moving up (`target > _wing_open`): play `Arcwing/Opening`, seek `t = _wing_open * 1.5`.
  - Moving down (`target < _wing_open`): play `Arcwing/Closing`, seek `t = (1 - _wing_open) * 1.5`.
  - Settled at a state (|target − _wing_open| ≈ 0 and `_wing_open` ≈ n/3): play the matching
    idle (`Idle_Closed/Squeezed/Open/Full`) so the wings hold fixed at rest.
  - Seek with `update=true` each physics frame while traveling guarantees the pose exactly
    tracks `_wing_open` regardless of playback timing.
- Both wing players driven identically. `AnimationPlayer.play()` (no blend) + `seek(t, true)`.
- On `_ready()`: stop both players, initialize `_wing_open = 0.0` (Closed), play
  `Arcwing/Idle_Closed` (overrides the scene's `Idle_Open` autoplay).

## Exports added (`PodController.gd`, `@export_category("Wing Motion")`)

- `wing_open_turn_gain : float = 1.0` — 0..1 multiplier on |turn_frac| → openness.
- `wing_open_pitch_gain : float = 0.4` — multiplier on `input.pitch` (nose up +, nose down −).
- `wing_open_step_rate : float = 0.6667` — openness units/sec (1 state per 0.5s at default).
- `wing_open_rest_pose : float = 0.0` — openness when turn/pitch are neutral (default Closed;
  can raise to Squeezed later for a "parked slightly open" look).

## State vars

- `_wing_open : float = 0.0`
- `_wing_open_last_dir : int = 0` (0 = idle, +1 opening, −1 closing) to only re-play on change.

## Hook

- `_physics_process` (after `_wing_tilt` at line 366): `_wing_open_anim(delta, input);`
- Replace the `TODO(mechanical-opening)` block (650-674) with the real `_wing_open_anim()`.

## Out of scope

- Per-part individual openness (docs mention parts at different levels) — the library has a
  single wing state ladder; revisit only if user asks.
- Turn/pitch → idle fallback time, tilt-gating the mechanical open (docs don't gate it).
- `set_track_modes.gd` / `mirror.gd` retargeting (separate earlier task; stale `.tres` target).

## Verification

1. Edit `PodController.gd`; check parse via MCP `script_patch`/`filesystem_manage read_text` + editor logs.
2. `project_run` Test_Level; drive: turn → wings open; hold → stay; release → close; nose-up opens
   further, nose-down closes; log `logs_read(source='game')` for AnimationPlayer errors.
3. User visually confirms cadence/feel and tunes `wing_open_*` exports.

## Questions / Options

1. **Rest pose.** Default `wing_open_rest_pose = 0.0` (Closed at neutral). Scene autoplays
   Idle_Open today, so user may prefer a slightly-open rest (0.25 ≈ Squeezed). Tunable export.
2. **Pitch gain sign/strength.** Assumed `input.pitch > 0` (nose up) adds openness. If in-game
   feel is inverted, flip `wing_open_pitch_gain` sign. Default 0.4 so turns stay the primary driver.
3. **Seek vs natural playback.** Explicit per-frame `seek()` chosen for determinism; if 2×70-track
   seeks/frame ever matter, switch to `speed_scale`-driven playback (documented alternative).
