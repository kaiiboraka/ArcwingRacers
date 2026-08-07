# Context Map

> Start here. This file tells you what exists in this repo and where to look before you begin any task.

## What This Project Is

**ArcwingRacers** is a **high-speed low-poly 3D fantasy racing game** set on the planet **Elythia**. Players pilot magical hovercraft called "Arcwings" — chariot-like pods with detached floating arcane engines — across diverse biomes in tournament racing. The game blends the physics and feel of Star Wars Episode I: Racer with elemental character abilities, modular pod part customization, and roguelike Archon Race mode.

The game world, lore, and characters are shared with the broader Elythia fantasy setting (see `game-design/overview.md`). This project reimagines Elythia as a racing game: the elemental nations, Archons, and magic system that were combat mechanics in the previous 2D action-RPG are now expressed through racer abilities, track hazards, and pod mods.

Built on **Godot 4** (GDScript). 3D. See `technical/code-standards.md` for the pinned version and API guidance.

---

## **Source Locations**

- Godot project: `C:\Projects\ArcwingRacers`
- Docs: `docs/` within this repository
- Obsidian Vault (previous Elythia world-building): machine-specific, see `docs/game-design/overview.md` for context

---

## Doc Structure

| Folder | Contains | Use it when… |
|---|---|---|
| `game-design/` | What the game is — mechanics, world, characters, tracks, art, audio | You need to understand intent, scope, or design goals |
| `systems/` | How game systems work — runtime behavior, rules, data flow | You're implementing or modifying a named system |
| `technical/` | How the software works — architecture, patterns, Godot specifics | You need a structural or implementation reference |
| `decisions/` | Why choices were made — ADRs, tradeoffs | You're questioning an existing approach or proposing a change |
| `marketing/` | Go-to-market strategy — audience, positioning, launch | You're working on store listing, launch, or growth tasks |
| `agent-context/` | How agents should work in this repo | You're an AI agent (you're here now) |
| `agent-context/plans/` | Working plan documents — agreed multi-step plans (`plan-<topic>.md`) written before execution | You're starting an agreed multi-step task and need the active plan |
| `superpowers/` | Archived features, specs, and plans (legacy — previous project) | Reference only |

---

## Start Here by Task

**Implementing a track, vehicle, or gameplay system (any Godot/GDScript code)**
→ Read `technical/code-standards.md` first. Then read the relevant `game-design/` doc for the system's intent.

**Adding or modifying racer/pod behavior**
→ Read `game-design/pod-stats.md` for the stat model, `game-design/boost-and-heat.md` for the boost/heat system, `game-design/mana-and-shield.md` for mana/shield, then the pod technical docs (`pod-scene-hierarchy.md`, `pod-hover-system.md`, `pod-handling-and-boost.md`, `pod-collision-response.md`) for implementation reference.

**Adding a new racer character**
→ Read `game-design/racers.md` for roster structure, `game-design/pod-stats.md` for stat allocation, `game-design/abilities.md` for element/ability assignment.

**Building a new track**
→ Read `game-design/tracks/overview.md` for biome/chunk design, `game-design/tracks/track-layout.md` for spline layout and waypoint rules, `game-design/tracks/hazards.md` for hazard placement, `technical/tracks-and-splines.md` for the spline system implementation.

**Implementing or modifying the economy**
→ Read `game-design/economy/overview.md`, then `technical/architecture-plan.md` Phase 3 for system layout.

**Implementing or modifying UI (speed gauge, HUD, menus)**
→ Read `technical/architecture-plan.md` Phase 2 HUD section, `technical/ui-events.md` and `technical/singleton-controllers.md`, plus ADR 0002 (`decisions/adrs/0002-eventbus-ui-communication.md`).

**Implementing pod hover, handling, or collision**
→ Read `technical/pod-physics-and-collision.md` for collision model and layers, `technical/pod-hover-system.md` for spring-raycast model, `technical/pod-handling-and-boost.md` for acceleration/steering/boost/air control, `technical/pod-collision-response.md` for scrape/crash/damage/death spin.

**Implementing abilities or mana system**
→ Read `game-design/abilities.md` for ability types and element interactions, `game-design/mana-and-shield.md` for mana/shield mechanics, `technical/architecture-plan.md` for system layout.

**Implementing multiplayer**
→ Read `game-design/multiplayer.md` and ADR 0006 (`decisions/adrs/0006-multiplayer-architecture.md`), plus `technical/architecture-plan.md` Phase 5.

