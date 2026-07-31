# Boost and Heat System

## Overview

The boost/heat system is the core risk-reward mechanic of ArcwingRacers, copied directly from Star Wars Episode I: Racer. It interleaves speed management, heat management, and a damage penalty for overindulgence.

## Mechanic Flow

```
           [Not fast enough]  ←→  [At speed, holding forward]
                 OFF                    GREEN (gauge fills)
                                             ↓
                                        [gauge full]
                                        YELLOW (primed)
                                             ↓
                                   [press Boost]
                                             ↓
                                     RED (boosting)
                                    ←→ [heat rising]
                                             ↓
                          [release/brake/speed drop]      [heat max]
                                             ↓                 ↓
                                          OFF            Wing Fire
                                                            ↓
                                                    [Must Cool Fully]
                                                            ↓
                                                       [Fire Out]
```

---

## Stage Lights

The boost HUD light shows one of four stages:

| Stage | Light | Meaning |
|-------|-------|---------|
| **OFF** | Off | Below charge speed — holding forward does nothing |
| **GREEN** | Green | At charge speed — gauge fills while holding forward |
| **YELLOW** | Yellow | Gauge full — boost primed, press Boost to activate |
| **RED** | Red | Boost active — heat rising |

## Phase Details

### 1. Charge Phase
- Holding the forward input (nose down) while **at or near maximum speed** fills the boost gauge — the pod must be above a charge-speed threshold (default 80% of max speed).
- **Forward input must be held basically all the way forward** to count — the stick has to be within `charge_pitch_deadzone_deg` (default 10°) of full deflection, so charging is a committed straight-line action. A light nose-down that would also let you steer does not charge. (This is the "wings on the ground, flying straight" pose.)
- Below that threshold the gauge is **OFF** (stage light off); at or above it the light goes **GREEN** and the gauge fills.
- **Releasing forward resets the gauge instantly.** The gauge is not retained between pulses — each hold starts from empty.
- The gauge visually fills in the HUD. Audio pitch rises as it approaches full.
- **Forward input is only required to charge the gauge.** Once boost is active, the player can return to neutral.

### 2. Activation
- When the gauge is full (stage light **YELLOW**), the player presses the Boost button to activate boost — a single keypress, not EP1R's release-and-repress (the N64 controller's limited buttons drove that pattern; it is not a constraint here).
- Boost immediately adds a flat amount to current speed.
- The pod accelerates rapidly toward a **boost max speed** that is *additive* on top of the pod's normal max speed (normal max + boost bonus), not a fixed value.
- Boost can be activated at any time the gauge is full, including mid-turn or mid-air.

### 3. Boost Phase (RED)
- During boost, the **heat gauge** rises continuously at the pod's **Heat Rate**.
- Boost continues until one of:
  - Heat gauge reaches maximum → **overheat**
  - Player releases forward
  - Player applies brakes (instantly ends boost — braking is not a heat-drain skill move)
  - Pod's speed drops far below max (a massive speed loss ends boost early)
  - Pod collides with another pod or obstacle (significant collision)
  - Pod crashes (out of bounds / flip)
- Elemental mods on the engine slot modify Heat Rate (see [pod-stats.md](pod-stats.md)).

### 4. Overheat
- When heat reaches maximum, boost forcibly disengages.
- One of the pod's **wings catches fire** (visual + particle effect).
- The pod loses all boost benefits immediately.
- The pod **cannot boost again** until the fire is extinguished.

### 5. Cooling
- Heat drains whenever the pod is **not boosting** — boosting stops cooling and starts heating.
- After a voluntary end, the gauge depletes at the **Cool Rate** while the pod re-charges.
- During overheat, the gauge must fully drain before the fire goes out and boosting is possible again.
- Elemental mods modify Cool Rate.

---

## Visual & Audio Feedback

### Boost Gauge
HUD element showing charge level and stage light (OFF / GREEN / YELLOW / RED — see [Stage Lights](#stage-lights)). The light is **OFF** when too slow to charge, **GREEN** while the gauge fills, **YELLOW** when full and boost is available, and **RED** while boost is active. Releasing forward drops the gauge back to empty instantly.

### Heat Gauge
HUD element near the speed gauge. Color shifts from green → yellow → red as temperature rises.

### Engine Smoke
A smoke mesh/texture appears behind the engines during boost. Its opacity scales with heat level — barely visible at low heat, thick and opaque near overheat.

### Heat Warning Border
When heat exceeds ~50%, an orange border appears around the engine health display. "TEMP WARNING" text flashes at the top of the border.

### Heat Audio Beeps
A 3-phase audio warning tied to heat level:
- **Phase 1 (~50–85% heat):** Slow beeps at low pitch
- **Phase 2 (~85%+):** Fast beeps at high pitch — imminent overheat
- **No beep** below ~50% heat

### Wing Fire
When overheat occurs, a particle effect ignites on one of the wings (the flaming engine). The fire spreads audibly and visually. Boost cannot be used again until the fire is fully extinguished.

### Engine Pitch
Engine sound pitch scales with both speed and heat level — hotter + faster = higher pitch.
