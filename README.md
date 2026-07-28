# ArcwingRacers

High-speed low-poly 3D fantasy racing game set on the planet Elythia. Players pilot magical hovercraft called **Arcwings** — chariot-like pods with detached floating arcane engines — across diverse biomes in tournament racing.

Built in **Godot 4** (GDScript). Primary reference: *Star Wars Episode I: Racer.*

---

## Overview

ArcwingRacers targets the physics feel, boost/heat risk-reward, and pod customization of EP1R, then expands on it with elemental character abilities, mana/shield mechanics, modular track hazards, a roguelike Archon Race mode, and deeper economy systems with part storage and explicit selling.

The game world is **Elythia** — a planet of 12 elemental nations. The summer month of Taikaran features an Elythian Olympics where Arcwing racing is the premier sport.

---

## Architecture

Four-pillar folder structure with strict one-way dependency flow:

| Pillar | Contents |
|---|---|
| `addons/` | Libraries and tools reusable across 3D games |
| `systems/` | Core game rules and mechanics |
| `ui/` | User interface — reads from systems via signals, never writes to them |
| `content/` | Assets, scenes, scripts, levels |

UI ↔ gameplay communication routes through an EventBus autoload at `systems/events/event_bus.gd`.

---

## Major Divergences from EP1R

| Area | EP1R | ArcwingRacers |
|---|---|---|
| Abilities | Only Sebulba has one | Every racer has an active ability or passive |
| AI | Fixed speed buckets | Randomized loadouts per difficulty tier |
| Progression | Race-count gating | License Rank (points from placements) |
| Economy | Trade-in only | Explicit selling, part warehouse |
| Currency | Single (truguts) | Losallian Crowns + Elemental Cores |
| Shops | One shop (Watto's) | Per-nation shops with elemental specialization |
| Repairs | In-race hold-R only | In-race hold-R + garage paid repairs |
| Pit Droids | Speed up repair | Same, but equipped-parts only |
| Tracks | Static obstacles | Systemic hazards, Elemental Imbalance events |
| Modes | Campaign + time attack | Campaign, Mercenary, Archon Races (roguelike), multiplayer |

Full breakdown: `docs/game-design/differences-from-ep1r.md`

---

## Features

### Core Mechanics
- **Hover Physics** — 4 spring-raycast suspension on CharacterBody3D, independent corner damping, natural terrain following
- **Boost/Heat System** — EP1R-style: nose-pitch charge, release-and-re-press activate, heat buildup leads to wing fire
- **Air Control** — nose pitch modulates gravity (pull back to stay airborne, push forward to descend)
- **In-Race Repairs** — hold R to repair damaged engine segments (engine offline during repair, yellow-only restoration)
- **Pod-on-Pod Collisions** — damage + shoving based on relative speed, angle, and Bump Mass; wall pinning compounds damage

### Pod Customization
- 7 upgrade slots (Traction, Turn Response, Acceleration, Top Speed, Airbrake, Cool Rate, Repair Rate)
- 6 tiers per slot with EP1R-derived component names and costs
- Component health degrades in races — pit droids repair equipped parts between races
- **Elemental mods** — Environmental Resist, Stat kiss-curse, and Perks purchased with Elemental Cores
- **Part warehouse** — store parts indefinitely, no degradation, build multiple loadouts
- **Junkyard** — randomized used parts at discount, any tier can appear even if locked

### Mana & Shield
- Mana pool with slow regen + track pickups (small crystals, large crystals, super crystals)
- Hit racers drop mana
- Directional shield (front/back/left/right) — hold to drain mana, parry timing restores mana

### Abilities
- Plug-and-play: weapon type × element (e.g., Flamethrower/Fire vs Cone of Cold/Ice)
- Element interactions: water washes ice, fire melts ice, wind blows water, lightning conducts through water
- Each racer has at least one ability determined by their element

### Controls
- Left stick: steer + nose pitch
- Right stick: 90° ship tilt
- Left trigger: shield (hold/parry)
- Right trigger: ability
- Face buttons: accelerate (south), brake (east), item/repair (west/north, preset-configurable)
- Left bumper: look behind (minimap mirrors in rear-view)
- Select: cycle 4 minimap modes

Full mapping: `docs/game-design/controls/controls-and-camera.md`

### Minimap (4 Modes)
1. Spline zoomed out — upcoming route only
2. Spline zoomed in — tighter approach view
3. Vertical position comparison — neck-and-neck relative positions
4. Screen-circling progress — spline flattened across screen edges, racer flags orbit with position numbers

Never shows terrain. Spline follows camera direction (always "up").

### Game Modes
| Mode | Description |
|---|---|
| **Campaign / Tournament** | Story-driven circuit progression through Elythia's nations |
| **Single Race** | Quick race on any unlocked track with any unlocked racer |
| **Time Attack** | Race against the clock, best lap/race per racer per track |
| **Mercenary Race** | Random race, random track, random opponents — paid by performance |
| **Archon Race** | Roguelike: permadeath, elimination format, escalating hazards, massive rewards |
| **Multiplayer** | Splitscreen (2–4), LAN, P2P online. AI fills up to 16 racers |

### Track Design
- **Modular chunks** — reusable segments stitched into multiple courses per biome
- **Dynamic assembly** — chunks combined at runtime for randomized layouts (Archon Races)
- **Systemic hazards** — fire vents, freezing water, pop-up traps, moving doors, destructible walls, wildlife, dragons, pirates, dock cranes
- **Elemental Imbalance** — Mario Galaxy prankster-comet style: remixes a track with a different element's hazards, visuals, and shortcuts
- Underwater sections, temperature zones, skill-based shortcuts, branching paths

Full hazard catalog: `docs/game-design/tracks/hazards.md`

### Economy
- **Losallian Crowns** — general currency for parts, repairs, upgrades
- **Elemental Cores** — from Archon Races, spent on elemental mods at nation shops
- **Race Winnings** — scaled by difficulty selection (harder AI = bigger payout)
- **Junkyard Flipping** — buy damaged high-tier parts cheap, race to repair, resell
- **Explicit Selling** — sell any owned part for market value (no trade-in target needed)
- **Difficulty/Payout Slider** — unified control over AI strength and prize reward

Full economy: `docs/game-design/economy/overview.md`

### Progression
- **License Rank** — accumulate points from placements (wins = most, top-half = some, bottom = none)
- Gates track access, part tiers, and max winnings
- NOT tied to race count — skilled players rank up faster

### AI
- Randomized component loadouts within quality range per difficulty tier
- Spline-based path sampling with lookahead distance
- Boost timing, braking aggression, and path choice vary by difficulty

---

## Technical Architecture

The full system map spans 23 modules across 5 implementation phases:

| Phase | Focus |
|---|---|
| 1 | Core Racing — spline system, input buffer, pod physics, hover system, boost/heat |
| 2 | Race Logic — race manager, lap detection, HUD, minimap, starting grid |
| 3 | Content/Economy — component system, shops, junkyard, pit droids, AI racers |
| 4 | Menus/Modes — garage UI, tournament progression, Archon Race mode |
| 5 | Multiplayer — state sync, lobby, P2P networking |

Technical docs: `docs/technical/`
Architecture plan: `docs/technical/architecture-plan.md`

---

## Doc Structure

| Folder | Contents |
|---|---|
| `docs/game-design/` | Design intent — mechanics, world, characters, tracks, economy, abilities |
| `docs/technical/` | Implementation reference — architecture, physics, hover, handling, collision |
| `docs/decisions/` | ADRs — why choices were made |
| `docs/agent-context/` | Working memory for AI agents working in this repo |
| `docs/pod-racer-notes/` | EP1R reference data — stats, components, junkyard strategy |

Start at `docs/agent-context/context-map.md` for task-specific reading paths.

---

## Scope Targets (Launch)

- **Tracks:** ~25+ courses across 10+ biomes
- **Racers:** ~33–35 (18 nation racers + 12 Archons + 3–5 secret)
- **Single-player length:** ~15–20 hours campaign
- **Multiplayer:** Splitscreen (2–4), LAN, P2P online (post-launch)
