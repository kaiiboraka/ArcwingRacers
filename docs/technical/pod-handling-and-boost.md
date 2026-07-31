# Pod Handling and Boost

## Acceleration

The Acceleration stat does not affect physics force — it controls the **catch-up rate**: how fast the pod's current speed approaches its maximum speed.

When speed is lost (turn, brake, crash, start from standstill), the current speed recovers toward max each frame:

```
current_speed = lerp(current_speed, max_speed, acceleration_factor * delta)
```

The Acceleration component (Injector) modifies the base factor — lower Acceleration stat = higher factor = faster recovery. This applies whenever the accelerator is held and current speed < max speed.

---

## Steering

Steering uses **yaw rotation** (Approach A below) — not lateral forces.

### Physics: Yaw + Traction-Gated Drift
1. Steering input is ramped by **Turn Response** — the actual yaw rate lerps toward `max_turn_rate` each frame (persistent `_yaw_rate` state), so the nose smoothly accelerates into the turn and eases back to zero on release instead of snapping at full rate instantly.
2. Pod's linear velocity aligns toward the new forward direction, gated by **Traction** stat
3. Higher Traction = velocity aligns faster = less drift (better grip)
4. Lower Traction = more drift (pod slides through turns)

**Two separate turn stats** (matches the EP1R stat model):
- `max_turn_rate` — how steep the turn can be (fixed per-racer sharpness, in rad/s)
- `turn_response` — how quickly the pod reaches `max_turn_rate` after steering input (upgradable; higher = snappier, lower = sluggish floaty turn-in)

This gives the "yank" feel (yaw rotation starts immediately on input, ramping toward max) while the body's velocity catches up, creating the floaty drift EP1R is known for. The lateral drift kick scales with the *ramped* turn rate (`steer_frac`), so a fresh standstill tap does not instantly shove the pod sideways — it builds with the turn.

### Visual: Chassis Sway
From EP1R observation — the chassis (chariot body) swings much further than the engines during turns. The engines stay centered in the view while the chariot moves left/right. Implemented on `PodController` by translating the `Blade` node laterally in the pod's local frame: the body shifts to the outside of the turn (opposite the steer direction), scaled by steer × speed fraction and lerped by `chassis_sway_speed`. Tunable via `chassis_sway_travel` (lateral distance in meters) and `chassis_sway_speed` (response rate).

### Visual: Ship Tilt (90°)
The Ship Tilt ability rolls the pod up to 90° about its forward axis using the right analog stick horizontal or Q / E. It stacks on top of the steering bank — tilting while steering rolls further. Tunable via `tilt_max_angle` (max roll degrees) and `tilt_speed` (roll response). Purely visual on the pod's roll axis; used to thread narrow gaps and hazards.

### Visual: Engine Vertical Shift
During turns the engines shift vertically **in world space** — the arc-rig beams connecting the wings to the blade transfer the turn into vertical motion. The behavior is **tilt-gated**:

- **Upright (differential):** the wing on the inside of the turn drops and the opposite wing rises — Right turn: Right engine down, left engine up. Left turn: Left engine down, right engine up.
- **Tilted (together):** both wings shift **together** along the pod's local up/down axis, toward the direction of the turn in world space — the pod-local up/down maps to absolute left/right at full roll, so the wings sweep sideways with the tilt.

Magnitude scales with steer × speed fraction and is tunable via `wing_down_vert_travel` (how far the turn-side wing drops upright, or the down-local shift tilted) and `wing_up_vert_travel` (how far the opposite wing rises upright, or the up-local shift tilted) on `PodController` — both values apply to both wings. It is a translation — the wing models stay upright while they bob, they do not roll in place. This is separate from chassis sway.

### Visual: Mechanical Opening
Fins, wings, vents, and other moving parts on each engine open as turn rate increases, stay open while the turn is held, and decay back to closed when the stick returns to neutral. Each part tracks its own openness — they can be at different levels simultaneously (e.g., partially open during a gentle turn). This is independent of the engine vertical shift above.

### Nose Tilt
Engines tilt slightly up or down based on nose pitch input, matching the pod's pitch attitude. Purely visual on the engine visual groups.

### Dismissed: Lateral Force
Applying lateral force at wing positions was considered but produces a softer, more inertia-driven response. The EP1R reference requires the immediate yank of yaw rotation.

