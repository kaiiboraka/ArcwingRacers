# Technical Architecture Plan

## Overview

This document maps every system needed for ArcwingRacers, its responsibilities, data flow, and recommended implementation phase. The goal is to define what we'll build and in what order before writing a single `.gd` file.

---

## Phase 1 — Core Racing Foundation

### 1. Spline System
**Where:** `systems/track/spline.gd` (Resource subclass)
**Dependencies:** None

A `Spline` Resource that stores a 3D catmull-rom or bezier curve as an array of control points. Provides:
- `sample(t: float) → Vector3` — position along the spline
- `sample_vector(t: float) → Vector3` — direction at that point
- `project(point: Vector3) → float` — nearest t-value for any world position
- `total_length() → float`
- Support for multiple paths (main + branches) in one resource

Spline data is authored as `.tres` files in `Content/Tracks/`.

### 2. Pod Physics
**Where:** `systems/vehicles/pod_controller.gd` (Node, attached to the pod scene)
**Dependencies:** Spline System (for AI), Input Buffer

The core vehicle movement. Must match EP1R feel:
- Hover: pod floats at `hover_height` above ground, with suspension damping
- Throttle: acceleration curve, max speed cap, boost modifier
- Steering: turn rate clamped by `max_turn_rate`, response smoothed by `turn_response`
- Pitch: nose down for boost charge, nose up for air control; pitch affects turning radius during air time
- Airbrakes: left/right yaw rotation, deceleration on brake input
- Drag: deceleration inverse for coasting behavior
- Gravity: when airborne, gentle gravity with hover re-engagement on ground proximity
- Collision response: bump mass, damage calculation, deflection

Input is read from an **Input Buffer** (not directly from `Input`). This is the slot abstraction that enables multiplayer later.

### 3. Camera System
**Where:** `systems/camera/race_camera.gd`
**Dependencies:** Pod Physics (to follow)

4 chase views (far/med/close + first person) + speed-based look-ahead. Camera position smoothed with spring interpolation. Wall occlusion handled via transparency or spring-in. View cycled with a button press, saved per-player.

### 4. Input Buffer
**Where:** `systems/input/input_buffer.gd`
**Dependencies:** None

A per-slot buffer that decouples input sources from the simulation:
- Local input (keyboard/gamepad) writes to buffer each frame
- AI decision system writes to buffer (see Phase 3)
- Network packets deserialize into buffer (see Phase 5)
- Pod physics reads from buffer

This is the single abstraction that makes multiplayer "free."

### 5. Track Scene
**Where:** `Content/Tracks/<name>/<name>.tscn`
**Dependencies:** Spline System (spline resource), Starting Grid (Phase 2)

A track scene contains:
- A `Track` root node that references its `Spline` resource
- Visual geometry (mesh, collision, environment)
- Starting grid scene instance
- Spawn/waypoint/respawn references

---

## Phase 2 — Race Logic

### 6. Race Manager
**Where:** `systems/race/race_manager.gd` (autoload or scene-level Node)
**Dependencies:** EventBus, Input Buffers, Spline, Pod Physics, Starting Grid

State machine: `PREGAME → COUNTDOWN → RACING → FINISHED → RESULTS`

Pre-game: place racers on grid positions, assign input slots, initialize timers.
Countdown: 3-2-1-GO audio/visual cue, then release controls.
Racing: per-frame update loop — tick physics, tick AI, check lap/position, check crashes.
Finished: trigger results when all racers finish or time-out.

Fires EventBus signals for state transitions, lap completions, crashes, finishes.

### 7. Lap & Position Tracking
**Where:** `systems/race/lap_tracker.gd`
**Dependencies:** Spline System

Tracks each racer's progress through the spline:
- Each racer has a `spline_t` (their nearest projected position on the main spline) + `lap_count`
- **Waypoint gating:** Waypoints are defined at strategic spline `t` values (before splits, after merges, at start/finish). Each racer has a `next_waypoint_index`. Clearing a waypoint = crossing its `t` threshold while moving forward. Branching paths that skip waypoints are valid — next waypoint advances when the racer's `t` passes it.
- Lap increment: lap increases when `spline_t` wraps past 0 (start/finish) and all previous waypoints in that loop have been cleared.
- Position ranking: sort racers by (lap_count, spline_t) descending.

### 8. Boost & Heat System
**Where:** `systems/vehicles/boost_system.gd`
**Dependencies:** Pod Physics, EventBus

