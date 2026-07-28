# ADR 0003: Vehicle Stats and Component Model

## Status
Accepted

## Context
ArcwingRacers targets the game feel of Star Wars Episode I: Racer. That game's vehicle performance is defined by 15 numeric attributes, 7 of which are improvable via purchased upgrade components with defined tier lists and costs. The junkyard economy (buying used parts, repairing them, trading up) is a core loop of single-player progression.

We need a baseline stat model that supports the remaining 8 fixed attributes (per-racer identity), 7 upgradable attributes (component progression), and 3 physical handling factors (pod width, cable length, binder length).

## Decision
Adopt the EP1R stat model directly as the baseline:

**7 Upgradable stats** (each with a component slot):
- Traction (Anti-Skid) — grip on turns and slippery surfaces
- Turn Response — time to reach max turn rate after steering input
- Acceleration — rate of speed increase (lower = faster acceleration in EP1R convention)
- Maximum Speed — top speed before boost
- Airbrake Inverse — braking power (lower = faster stops)
- Cool Rate — how fast engines cool after boost
- Repair Rate — how fast engine damage is repaired

**8 Fixed per-racer stats:**
- Maximum Turn Rate — sharpness of turn (higher = tighter)
- Boost Thrust — speed added during boost
- Heat Rate — how fast engines heat during boost
- Deceleration Inverse — how fast pod slows without brakes (higher = coasts longer)
- Hover Height — ride height above ground
- Bump Mass — force imparted in collisions
- Damage Immunity — damage resistance (lower = takes less damage)
- Intersect Radius — collision/hitbox size

**3 Physical handling factors** (non-numeric, visual-authoring):
- Podracer Width — visual width, affects tilt behavior in turns
- Cable Length — distance between cockpit and engines, affects swing in turns
- Binder Length — width of the energy beam between engines, affects rigidity

**Component upgrade tiers:**
Copy EP1R's exact tier lists and costs as a starting point (7 slots × 6 tiers each, default + 5 upgrades). Tune during playtesting.

**Component health and damage (EP1R baseline):**
Components take damage during races from collisions. The pod has 2 engines (left/right) × 3 sections (front/middle/back) = 6 health segments, each mapped to a component slot. As a segment takes damage, its status degrades from green → yellow → orange → red (critically damaged, "WARNING" flashing). A destroyed segment means the component is lost.

Damage rules:
- **Only components above the cheapest base tier are eligible for damage.** The default/starting part in each slot never takes damage.
- **Damage only triggers on a first-time race completion.** Re-running a completed race does not degrade parts. This makes the junkyard exploit finite.
- **In-race repairs (EP1R):** Hold R to repair. The most-damaged segment is repaired first. Repairs take the engine offline (pod slows, handles poorly). Repairs only restore to **yellow** condition, never full green. Cannot repair green or yellow segments — only orange/red.
- **After all races are completed (EP1R):** Parts are permanently fixed in their current condition. The only way to improve them is to pay cash.

**Pit Droids (EP1R baseline):**
- Start with 1 pit droid, purchase up to 3 more (max 4)
- Pit droids do NOT prevent damage during a race
- **After a race**, each droid repairs one damaged component. They automatically target the 4 most expensive **equipped** parts not at full health (warehouse storage excluded). Droids are not assigned to specific slots and do not stack — they always pick the most valuable damaged equipped part.
- Guide advises buying all 4 droids before any upgrade components, because keeping parts repaired saves more money over the long run.
- Once all races in the tournament are completed, parts are permanently fixed in their current condition. Cash-only repair if you want to fix them afterward.

**Divergence from EP1R — Garage Repairs:**
EP1R's garage screen is view-only: it shows item health bars and pit droid status, with a shortcut to the shop to buy the same category of part. There is no paid repair option. ArcwingRacers adds the ability to **pay Losallian Crowns** to repair damaged components between races. Cost scales with damage severity only (not affected by the pod's Repair Rate stat, which only governs in-race repair speed).

**Trade-in system (EP1R baseline):**
When buying a new part from a shop, the price of the player's current equipped part is subtracted from the new part's list price. The player only pays the difference.

**Divergence from EP1R — Explicit Selling:**
EP1R only allows trade-in (no direct sale). ArcwingRacers adds explicit selling: players can sell any owned part (equipped or in storage) directly for its current market value.

**Divergence from EP1R — Part Storage:**
EP1R forces the player to carry every owned part at all times. ArcwingRacers adds a **part warehouse** where players can store parts indefinitely without degradation.

**Divergence from EP1R — License-Based Progression:**
EP1R gates part availability purely by number of races completed (2, 4, 6, 8, 10, 12, 14, 16 races). ArcwingRacers replaces this with **License Rank** progression: points earned from placements, not completions.

## Consequences
- **Positive:** Proven, balanced stat model directly from the reference game. Community knowledge about EP1R stat interactions transfers.
- **Positive:** Junkyard economy (used parts with damage, repair-to-restore) has a clear stat target.
- **Positive:** Component health creates a compelling between-races management layer — which slots to protect with pit droids, which to let degrade.
- **Positive:** 8 fixed stats per racer create natural identity — two identically-equipped pods handle differently.
- **Tradeoff:** Some stat conventions are counterintuitive (lower Acceleration = faster acceleration). Documentation and variable naming must clarify this.
- **Tradeoff:** EP1R's exact values may need retuning for our different track scales and physics timestep.
- **Tradeoff:** Damage-to-component-slot mapping (which collision region damages which slot) is not documented in EP1R sources — will need to be defined during implementation.