---

## Boost System

**Location:** Currently implemented inline in `Systems/Pod/PodController.gd`; planned to move to a `BoostComponent` node.
**Dependencies:** `InputCollector` (reads `boost_just_pressed`)

### BoostComponent

A per-pod node managing boost charge, activation, heat, and overheat.

```gdscript
# boost_component.gd
class_name BoostComponent
extends Node

# ── VehicleStat-derived exports ──
@export var heat_rate: float = 1.0        # heat units per second during boost
@export var cool_rate: float = 1.0        # heat units per second after boost
@export var boost_thrust: float = 200.0   # speed added during boost
@export var boost_speed_bonus: float = 50.0  # added on top of max_speed while boosting
@export var min_charge_speed_fraction: float = 0.8  # min max-speed fraction to charge
@export var boost_end_speed_fraction: float = 0.5   # speed drop below this fraction ends boost

# ── State ──
enum State { NORMAL, CHARGING, READY, BOOSTING, OVERHEAT }
var state: State = State.NORMAL
var charge: float = 0.0        # 0.0 → 1.0 (full)
var heat: float = 0.0          # 0.0 → 1.0 (max = overheat)
var max_heat: float = 1.0
```

`NORMAL` is the resting, uncharged state — charge sits at 0 and nothing happens. The pod only enters `CHARGING` when it is actually filling the gauge (holding forward AND fast enough); the moment either condition drops, it returns to `NORMAL` and charge resets to 0.

### Charge Phase

Forward input while at speed fills the gauge. The gauge does not charge when coasting or slow, and **resets instantly when forward is released** — each hold starts from empty. The stick must be held **basically completely forward** (within `charge_pitch_deadzone_deg`, default 10°, of full deflection) — a light nose-down that would also allow steering does not count. Charging is a committed straight-line action: because steering pulls the stick off full-forward, the pod effectively has to be flying straight (wings on the ground, not turning) to charge.

```gdscript
func _charging_input(input) -> bool:
    if input.pitch >= 0.0:
        return false
    var full = cos(deg_to_rad(charge_pitch_deadzone_deg))
    return -input.pitch >= full

func _charge(delta: float, nose_pitch: float, speed_fraction: float):
    if state == State.CHARGING and (_charging_input(input) and speed_fraction >= min_charge_speed_fraction):
        charge += charge_rate * abs(nose_pitch) * delta
        charge = min(charge, 1.0)
        if charge >= 1.0:
            state = State.READY
            EventBus.boost_ready.emit()
    else:
        state = State.NORMAL     # not charging → idle; resets gauge
        charge = 0.0
```

### Boost Activation

When the gauge is full (state = READY), a single press of the Boost button activates boost — a divergence from EP1R's release-and-repress pattern (simplified for modern controls; see ADR 0004). Boost max speed is additive: while boosting, the pod accelerates toward `max_speed + boost_speed_bonus`.

```gdscript
func try_activate(boost_just_pressed: bool):
    if state != State.READY:
        return
    if boost_just_pressed:
        _start_boost()

func _start_boost():
    state = State.BOOSTING
    heat = 0.0
    velocity += forward * boost_thrust   # flat speed added on activation
    EventBus.boost_started.emit()
```

**Forward input is only required to charge the gauge.** Once boost is active, the player returns to neutral pitch — boost continues regardless of nose position.

### Boost Phase

```gdscript
func _boost_process(delta: float):
    if state != State.BOOSTING:
        return

    heat += heat_rate * delta
    if heat >= max_heat:
        _overheat()
        return

    var heat_pct = heat / max_heat
    # Emit heat level for audio/visual feedback
    EventBus.boost_heat_updated.emit(heat_pct)

    # Turn rate reduced during boost (see Steering / _steer in PodController)
    # yaw_turn_rate = max_turn_rate * boost_turn_rate_penalty   # default 0.5 → half turn rate
```

**Turn-rate penalty:** While boost is active, `_steer` in `PodController` multiplies both the yaw turn rate and the lateral traction alignment by `boost_turn_rate_penalty` (default 0.5 — half agility). This is the "handling loss" cost of boosting: you commit to a fast, straight-ish line and turn sluggishly.

### Boost End Conditions