**Implementing AI racers**
→ Read `technical/architecture-plan.md` Phase 3 AI section, `technical/state-machines.md` for AI behavior pattern.

**Modifying a game system (saving, audio, etc.)**
→ Read the matching file in `systems/`, then check `technical/architecture-plan.md` for system boundaries.

**Making an architectural decision**
→ Read existing ADRs in `decisions/adrs/` before proposing anything new.

**Filing a new idea, question, or TODO**
→ Drop it in `unfiled-ideas.md`. Periodically, ideas are promoted into the appropriate design doc.

**Writing or checking an agreed multi-step plan (phases, roadmaps, task lists)**
→ Working plans live in `agent-context/plans/` (`plan-<topic>.md`). Agreed plans must be written there before execution starts; see `agent-rules.md`. Check it for any active plan before starting work. When work on a plan is committed to, its steps are mirrored into the active todo list prefixed with the plan's tag (e.g. `[LPDE]`).

**Delivering Godot scenes, resources, or editor integration steps**
→ Read `agent-context/workflows/godot-editor-workflow.md`.

**Setting up environment model physics (GLB import pipeline)**
→ Read ADR 0009 (`decisions/adrs/0009-environment-modeling-pipeline.md`). Each .glb's import settings configure per-mesh collision generation — no wrapper scenes, no scripts.

---

## Key Vocabulary

| Term | Meaning |
|---|---|
| Arcwing | The whole pod: chariot-like cockpit ("Blade") + detached arcane engines ("Wings") lashed by pink energy beams |
| Blade | The cockpit/chariot body; about the size of an ATV, shaped like a reverse Naboo Starfighter |
| Wings | The detached floating engines; solar-sail-like energy cells on magical machinery |
| Arc-rig | The cross beams connecting Blade to Wings via arcane energy |
| Blade Rider / Arc Rider | The pilot |
| Racer Position | A Marker3D slot in the starting grid (Position_01–Position_16, 4×4 grid anchored at origin) |
| Starting Line | The `Content/Scenes/starting_line.tscn` scene; auto-generates grid positions via @tool script |
| Pod | The player's Arcwing vehicle; modular with upgradeable parts |
| Elemental Ability | A weapon/ability slot on each character (instead of just Sebulba having one) |
| Elythia | The planet; 12 elemental nations, each with a patron deity and month |
| Archon | A living mortal vessel of a deity's elemental power; exists in this setting but role differs per mode |
| Archon Race | Roguelike mode — choose an Archon, race through a region's tracks with escalating difficulty and rewards |
| Elemental Imbalance | Track modifier akin to Mario Galaxy's prankster comets — remixes a level with different elemental hazards |
| Boost | Core mechanic copied from Ep 1 Racer: over-abuse causes overheating/fire |
| Racer License | Player progression system; license rank determines available races and rewards |
| Losallian Crowns | Primary currency — part purchases, repairs, upgrades |
| Elemental Cores | Tertiary currency from Archon Races, spent on elemental mods |
| Part Warehouse | Store parts indefinitely without degradation; no forced carry limit |
| Pit / Junkyard | Economy system — repair pod parts, trade used parts, buy/sell upgrades |
| Explicit Selling | Divergence from EP1R: sell any owned part for current market value (no trade-in target needed) |
| Mercenary Race | Drop into a random race on a random track for pay based on performance |
| Mana | Resource for abilities and shield. Recharges slowly; pickups on track; dropped by hit racers |
| Shield | Directional block (front/back/left/right); hold drains mana, time to parry restores mana |
| Parry | Timed shield raise just before impact — restores mana instead of consuming it |
| Elemental Ability | Weapon type × element plug-and-play system; every racer has at least one |
| Elemental Interaction | Cross-element effects (water washes ice, fire melts ice, wind blows water, etc.) |
| Four-pillar architecture | `addons/` / `systems/` / `ui` / `content/` with strict one-way dependency flow; UI reads from systems via EventBus signals at `systems/events/event_bus.gd` |
| Ep 1 Racer | Star Wars Episode I: Racer — primary reference for physics, boost, and track design |
| Low-poly | Art style — simple textures, clean 3D models, immersive UI |

---

## Doc Status

> Update this table whenever a doc's status changes.

