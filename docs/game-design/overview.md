# ArcwingRacers — Game Design Overview

## Project Identity

**Title:** ArcwingRacers
**World / Setting:** Elythia
**Genre:** High-speed low-poly 3D fantasy racing game
**Engine:** Godot 4 (GDScript)
**Target Platforms:** Windows (console ports TBD)
**Primary Reference:** Star Wars Episode I: Racer

---

## Concept

ArcwingRacers is a high-speed racing game set on the planet Elythia — a world of 12 elemental nations, elemental gods, and magical technology. Players pilot "Arcwings," magical hovercraft with detached floating arcane engines, across diverse biomes in tournament racing.

The core game feel targets the physics, boost mechanics, and risk-reward loop of Star Wars Episode I: Racer. On top of that baseline, ArcwingRacers adds:
- **Elemental characters** — Each racer has a unique active ability on cooldown
- **Modular pod parts** — 7 upgrade slots with tiered components, junkyard economy
- **Roguelike Archon Races** — Unlockable hardcore mode with permadeath and escalating difficulty

---

## Core Design Pillars

- **EP1R feel first.** The physics, boost/heat system, and air control must match the reference game. Everything else builds on this foundation.
- **Roster as identity.** 30+ racers from 9 nations + 12 Archons + secret characters — each with fixed stats that make them handle uniquely. Two identically-equipped pods drive differently.
- **Modular tracks.** 10+ biomes with reusable chunk segments stitched into multiple courses per biome. Branching paths and intentional shortcuts are part of track design.
- **Multiplayer from day one.** Same code path for single-player, splitscreen, LAN, and eventual P2P online. AI fills any empty slots up to 16 racers.
- **Economy as progression.** Winnings, junkyard trading, part repair, and license rank gate content and create the single-player loop.
- **UI reads only.** All UI communication routes through the EventBus at `systems/events/event_bus.gd`. UI never calls into systems.

---

## Game Modes

| Mode | Description | Players |
|---|---|---|
| Campaign / Tournament | Story-driven circuit progression through the nations of Elythia. Earn money, unlock parts, increase license rank. | 1 player + AI |
| Single Race | Quick race on any unlocked track with any unlocked racer. | 1–4 local + AI |
| Time Attack | Race against the clock. Best lap and best race time recorded per racer per track. | 1 player |
| Mercenary Race | Random race on a random track with random opponents. Paid based on performance. | 1 player + AI |
| Archon Race | Roguelike mode: choose an Archon, race through a region's tracks. Permadeath — one crash ends the run. Elimination races, elemental imbalances, escalating rewards. | 1 player |
| Multiplayer (Local/LAN/Online) | Custom lobbies, up to 16 racers, mix of human and AI players. | 1–16 |

---

## Scope Targets (Launch)

- **Tracks:** ~25+ courses across 10+ biomes (modular stitching)
- **Racers:** ~33–35 (18 nation racers + 12 Archons + 3–5 secret)
- **Single-player length:** ~15–20 hours campaign
- **Multiplayer:** Splitscreen (2–4), LAN, P2P online (post-launch)
