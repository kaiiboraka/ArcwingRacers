# Boost and Heat System

## Overview

The boost/heat system is the core risk-reward mechanic of ArcwingRacers, copied directly from Star Wars Episode I: Racer. It interleaves speed management, heat management, and a damage penalty for overindulgence.

## Mechanic Flow

```
[Nose Down at Speed] → [Boost Gauge Fills]
         ↓
  [Activate Boost]
         ↓
[Boost Engaged] ←→ [Heat Gauge Rising]
         ↓                    ↓
  [Release/Crash]      [Heat Max → Overheat]
         ↓                    ↓
  [Cool Phase]          [Wing Fire]
                            ↓
                    [Must Cool Fully]
                            ↓
                    [Fire Extinguished]
```

---

## Phase Details

### 1. Charge Phase
- Pushing the nose down (pitch forward) while **at or near maximum speed** fills the boost gauge.
- The gauge only charges when the pod is moving fast enough. Coasting or slow speeds do not charge.
- The gauge visually fills in the HUD. Audio pitch rises as it approaches full.

### 2. Activation
- When the gauge is full, the player presses the Boost button to activate.
- Boost immediately adds a flat amount to current speed.
- The pod accelerates rapidly toward a higher **boost max speed**.
- Boost can be activated at any time the gauge is full, including mid-turn or mid-air.

### 3. Boost Phase
- During boost, the **heat gauge** rises continuously at the pod's **Heat Rate**.
- Boost continues until one of:
  - Heat gauge reaches maximum → **overheat**
  - Player releases accelerator
  - Player applies brakes
  - Pod collides with another pod or obstacle (significant collision)
  - Pod crashes (out of bounds / flip)
- Elemental mods on the engine slot modify Heat Rate (see [pod-stats.md](pod-stats.md)).

### 4. Overheat
- When heat reaches maximum, boost forcibly disengages.
- One of the pod's **wings catches fire** (visual + particle effect).
- The pod loses all boost benefits immediately.
- The pod **cannot boost again** until the fire is extinguished.

### 5. Cooling
- After boost ends (voluntary or forced), the heat gauge depletes at the **Cool Rate**.
- During overheat, the gauge must fully drain before the fire goes out.
- Elemental mods modify Cool Rate.

---

## Visual Feedback

- **Boost gauge:** HUD element showing charge level.
- **Heat gauge:** HUD element near speed gauge. Color shifts from green → yellow → red.
- **Wing fire:** Particle effect on the flaming engine. Spreads audibly.
- **Engine pitch:** Scales with speed and heat level.