The EP1R mechanic as described in ADR 0004:
- Nose-down near max speed → charge boost gauge
- Activate → flat speed addition, accelerate to boost max speed
- Heat rises at `heat_rate` during boost
- Overheat → boost ends, wing fire, must cool fully before re-boosting
- Cools at `cool_rate` after boost ends

Emits `boost_activated`, `boost_overheat`, `boost_charge`, `heat_changed` on EventBus for UI.

### 9. Collision System
**Where:** `systems/physics/collision_handler.gd`
**Dependencies:** Pod Physics, EventBus

Handles:
- Pod↔track: wall collision → deflection + damage
- Pod↔pod: bump mass calculation → both deflected, damage based on `damage_immunity`
- Pod↔obstacle: track hazards (geysers, lava, etc.) → damage + effect

Emits `collision_occurred` on EventBus for damage system and audio.

### 10. Damage System
**Where:** `systems/vehicles/damage_system.gd`
**Dependencies:** Component System, EventBus

EP1R style: 2 engines × 3 sections (front/middle/back) = 6 health segments. Each segment corresponds to a component slot:
- Front left / Front right — air brake (or fixed by which part occupies that slot)
- Middle left / Middle right — acceleration/turning (TBD mapping)
- Back left / Back right — cooling/repair (TBD mapping)

Each segment has `max_hp` and `current_hp`. Collision damage is allocated to the hit region. Component stat bonus scales with segment health (`bonus * (hp / max_hp)`). When HP reaches 0, the component provides no bonus.

Between races, assigned pit droids restore segment HP. See Phase 3.

Emits `damage_taken`, `component_destroyed` on EventBus.

### 11. Race HUD
**Where:** `ui/race/hud.tscn` + `ui/race/hud.gd`
**Dependencies:** EventBus (reads only)

Reads from EventBus signals and displays:
- Speed gauge (analog dial or digital)
- Lap counter / total laps
- Race timer (elapsed or countdown)
- Position display (current standing)
- Boost charge gauge
- Heat gauge (color gradient green→yellow→red)
- Damage display (2 columns × 3 rows of icons, green→yellow→red→flashing dark red)
- Engine fire overlay when overheating
- Minimap (TBD)

---

## Phase 3 — Content & Economy

### 12. Racer Data
**Where:** `systems/vehicles/racer_data.gd` (Resource subclass)
**Dependencies:** None

A `RacerData` Resource holding:
- Display name, portrait path, icon path, model path
- Base stats: 15 attributes (8 fixed + 7 base values for upgradable stats)
- Physical factors: width, cable length, binder length (floats)
- Active ability definition (name, cooldown, effect — see Phase 4)
- Records dict: `{track_id: {best_race_time, best_lap_time}}`

Stored as `.tres` files in `Content/Racers/`.

### 13. Component System
**Where:** `systems/vehicles/component.gd` (Resource subclass)
**Dependencies:** None

A `Component` Resource:
- Slot type (enum: TRACTION, TURNING, ACCELERATION, TOP_SPEED, AIR_BRAKE, COOLING, REPAIR)
- Tier (1–6)
- Stat modifier value (additive or multiplicative, per stat model)
- Base cost
- Current HP / max HP

Stored as `.tres` files. A racer's loadout is a dictionary of `{slot_type: Component}`.

### 14. Economy System
**Where:** `systems/economy/`
**Dependencies:** Component System, Race Manager (for winnings)

