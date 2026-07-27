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
| `superpowers/` | Archived features, specs, and plans (legacy — previous project) | Reference only |

---

## Start Here by Task

**Implementing a track, vehicle, or gameplay system (any Godot/GDScript code)**
→ Read `technical/code-standards.md` first. Then read the relevant `game-design/` doc for the system's intent.

**Adding or modifying racer/pod behavior**
→ Read `game-design/gameplay/movement.md`, then `technical/state-machines.md` for the AI/behavior architecture pattern.

**Adding a new character or elemental ability**
→ Read `game-design/gameplay/abilities.md` and `game-design/gameplay/player-characters.md`.

**Building a new track or world area**
→ Read the relevant world location doc under `game-design/world/`, then `technical/collisions.md` and `technical/tilemaps.md` (if applicable).

**Implementing or modifying UI (speed gauge, health, HUD)**
→ Read `technical/ui-events.md` and `technical/singleton-controllers.md`.

**Modifying a game system (saving, audio, dialog, etc.)**
→ Read the matching file in `systems/`, then check `technical/game-events.md` for integration patterns.

**Making an architectural decision**
→ Read existing ADRs in `decisions/adrs/` before proposing anything new.

**Importing or sourcing any audio asset**
→ Read `technical/audio-licensing.md` — every non-original audio file needs a license-traceability entry.

**Filing a new idea, question, or TODO**
→ Drop it in `unfiled-ideas.md`. Periodically, ideas are promoted into the relevant design docs.

**Delivering Godot scenes, resources, or editor integration steps**
→ Read `agent-context/workflows/godot-editor-workflow.md`.

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
| Pit / Junkyard | Economy system — repair pod parts, trade used parts, buy/sell upgrades |
| Mercenary Race | Drop into a random race on a random track for pay based on performance |
| Four-pillar architecture | `addons/` / `systems/` / `ui` / `content/` with strict one-way dependency flow; UI reads from systems via EventBus signals |
| Ep 1 Racer | Star Wars Episode I: Racer — primary reference for physics, boost, and track design |
| Low-poly | Art style — simple textures, clean 3D models, immersive UI |

---

## Doc Status

> Update this table whenever a doc's status changes.

| Doc | Status |
|---|---|
| `game-design/overview.md` | 🔴 Legacy (Fantasy X 2D action-RPG) — needs rewrite for ArcwingRacers |
| `game-design/gameplay/movement.md` | 🔴 Legacy (platformer movement) — needs rewrite for racing physics |
| `game-design/gameplay/abilities.md` | 🔴 Legacy (combat orbs) — needs rewrite for elemental racing abilities |
| `game-design/gameplay/player-characters.md` | 🔴 Legacy (Kael/Rina) — needs rewrite for Arcwing racers |
| `game-design/gameplay/enemies/` | 🔴 Legacy — needs replacement with racer AI / opponents |
| `game-design/world/` | 🔴 Legacy (Zelda-like locations) — needs replacement with racetracks and biomes |
| `game-design/art-direction/` | 🔴 Legacy (2D pixel art) — needs rewrite for 3D low-poly |
| `game-design/audio-direction/` | 🔴 Legacy — needs rewrite for racing audio |
| `game-design/hud/` | 🔴 Legacy — needs rewrite for racing HUD (speed gauge, health) |
| `game-design/menu-scenes/` | 🟡 Partial — potentially adaptable |
| `systems/` | 🔴 Mostly legacy — needs rewrite for racing systems |
| `technical/` | ✅ Godot 4 specific — may need auditing for 3D vs 2D differences |
| `decisions/adrs/` | 🔴 No ADRs recorded for ArcwingRacers yet |
| `agent-context/workflows/godot-editor-workflow.md` | ✅ Substantive |
| `superpowers/` | 🗑️ Legacy (previous project content) |

---

## Conventions

- The `docs/` folder holds design intent, architecture decisions, and working memory. Source of truth for project-specific decisions.
- When a design decision is made in conversation, it lands in the relevant `game-design/` doc.
- `unfiled-ideas.md` is the inbox. Clear it periodically into the appropriate docs.
- All `[TBD]` tags are intentional. Do not fill them in — surface them.
- Doc filenames use `kebab-case`.
- Code follows the four-pillar folder architecture: `addons/` (libraries), `systems/` (core mechanics), `ui/` (read-only displays), `content/` (assets, scenes, level scripts).
- UI ↔ gameplay communication routes through signals or EventBus autoload only: UI reads by subscribing, writes by firing event requests.
