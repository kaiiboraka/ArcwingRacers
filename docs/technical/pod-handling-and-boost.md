# Pod Handling and Boost

## Acceleration

The Acceleration stat does not affect physics force — it controls the **catch-up rate**: how fast the pod's current speed approaches its maximum speed.

When speed is lost (turn, brake, crash, start from standstill), the current speed recovers toward max each frame:

```
current_speed = lerp(current_speed, max_speed, acceleration_factor * delta)
```

The Acceleration component (Injector) modifies the base factor — lower Acceleration stat = higher factor = faster recovery. This applies whenever the accelerator is held and current speed < max speed.

---

## Steering (TBD — needs playtesting)

Steering is likely **yaw rotation** of the pod body, with the linear velocity following behind with lag (creating drift). Two approaches to test:

### Approach A: Yaw + Traction-Gated Drift
1. Steering input applies yaw angular velocity to the pod
2. Pod's linear velocity aligns toward the new forward direction, gated by **Traction** stat
3. Higher Traction = velocity aligns faster = less drift (better grip)
4. Lower Traction = more drift (pod slides through turns)

This gives the "yank" feel (yaw rotation happens immediately on input) while the body's velocity catches up, creating the floaty drift EP1R is known for.

### Approach B: Lateral Force
1. Steering applies a lateral force at the wing positions, pulling the pod sideways
2. Pod rotates as a result of the force offset
3. Response is softer — less immediate yank, more inertia-driven

---

## Boost

EP1R-style: when the boost gauge is full (charged by nose-down at speed), releasing and re-pressing accelerator activates boost.

### Boost Effect
- Adds a flat **Boost Thrust** value to current max speed
- The pod accelerates toward this new temporary max at the normal acceleration rate
- While boosting, **traction is reduced** (handling worsens) — this is a baked-in risk, not a stat
- Heat gauge rises at the pod's **Heat Rate** during boost

### Boost End Conditions
- Heat gauge reaches max → overheat (wing fire, forced cool-down, cannot boost again until fire out)
- Player releases accelerator
- Player applies brakes
- Significant collision
- Pod crashes

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
