# Abilities

## Overview

Every racer in ArcwingRacers gets either an active ability or a powerful passive. Unlike EP1R where only Sebulba has a special move (flamejet), abilities are a core part of every character's identity.

The ability system uses a plug-and-play design: **weapon type × element**. The same weapon mechanic (e.g., projectile) can be paired with any element, producing different visual and gameplay effects. One scene per weapon type — element drives visuals and flavor.

---

## Elements

### Primary Elements (racer elements)

| Element | Associated Nation |
|---|---|
| Fire | Losalia? |
| Earth | — |
| Wood | — |
| Iron | — |
| Water | — |
| Ice | — |
| Wind | — |
| Lightning | — |

### Other Elements (items/traps only — no racers)

| Element | Potential Use |
|---|---|
| Death | Poison traps, damage-over-time hazards |
| Life | Healing items, shield restoration pickups |

---

## Element Interactions

Element interactions are a **pre-race loadout concern**, not real-time combat mechanics. Before a race, players equip elemental modifications to counter track-specific threats (e.g., fire resistance for volcanic tracks, ice resistance for frozen tracks). During the race, elements do not interact reactively — there is no active combat advantage system.

The interaction table below describes how elements relate for the purposes of loadout planning and track hazard design only:

| Interaction | Context |
|---|---|
| Water washes off Ice | Ice resistance counters water-hazard slowing effects |
| Fire melts Ice | Fire resistance negates ice-hazard traction loss |
| Lightning conducts through Water | Lightning mods are more effective on tracks with water hazards |
| Earth blocks Wind | Earth mods provide wind resistance |

This may be revisited if dedicated combat modes are added later. For standard racing, elements are about identity and visuals, not rock-paper-scissors during gameplay.

---

## Ability Slots

Each racer has at least one ability slot. Some may have two (primary + secondary) depending on character design. The ability is determined by the character's element and cannot be changed — it's part of their identity.

Actives and passives occupy the same slot system. A racer with a passive simply has no active activation — the effect applies continuously or triggers automatically.

---

## Cast Types (Active Abilities)

Active abilities use one of four cast modes:

| Cast Type | Behavior |
|---|---|
| **Instant** | Activates immediately on button press. Projectile fires, effect applies. |
| **Cast Time** | Button press starts a wind-up channel. Ability fires after the cast time completes. Can be interrupted. |
| **Charged** | Hold button to charge. Effect scales with charge duration (damage, range, size). Release to fire. |
| **Channeled** | Hold button for continuous effect. Drains mana per second while held. Effect ends on release or mana depletion. |

---

## Resource Costs

Each ability defines its cost model in data — costs are not fixed globally:

- **Mana cost:** A flat amount deducted on activation (instant/cast time) or per-second while held (channeled).
- **Cooldown:** A duration before the ability can be used again. Timer starts on activation (instant), on fire (cast time), on release (charged), or on release (channeled).
- Some abilities may use only one, some both. All values are defined per ability in data and can be tuned independently during development.

---

## Ability Brainstorm by Element

The following list is speculative — these are candidate ideas, not final designs. Each idea maps to a combination of weapon type (how it works mechanically) and element (visual flavor and identity).

### Fire
- **Flame Jet:** Shoots flame sideways from the pod. Can ignite other racers.
- **Bouncing Fireballs:** Projectile that bounces off walls and track surfaces.
- **Fire Cannon (Super):** Tracks the 1st-place racer, hits them, and swaps positions.

### Water
- **Splash Wave:** AOE knockback — pushes nearby racers away from the pod.
- **Rain:** Creates slippery surfaces as a status effect or environmental hazard on a targeted area.

### Ice
- **Falling Ice:** Drops ice blocks on racers ahead, freezing them briefly.
- **Cold Breath:** Frontal cone that freezes racers in its path.
- **Snowball Cannon:** Projectile that blinds hit racers (visual obstruction).

### Wind
- **Gust:** Blows racers off course or pushes them away from the pod.
- **Clear:** Removes hazards and items from the track ahead.

### Lightning
- **Chain Lightning:** Homing projectile that bounces between nearby racers.
- **Lightning Strike:** Hits a targeted racer from above, stunning them for ~3 seconds.

### Earth
- **Rolling Boulder:** Large boulder rolls down the track, knocking aside racers in its path.
- **Stone Wall:** Drops a wall behind the pod to block pursuers.
- **Mud Trap:** Ground hazard that slows racers who drive through it.
- **Mud Ball:** Projectile that splats and slows the hit racer.

### Iron
- **Cannonball:** Heavy projectile that knocks down racers and explodes on impact.
- **Defensive Armor:** Temporarily strengthens shield, absorbs more damage.
- **Ringing Metal:** AOE sound blast that stuns nearby racers.
- **Blades:** Circular saw blade projectile.
- **Spike Trap:** Falling iron spike ball from above.
- **Chains:** Grappling chain that wraps around a target's wheels to slow/stop them.
- **Grenades:** Explosive projectile.

### Wood
- **Rooting Vines:** Vines wrap around a target's wheels, slowing or stopping them.
- **Rolling Log:** Large log rolls down the track.