Boost ends when any of:
- Heat reaches max → overheat
- Player releases accelerator
- Player applies brakes
- Speed drops far below max (below `boost_end_speed_fraction`, default 0.5 — a massive speed loss ends boost early)
- Significant collision (above damage threshold)
- Pod crashes

```gdscript
func end_boost():
    if state == State.BOOSTING:
        state = State.NORMAL   # back to idle; heat drains passively while not boosting
        heat = max(heat, 0.1)    # preserve current heat for cooldown
        EventBus.traction_modifier.emit(1.0)   # restore traction
        EventBus.boost_ended.emit()
```

**Brake during boost:** Braking is not analog. Pressing brake while boost is active ends it immediately — it does not drain heat. Heat only drains by not boosting.

### Overheat

When heat reaches maximum, boost forcibly disengages. Wing fire starts. The pod cannot boost again until the fire is extinguished — heat gauge must fully drain.

```gdscript
func _overheat():
    state = State.OVERHEAT
    EventBus.traction_modifier.emit(1.0)
    EventBus.overheat_started.emit()   # triggers wing fire VFX + SFX
```

### Cooling

Heat depletes whenever the pod is **not boosting** — boosting stops cooling and starts heating. After a voluntary end, heat drains while the pod re-charges. During overheat, the gauge must fully drain before the fire goes out and the pod can boost again.

```gdscript
func _cool_process(delta: float):
    if state == State.BOOSTING:
        return
    heat -= cool_rate * delta
    heat = max(heat, 0.0)
    if state == State.OVERHEAT and heat <= 0.0:
        state = State.NORMAL
        charge = 0.0
        EventBus.overheat_ended.emit()   # extinguishes wing fire
```

---

## Visual & Audio Feedback (Integration Points)

All feedback is driven by `EventBus` signals, not direct calls from BoostComponent.

### Engine Smoke
A smoke particle system on each engine. Opacity driven by `boost_heat_updated(heat_pct)`:
- `heat_pct < 0.3`: smoke invisible
- `heat_pct 0.3–0.6`: light smoke, gaining opacity
- `heat_pct 0.6–1.0`: thick smoke

### Heat Warning Border
When `heat_pct > 0.5`, the HUD shows an orange border around the engine health display with flashing "TEMP WARNING" text.

### Heat Audio Beeps
```gdscript
# In audio controller:
func _on_boost_heat_updated(heat_pct: float):
    if heat_pct < 0.5:
        _stop_beep()
    elif heat_pct < 0.85:
        _start_beep(beep_slow, pitch_low)
    else:
        _start_beep(beep_fast, pitch_high)
```

### Engine Pitch
Pod engine audio pitch scales with `current_speed / max_speed` blended with `heat_pct`. Hotter + faster = higher pitch.

### Wing Fire
On `overheat_started`, a particle system ignites on the overheated engine wing. On `overheat_ended`, it extinguishes.

---

## Air Control

Nose pitch (left stick vertical) does NOT directly rotate the pod. It **modulates gravity** — always, grounded or not. `_hover` lerps effective gravity between base `gravity` and fixed `gravity_nose_up` (nose-up) or `gravity_nose_down` (nose-down) by stick deflection. Nose-down therefore presses the pod toward the ground even when the hover springs are engaged. Nose-down charging works grounded because the boost gauge reads `input.pitch` directly.

Thrust and braking are driven along the **yaw-only** forward direction (`_flat_forward()`), NOT the body's pitched forward — body pitch is cosmetic, so arcing the nose up/down never redirects thrust vertically (prevents pitch-induced flyaways and dives).

- **Nose up (pull back):** Reduces effective gravity → pod stays airborne longer, falls slower, reduces landing impact
- **Nose down (push forward):** Increases effective gravity → pod drops faster, presses into the ground, can take landing damage on hard impact
- This is the mechanism for surviving long jumps and controlling descent on shortcut drops

### Rotation Limits
- Pod rotation while airborne is capped — cannot over-rotate beyond a certain angle
- Landing on terrain **auto-levels** the pod (resets rotation toward neutral) unless the impact is severe enough to cause a crash

---

## Braking

The **Airbrake Inverse** stat controls braking power (lower = faster stops). Applied as a deceleration force when the brake button is held. Stronger with higher upgrade tiers. Braking during boost instantly ends it — braking does **not** drain heat; heat only drains by not boosting.
