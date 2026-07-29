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
1. Steering input applies yaw angular velocity to the pod
2. Pod's linear velocity aligns toward the new forward direction, gated by **Traction** stat
3. Higher Traction = velocity aligns faster = less drift (better grip)
4. Lower Traction = more drift (pod slides through turns)

This gives the "yank" feel (yaw rotation happens immediately on input) while the body's velocity catches up, creating the floaty drift EP1R is known for.

### Visual: Chassis Sway
From EP1R observation — the chassis (chariot body) swings much further than the engines during turns. The engines stay centered in the view while the chariot moves left/right. This is handled by the spring-offset nodes on the visual groups.

### Visual: Engine Counter-Tilt
During turns, the engines tilt in opposite vertical directions:
- **Right turn:** Right engine tilts down, left engine tilts up
- **Left turn:** Left engine tilts down, right engine tilts up

This is separate from chassis sway — a per-engine rotation on the wing visual groups.

### Visual: Mechanical Opening
Fins, wings, vents, and other moving parts on each engine open as turn rate increases, stay open while the turn is held, and decay back to closed when the stick returns to neutral. Each part tracks its own openness — they can be at different levels simultaneously (e.g., partially open during a gentle turn). This is independent of the engine counter-tilt above.

### Nose Tilt
Engines tilt slightly up or down based on nose pitch input, matching the pod's pitch attitude. Purely visual on the engine visual groups.

### Dismissed: Lateral Force
Applying lateral force at wing positions was considered but produces a softer, more inertia-driven response. The EP1R reference requires the immediate yank of yaw rotation.

---

## Boost System

**Location:** `systems/boost/boost_component.gd`
**Dependencies:** InputBuffer, EventBus

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
@export var boost_max_speed: float = 800.0

# ── State ──
enum State { CHARGING, READY, BOOSTING, OVERHEAT, COOLING }
var state: State = State.CHARGING
var charge: float = 0.0        # 0.0 → 1.0 (full)
var heat: float = 0.0          # 0.0 → 1.0 (max = overheat)
var max_heat: float = 1.0
var min_charge_speed: float = 0.8  # fraction of max speed required to charge
```

### Charge Phase

Nose-down while at speed fills the gauge. The gauge does not charge when coasting or slow.

```gdscript
func _charge(delta: float, nose_pitch: float, speed_fraction: float):
    if state != State.CHARGING:
        return
    if nose_pitch >= 0.0 or speed_fraction < min_charge_speed:
        return
    charge += charge_rate * abs(nose_pitch) * delta
    charge = min(charge, 1.0)
    if charge >= 1.0:
        state = State.READY
        EventBus.boost_ready.emit()
```

### Boost Activation

When the gauge is full (state = READY), the player releases the accelerator and presses it again. The hold-release-repress pattern is detected by the input buffer:

```gdscript
func try_activate(acceleration_held: bool, acceleration_just_pressed: bool):
    if state != State.READY:
        return
    if acceleration_just_pressed:
        _start_boost()

func _start_boost():
    state = State.BOOSTING
    heat = 0.0
    EventBus.boost_started.emit()
```

**Nose-down is only required to charge the gauge.** Once boost is active, the player returns to neutral pitch — boost continues regardless of nose position.

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

    # Traction reduced during boost
    EventBus.traction_modifier.emit(0.5)   # 50% traction
```

### Boost End Conditions

Boost ends when any of:
- Heat reaches max → overheat
- Player releases accelerator
- Player applies brakes
- Significant collision (above damage threshold)
- Pod crashes

```gdscript
func end_boost():
    if state == State.BOOSTING:
        state = State.COOLING
        heat = max(heat, 0.1)   # preserve current heat for cooldown
        EventBus.traction_modifier.emit(1.0)   # restore traction
        EventBus.boost_ended.emit()
```

### Overheat

When heat reaches maximum, boost forcibly disengages. Wing fire starts. The pod cannot boost again until the fire is extinguished — heat gauge must fully drain.

```gdscript
func _overheat():
    state = State.OVERHEAT
    EventBus.traction_modifier.emit(1.0)
    EventBus.overheat_started.emit()   # triggers wing fire VFX + SFX
```

### Cooling

After boost ends (voluntary or forced), heat depletes at the Cool Rate. During overheat, the gauge must fully drain before the fire goes out and the pod can boost again.

```gdscript
func _cool_process(delta: float):
    if state != State.COOLING and state != State.OVERHEAT:
        return

    heat -= cool_rate * delta
    heat = max(heat, 0.0)

    if heat <= 0.0:
        if state == State.OVERHEAT:
            state = State.CHARGING
            charge = 0.0
            EventBus.overheat_ended.emit()   # extinguishes wing fire
        else:
            state = State.CHARGING
```

Braking while boosting also reduces heat (a skill move — trade speed for safety):

```gdscript
# Called from pod_controller when brake is held during boost
func brake_cool(brake_strength: float, delta: float):
    if state == State.BOOSTING:
        heat -= brake_cool_rate * brake_strength * delta
        heat = max(heat, 0.0)
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

Nose pitch (left stick vertical) does NOT directly rotate the pod. It **modulates gravity**:

- **Nose up (pull back):** Reduces effective gravity → pod stays airborne longer, falls slower, reduces landing impact
- **Nose down (push forward):** Increases effective gravity → pod drops faster, can take landing damage on hard impact
- This is the mechanism for surviving long jumps and controlling descent on shortcut drops

### Rotation Limits
- Pod rotation while airborne is capped — cannot over-rotate beyond a certain angle
- Landing on terrain **auto-levels** the pod (resets rotation toward neutral) unless the impact is severe enough to cause a crash

---

## Braking

The **Airbrake Inverse** stat controls braking power (lower = faster stops). Applied as a deceleration force when the brake button is held. Stronger with higher upgrade tiers. Braking also reduces heat during boost (one way to cool down without fully overheating).
