# Divergences from EP1R

## Overview

ArcwingRacers uses Star Wars Episode I: Racer as its primary mechanical reference — physics feel, boost/heat system, stat model, component tiers, and junkyard economy all start from EP1R's baseline. This document tracks every intentional divergence.

---

## Progression

### License Rank (not race-count)
EP1R gates part availability by number of races completed (2/4/6/8/10/12/14/16). ArcwingRacers uses **License Rank** — points earned from placements, not completions. Winning awards the most; top-half finishes contribute; bottom-half earns nothing. A player who wins hard races early ranks up faster than someone grinding easy ones.

### Difficulty-Controlled Payout
EP1R has three payment modes (Fair/Skilled/WTA) independent of AI difficulty — each track has a fixed AI Level (86–113) and the player only chooses purse split. ArcwingRacers replaces this: **difficulty selection controls both AI strength and prize payout**. Higher difficulty = harder AI opponents + larger first-place reward. Lower difficulty = easier AI + smaller payout. The risk-reward choice is unified into one slider.

---

## Economy

### Explicit Selling
EP1R only supports trade-in (swap old part toward new part's cost, pay the difference). ArcwingRacers adds direct selling: any owned part (equipped or in storage) can be liquidated for its current market value.

### Part Warehouse
EP1R forces the player to carry every owned part (limited screen space). ArcwingRacers adds indefinite storage. Stored parts do not degrade. Enables collecting multiple loadouts.

### Multi-Currency
EP1R has one currency (truguts). ArcwingRacers has two:
- **Losallian Crowns** — general money for parts, repairs, upgrades
- **Elemental Cores** — earned from Archon Races, spent on elemental mods at nation shops

### Elemental Mod System
Not present in EP1R. Three mod types purchasable with Elemental Cores:
- **Environmental Resist** — immunity to specific track hazards (e.g., fire resist in lava biomes)
- **Stat Modifier** — kiss-curse (increases one stat, decreases another)
- **Perk** — conditional effect (e.g., "while surging, protected from choked")

### Nation Shops
EP1R has one shop (Watto's). ArcwingRacers has per-nation shops, each specializing in its native element's mods. Off-element cores cost more.

---

## Repairs & Pit Droids

### In-Race Repairs
EP1R repairs are done in-race by holding R: the most-damaged engine segment is repaired first, the engine goes briefly offline (pod slows, handles poorly), and segments are only restored to **yellow** condition (never full green). ArcwingRacers **keeps this as-is.**

### Garage Repairs (divergence)
Not in EP1R. ArcwingRacers adds a garage where players can pay Losallian Crowns to repair damaged components between races. Cost scales with damage severity only (pod's Repair Rate stat does not affect garage cost — it only governs in-race repair speed).

### Pit Droid Function
In EP1R, pit droids do NOT prevent damage. After each race, each droid repairs one damaged component, automatically targeting the 4 most expensive parts you own that aren't at full health. Droids are not assigned to specific slots and don't stack. Guide advises buying all 4 droids before any upgrade components. Once all races are completed, parts permanently fix in their current condition (any subsequent repairs are cash-only).

**Divergence — Equipped-only targeting:** Since ArcwingRacers has a part warehouse (stored parts), pit droids only target **equipped** parts. Damaged parts in storage must be repaired manually in the garage or equipped so the droids can heal them.

---

## Characters & Abilities

### Elemental Abilities
EP1R only has one racer with a special ability (Sebulba's flamethrower). In ArcwingRacers, **every character** gets either an active ability on cooldown or a powerful passive. Abilities use a plug-and-play system: weapon type × element. E.g., "Flamethrower (Fire)" vs "Cone of Cold (Ice)" using the same weapon mechanic with different elements.

### Secret Characters with Fixed Parts
EP1R secret characters are purely cosmetic unlocks. In ArcwingRacers, secret/boss characters have unique permanent pod parts that cannot be changed or removed — giving them a fixed gameplay identity alongside customization.

---

## AI

### Randomized Loadouts
EP1R AI racers have fixed speed values per difficulty bucket. ArcwingRacers AI racers get **randomized component loadouts** within a quality range for their tier, creating more variety in opponent behavior and making each race feel different.

---

## Modes

### Mercenary Races
Not in EP1R. A random pick-up race on a random track with random AI opponents. Pays Losallian Crowns based on performance relative to expectations. Available as a secondary income source between tournament races.

### Archon Races (Roguelike Mode)
Not in EP1R. Choose an Archon character, race through a region's tracks with permadeath — one crash ends the run. Elimination format (last place or crash = eliminated). Between races, choose from 3 upgrade paths. Elemental Imbalance occurs frequently. High risk/reward.

### Alternate Objective Modes
Not in EP1R. Potential post-launch modes:
- Ring Race — pass through all checkpoint rings
- Quick-Run — up to 3 laps, beat target time, rewards scale with fewer laps needed
- Last Racer Running — combat/elimination (item-based, Mario Kart-like)
- Hyper-Hazard — all hazards active simultaneously
- Mario Kart-style party mode with items
- Kirby Air Ride-style City Trial mode
- Capture the Flag, Rocket League-style, Halo Zombies variants

### Goofy Modifiers
Not in EP1R. Mirror mode, manual controls, hyper speed, ice/lava floors, Big Head / Little Head mode, Halo-style Birthday Party — cheat-adjacent fun modifiers.

---

## Track Design

### Environmental Hazards
EP1R tracks are mostly terrain + obstacles. ArcwingRacers adds systemic hazards: temperature (boost overheats you; hot areas amplify, cold areas help), monsters, geysers, destroyable walls (boost through for shortcuts), underwater sections.

### Elemental Imbalance
Not in EP1R. A track modifier akin to Mario Galaxy's prankster comets — remixes a level with a different element's hazards, visuals, and shortcuts. An ice level invaded by Fire will have lava replacing icy cavern shortcuts. Any element can invade any track, systemically changing targeted features.

### Dynamic Track Assembly
EP1R also used modular chunk segments to build levels, but each combination was baked as a fixed track. ArcwingRacers reuses the same chunks **dynamically at runtime** to create new randomized track layouts during gameplay — enabling Archon Races mode's procedural-ish generation and infinite variety from the same authored segments.

---

## Multiplayer

### Built From Day One
EP1R is single-player only (the N64 version had a 2P splitscreen mode, but it was simplistic). ArcwingRacers targets splitscreen (2–4), LAN, and P2P online from the same code path. AI fills empty slots up to 16 racers.