| Doc | Status |
|---|---|
| `README.md` | ✅ Written — formal design overview with feature list, divergences, scope targets |
| `brainstorm_GDD.md` | 🟡 Original concept / first brainstorm — raw ideas, early ability drafts, terminology noodling, concept art prompts. Preserved from the first README. Refer back when you want "what we first said about this." |
| `game-design/overview.md` | ✅ Written — ArcwingRacers racing game design |
| `game-design/differences-from-ep1r.md` | ✅ Written — all intentional divergences from EP1R |
| `game-design/pod-racer-notes/ep1r-advanced-players-reference-FAQ.md` | 🟡 Reference — full EP1R player guide, racer stats, component data (1700 lines) |
| `game-design/racers.md` | ✅ Written — roster composition, 33–35 racers |
| `game-design/pod-stats.md` | ✅ Written — 15 attributes, 7 upgradable, 8 fixed, component tiers, damage/health |
| `game-design/boost-and-heat.md` | ✅ Written — EP1R boost/heat system |
| `game-design/economy/overview.md` | ✅ Written — winnings, junkyard, pit droids, license progression |
| `game-design/tracks/overview.md` | ✅ Written — 10+ biomes, modular chunk stitching, tournaments |
| `game-design/controls/controls-and-camera.md` | ✅ Written — KB+M + gamepad, 4 camera views, shield/parry, repair, 4 minimap modes, look-behind |
| `game-design/mana-and-shield.md` | ✅ Written — mana pool, pickups, shield + parry mechanics |
| `game-design/abilities.md` | ✅ Written — elemental abilities brainstorm, element interactions |
| `game-design/tracks/hazards.md` | ✅ Written — full hazard catalog with categories and design principles |
| `game-design/multiplayer.md` | ✅ Written — splitscreen, LAN, P2P architecture |
| `game-design/pod-racer-notes/` | 🟡 Reference — EP1R stat data, junkyard strategy, best parts guide, pit droid mechanics |
| `game-design/tracks/track-layout.md` | ✅ Written — design intent: cyclic/non-cyclic, branching, waypoint gating, AI pathing, modular chunks |
| `technical/tracks-and-splines.md` | ✅ Written — implementation reference: `Spline extends Curve3D` + per-point metadata, recipe-driven mesh generation, traversal, AI sampling math, minimap rendering (see ADR 0010); track-editor dock (Phase 2 part 2) complete, only Phase 3 mesh generation remains (cursory plan + uncertainties in `agent-context/plans/plan-mesh-generation.md`) |
| `technical/architecture-plan.md` | ✅ Written — full system map, 23 modules across 5 phases, implementation order |
| `technical/pod-physics-and-collision.md` | ✅ Written — capsule collision, layers, CCD strategy |
| `technical/pod-scene-hierarchy.md` | ✅ Written — single CharacterBody3D, 7 capsules, spring-offset visuals |
| `technical/pod-hover-system.md` | ✅ Written — 4 spring-raycast corners, damped Hooke's law, banking TBD |
| `technical/pod-handling-and-boost.md` | ✅ Written — acceleration catch-up model, boost, air control (gravity modulation), steering (yaw + traction + max_turn_rate/turn_response split) |
| `technical/pod-collision-response.md` | ✅ Written — scrape vs crash, pod-on-pod damage, one-shot destruction, death spin |
| `technical/next-technical-breakdowns.md` | 📋 Planned — 10 subjects queued for next session |
| `technical/model-and-level-setup.md` | ✅ Written — model/level import-setup checklist (per-import-scene, per-MeshInstance3D, per-mesh, per-material settings, level prerequisites, LightmapGI baking). Companion to ADR 0009 |
| `technical/texture2d-import-settings.md` | ✅ Written — Texture2D compression mode: VRAM Compressed (BC6H) for 3D/lightmap/HDR `.exr`, Lossy only for UI/rare 2D |
| `decisions/adrs/` | ✅ 10 ADRs recorded (0001–0010) |
| `agent-context/` | ✅ All files updated for ArcwingRacers |
| Legacy Fantasy X docs | 🗑️ Legacy — keep for reference until replaced |

---

## Conventions

- The `docs/` folder holds design intent, architecture decisions, and working memory. Source of truth for project-specific decisions.
- When a design decision is made in conversation, it lands in the relevant `game-design/` doc.
- `unfiled-ideas.md` is the inbox. Clear it periodically into the appropriate docs.
- All `[TBD]` tags are intentional. Do not fill them in — surface them.
- Doc filenames use `kebab-case`.
- Code follows the four-pillar folder architecture: `addons/` (libraries), `systems/` (core mechanics), `ui/` (read-only displays), `content/` (assets, scenes, level scripts).
- UI ↔ gameplay communication routes through signals or EventBus autoload at `systems/events/event_bus.gd` only: UI reads by subscribing, writes by firing event requests.
