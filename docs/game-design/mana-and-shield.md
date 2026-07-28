# Mana and Shield System

## Overview

Mana is a secondary resource alongside the EP1R-style boost/heat system. While boost is charged by nose-pitch at speed and carries risk through overheating, mana is spent on abilities and shielding and is replenished through pickups on the track and successful parries.

Mana and boost are independent — boost has no mana cost.

---

## Mana

### Mana Pool
Each pod has a mana pool. Maximum capacity is a modifiable vehicle stat via components (similar to how EP1R's stat slots work). Some characters/racers may have different base mana values.

### Mana Regeneration
Mana regenerates slowly over time. The regeneration rate is a modifiable vehicle stat via components — players can invest in faster regen at the cost of other stat upgrades.

### Mana Pickups
Scattered on the track in two sizes:

| Type | Location | Effect |
|---|---|---|
| Small crystal | Trail edges, common | Small mana restore |
| Large crystal | Item boxes, shortcuts | Large mana restore |
| Super crystal | Rare, special locations | Fills entire mana bar |

### Combat Drop
When a racer is hit by an ability or collision, they drop some of their current mana as pickup crystals that any racer can collect.

---

## Shield

### Activation
Hold the shield button (Left Trigger / Left Shift). Direction is set by the right analog stick (horizontal) or mouse and snaps to one of four positions: front, back, left, right. The direction persists until changed.

### Mana Cost
- **Holding:** Drains mana continuously while active.
- **Parry (timed block):** If the shield is raised just before an impact, the attack is parried. A successful parry **restores mana** instead of consuming it. No mana cost.
- **Miss:** Raising the shield when nothing hits you still drains mana (waste).

### Behavior
- Blocks incoming damage from abilities and some hazards.
- Direction matters — a front shield does not block a rear attack.
- Shield direction can be changed while held.

---

## Interaction with Boost

Boost and mana are independent systems:
- Boost is EP1R-style: charged by nose-pitch at speed, no mana cost. The cost is handling loss, collision risk, and overheating.
- Abilities use mana + cooldowns.
- Shield uses mana.
- This may be reconsidered later (boost costing mana is a potential balance lever).