Sub-systems:
- **Currency Manager** — tracks player's balances (Losallian Crowns, Elemental Cores), handles all transaction types (purchase, sale, trade-in, repair, betting escrow)
- **Shop Manager** — generates available parts per nation with native-element specialization, trade-in subtraction math (new price - current part value)
- **Junkyard Manager** — generates used/random damaged parts from a weighted pool (any tier, even locked ones), randomizes condition %, handles inventory refresh on exit
- **Part Warehouse** — stores owned parts not currently equipped; stored parts don't degrade
- **Pit Droid Manager** — tracks owned pit droids (1–4), assignment to component slots, repair tick between races (only repairs on first-time race completions; assigned droids prevent damage AND repair)
- **License Manager** — tracks license rank, conditions for promotion (license points from placements, not race-count)
- **Mercenary Manager** — generates random race offers (random track, random AI opponents with randomized loadouts), pays Crowns based on performance vs expectations
- **Difficulty & Payout** — unified slider controlling both AI opponent strength and prize payout (replaces EP1R's Fair/Skilled/WTA)

### 15. AI Racer
**Where:** `systems/ai/racer_ai.gd`
**Dependencies:** Spline System, Pod Physics, Input Buffer

AI writes to the same Input Buffer as human players:
- Samples target position from spline at lookahead distance
- Steers toward target, accelerates/brakes based on upcoming curvature
- Boost decision: use boost on straights and long sections, avoid in tight turns
- Path selection: on branching paths, compare total remaining distance
- Difficulty variance: lookahead distance, braking aggression, boost timing, path choice quality — not raw speed
- Loadout variance: AI racers get randomized component loadouts within a quality range for their difficulty tier

---

## Phase 4 — Menus & Modes

### 16. Race Results
**Where:** `ui/results/`
**Dependencies:** EventBus (reads race results)

Finish order, lap times, best lap, winnings earned, component damage summary. "Next" button advances to garage or track select.

### 17. Garage / Upgrades UI
**Where:** `ui/garage/`
**Dependencies:** Economy System, Component System

- View current loadout with all 7 slots
- Buy new parts from shop (with trade-in subtraction)
- Browse junkyard for used parts (with inventory refresh on exit)
- Assign pit droids to slots
- Repair parts (costs money, speed affected by repair rate)
- Part warehouse (view, store, retrieve, sell directly)
- Explicit sell (any owned part for current market value)
- Trade in parts

### 18. Menu Flow
**Where:** `ui/menus/`
**Dependencies:** Economy System, Racer Data

- Main menu → campaign / single race / time attack / multiplayer / archon race
- Racer select → choose racer + view stats
- Track select → choose track from unlocked set
- Tournament map → progression view of tournament races

### 19. Tournament Progression
**Where:** `systems/economy/license_manager.gd` (expanded)
**Dependencies:** Race Manager, Economy System

Organizes races into circuits with unlock conditions. Tracks which races are completed, 1st-place status, license rank gates new circuits. Completed races with 1st place stop accumulating component damage.

### 20. Archon Race Mode
**Where:** `systems/modes/archon_race_manager.gd`
**Dependencies:** Race Manager, Economy System, AI

Roguelike mode:
- Choose one Archon character (unlockable)
- Race through a region: elimination format (last place or crash = eliminated)
- Between races: choose from 3 upgrade paths (stronger than normal component progression)
- Run ends when: your racer is eliminated, or you win the region (all others eliminated)
- High risk/reward: permadeath, but massive payout scaling
- Elemental Imbalance occurs more frequently

---

## Phase 5 — Multiplayer

### 21. Slot System (already designed in Phase 1 Input Buffer)
Already handled by the input buffer abstraction. Phase 5 adds the network transport layer.

### 22. Splitscreen
**Where:** `systems/multiplayer/splitscreen_manager.gd`
**Dependencies:** Input Buffer, Camera System

Creates multiple viewports (ViewportContainer in a Control), assigns one camera per local player. Each local player's input writes to their slot's buffer.

### 23. Network Sync (LAN → P2P)
**Where:** `systems/multiplayer/network_manager.gd`
**Dependencies:** Race Manager, Input Buffer

Host-authoritative model:
- Host runs the Race Manager
- Remote peers send input packets
- Host broadcasts state snapshots (positions, lap, heat, damage)
- ENet or WebRTC transport, no official servers

---

## Implementation Order

```
Phase 1: Spline → Input Buffer → Pod Physics → Camera → Test Track
     ↓
Phase 2: Race Manager → Lap/Position → Boost/Heat → Collision → Damage → HUD
     ↓
Phase 3: Racer Data → Component System → Economy → AI
     ↓
Phase 4: Results → Garage → Menus → Tournaments → Archon Races
     ↓
Phase 5: Splitscreen → LAN → Online P2P
```

## Open Design Questions (Flagged)

- **Ability resource system:** Some racer abilities may use a mana/energy meter filled by track pickups (Mario Kart coins style). Unresolved — flagged for later design.
- **Ability cooldowns:** Upper single digits to low teens, exact values TBD per ability.
- **Archon Race length:** "Win when all others eliminated." Unclear if a region has a fixed number of races or continues until one racer remains. Flagged.
- **Damage-to-component mapping:** Which physical region maps to which component slot. EP1R's exact mapping is unknown — will define during implementation.
