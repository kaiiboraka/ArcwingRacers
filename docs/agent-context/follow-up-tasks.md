# Follow-Up Tasks

Tasks explicitly deferred to a later session — not urgent, not forgotten. Remove an item once it's done and note where the resulting changes landed.

---

## Deferred Tasks

- **Write `game-design/overview.md` for ArcwingRacers.** Currently contains Fantasy X 2D action-RPG design. Needs full rewrite describing the high-speed low-poly 3D racing game, its setting, core pillars, and scope targets.

- **Document starting grid system.** The `starting_line.gd` @tool script at `Content/Scripts/starting_line.gd` is the first authored system. Write a design doc for it (grid layout, racer positions, visibility, public API).

- **Write ADR for folder architecture.** The four-pillar split (addons/systems/ui/content) was adopted from the GDQuest Epictellers pattern. Record ADR 0001 documenting the decision, dependency rules, and accepted tradeoffs.

- **Replace legacy `game-design/` content.** All docs under `game-design/` currently describe Fantasy X (2D platformer combat). Rewrite or replace for ArcwingRacers: movement/racing physics, abilities, characters, tracks, art direction, audio.

- **Replace legacy `systems/` content.** Game-saving, dialog, and other systems from the previous project need rewriting for racing game systems (lap tracking, boost, heat, pod stats, economy).

- **Replace legacy `game-design/world/` content.** Location docs describe Zelda-like dungeon/town areas. Needs replacement with racetrack biomes and circuit layouts.

- **Replace legacy `game-design/gameplay/enemies/` content.** Enemy behavior docs for archers, soldiers, etc. need replacement with racer AI opponent design.

- **Audit `technical/` docs for 3D vs 2D correctness.** The technical docs were written for Godot 4 2D (tilemaps, collisions, animation). Review for 3D applicability and update where needed.

- **Populate `decisions/adrs/`.** No ADRs recorded for ArcwingRacers yet. Record decisions as they're made (folder architecture, grid system, boost mechanic, etc.).

- **Clear `unfiled-ideas.md`.** Currently empty. File new ideas into appropriate design docs as they come.
