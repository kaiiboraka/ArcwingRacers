# Mana and Shield System

## Overview

Mana is a secondary resource alongside the EP1R-style boost/heat system. While boost is charged by nose-pitch at speed and carries risk through overheating, mana is spent on abilities and shielding and is replenished through pickups on the track and successful parries.

Mana and boost are independent — boost has no mana cost.

---

## Mana

### Mana Pool
Each character/Arcwing has their own mana pool — it is not a global or team resource. Maximum capacity is a modifiable vehicle stat via components (similar to how EP1R's stat slots work). Different characters/racers may have different base mana values.

### Mana Regeneration
Mana regenerates in discrete ticks (timer-driven), not continuously. The regen rate and tick interval are modifiable vehicle stats via components — players can invest in faster regen at the cost of other stat upgrades. Tick-based regen ensures deterministic replay and clean rollback.

Regen pauses while the shield is active.

### Mana Pickups
Scattered on the track in three sizes. Pickups are 2D sprites (billboarded Sprite3D), not 3D meshes.

| Type | Mana Value | Placement | Respawn |
|---|---|---|---|
| Small crystal | 5% | Trail edges, common | 8s |
| Large crystal | 20% | Item boxes, shortcuts | 15s |
| Super crystal | 100% | Rare, special locations | 45s or one-time |

Values lean small intentionally — you should want to pick up lots of crystals, not fill from one pickup. Large and Super are route-knowledge rewards.

### Combat Drop
When a racer is hit by an ability or significant collision, they drop ~15% of their current mana as pickup crystals that scatter into the world. Dropped crystals fly up and outward in an arc, then land with a small bounce — the scatter is visible and readable, not a single pickup at the hit point. These crystals never respawn.

No drops below a minimum threshold (prevents death-spiral at low mana).

---

## Shield

### Activation
Hold the shield button (Left Trigger / Left Shift). Direction is set by the right analog stick and snaps to one of four cardinal positions: front, back, left, right. The right stick's full 360° range is divided into four 90° quadrants — for example, with north as 0°, the north quadrant is -45° to +45°. The initial direction on press is the current stick position. Deadzone is significant (tunable). The direction persists until changed — you can hold the button and move the stick to rotate the shield mid-use.

When the shield moves between positions, it tweens with an elastic bounce at a configurable rate — it doesn't snap instantly.

### Mana Cost & Shield Strength
- **Holding:** Drains mana continuously while active (in-sync with frame input, not discrete timer).
- **Blocking:** A blocked hit drains additional mana proportional to the damage dealt, divided by the pod's **Shield Strength** stat. Higher Shield Strength = more efficient blocks (less mana lost per hit).
- **Parry (timed block):** If the shield is raised just before impact (a tunable frame window), the attack is parried. A successful parry **restores mana** instead of consuming it. No mana cost from the parried hit. Higher Shield Strength also widens the parry window slightly.
- **Miss:** Raising the shield when nothing hits you still drains mana (waste).

### Damage & Break
- The shield is a physical collision volume — if something hits it, the hit is blocked.
- Blocked hits drain additional mana: `damage * base_multiplier / shield_strength`. Higher Shield Strength = less mana loss.
- If mana hits zero while the shield is active, the shield **breaks**: the pod is momentarily stunned (a brief spin-out, like a Mario Kart banana slip). The shield cannot be re-raised until mana recovers above a threshold.
- This makes parrying the premier skill expression: time the raise perfectly, take no mana damage, and get a refund.

### Directional Behavior
- Front shield blocks front attacks only. Rear guard blocks rear attacks.
- Shield direction can be changed freely while held.
- Diagonal attacks are blocked by whichever cardinal quadrant they fall into.

### Stat Tradeoffs
Shield Strength competes with other vehicle stats in the component/upgrade system. It will not be possible to max every stat — investing in efficient shielding comes at the cost of speed, acceleration, cooling, or other attributes. Character base stats and component mods determine these tradeoffs.

---

## Interaction with Boost

Boost and mana are independent systems:
- Boost is EP1R-style: charged by nose-pitch at speed, no mana cost. The cost is handling loss, collision risk, and overheating.
- Abilities use mana + cooldowns.
- Shield uses mana.
- This may be reconsidered later (boost costing mana is a potential balance lever).
