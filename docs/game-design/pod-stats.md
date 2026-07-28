# Pod Stats & Components

## Overview

Each pod (Arcwing) is defined by 15 numeric attributes plus 3 physical handling factors. Seven attributes are improvable via purchased upgrade components; eight are fixed per-racer and define their unique handling identity. The 3 physical factors are visual-authoring properties that affect tilt, swing, and rigidity behavior.

---

## 7 Upgradable Stats

Each has a dedicated component slot with 6 tiers (default + 5 upgrades).

### Traction (Anti-Skid)
- Determines grip on turns and slippery surfaces.
- Higher = better grip on ice/mud/curve-heavy tracks.
- **Component:** Repulsorgrip upgrades.
- **Range:** 0.00–1.00.

### Turn Response
- Time for the pod to react to steering input.
- Higher = more responsive, less sluggish.
- **Component:** Control upgrades.
- **Range:** 202–900.

### Acceleration
- Rate of speed increase.
- **EP1R convention:** Lower value = faster acceleration.
- **Component:** Injector upgrades.
- **Range:** 0.30–4.00.

### Maximum Speed
- Top speed before boost.
- **Component:** Thrust Coil upgrades.
- **Range:** 475–650.

### Airbrake Inverse
- Braking power.
- **EP1R convention:** Lower value = faster stops.
- **Component:** Air Brake upgrades.
- **Range:** 14–45.

### Cool Rate
- How fast engines cool after boost.
- Higher = faster cooling.
- **Component:** Radiator/Pump upgrades.
- **Range:** 1.7–20.0.

### Repair Rate
- How fast the in-race hold-R repair cycles through damaged segments.
- Higher = faster repair. Does NOT affect garage repair costs or pit droid speed.
- **Component:** Power Cell upgrades.
- **Range:** 0.10–1.00.

---

## 8 Fixed Per-Racer Stats

Not upgradable. Define racer identity.

| Stat | Description | Higher is... |
|---|---|---|
| Maximum Turn Rate | Sharpness of turning circle | Better (tighter turns) |
| Boost Thrust | Speed added during boost | Better (faster boost) |
| Heat Rate | How fast engines heat during boost | Worse (faster overheat) |
| Deceleration Inverse | How fast pod slows naturally | Worse (coasts longer) |
| Hover Height | Ride height above ground | Situational |
| Bump Mass | Force in collisions | Better (pushes others harder) |
| Damage Immunity | Damage resistance | Worse (takes more damage) |
| Intersect Radius | Collision hitbox size | Worse (bigger target) |

---

## 3 Physical Handling Factors

These are visual/physical authoring properties of the pod model, not numeric stats.

| Factor | Effect |
|---|---|
| Podracer Width | Wider pods tilt more in turns. Affects stability through tight gaps. |
| Cable Length | Distance from cockpit to engines. Longer cables = more swing in turns, looser steering. |
| Binder Length | Width of the energy beam connecting the engines. Wider = more rigid turning, less tilt. |

---

## Component Tiers

Each of the 7 upgrade slots has 6 tiers (default + 5 purchasable upgrades) with increasing costs. EP1R's exact tier lists and costs serve as the baseline — see `pod-racer-notes/original-racer-component-stats.md` for the reference data.

Tuning during playtesting will adjust values as needed.

### Component Economy

- **New parts:** Purchased from nation shops. Price increases with tier. **Trade-in subtraction (EP1R rule):** when buying new, the shop subtracts the value of the player's current equipped part from the price — the player only pays the difference.
- **Used/Junkyard parts:** Found at reduced price with random damage. Any tier can appear even if not yet unlocked in shops. Must be repaired before use. **EP1R rule:** inventory resets when leaving the screen.
- **Damage rules:** Only parts above the cheapest base tier are eligible for damage. Damage only occurs on first-time race completions — re-running a completed race does not degrade parts.
- **Trade-in (EP1R):** Old parts traded toward new purchase. Value = current market value × condition. EP1R only supports this; ArcwingRacers adds explicit selling.
- **Explicit selling (divergence):** Any owned part (equipped or stored) can be sold directly for its current market value — no trade-in target needed.
- **Part warehouse (divergence):** Parts can be stored indefinitely without degradation. No forced carry limit.
- **Repair:** Damaged parts can be repaired in the garage for Losallian Crowns (cost scales with damage severity, reduced by the pod's Repair Rate stat). Pit droids repair their assigned slot for free between races.
