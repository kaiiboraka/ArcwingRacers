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
- **Nose-down is only required to charge the gauge.** Once boost is active, the player can return to neutral pitch.

### 2. Activation
- When the gauge is full, the player releases the accelerator and immediately presses it again to activate boost.
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

## Visual & Audio Feedback

### Boost Gauge
HUD element showing charge level. When fully charged, the gauge turns yellow — indicating boost is available.

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
