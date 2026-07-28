# ADR 0001: Four-Pillar Folder Architecture

## Status
Accepted

## Context
ArcwingRacers is expected to run for a year or more of development. Solo/small teams don't need CI-enforced structural checks, but a clear folder convention is worth establishing early to prevent entropy as the codebase grows. Without a standard, scripts and scenes scatter across the project root, dependencies become tangled, and UI code inevitably writes directly to game systems.

GDQuest's writeup of Epictellers' (Starfinder: Afterlight) four-pillar architecture provides a proven model: `addons/`, `systems/`, `ui/`, `content/` with strict one-way dependency flow.

## Decision
Adopt the four-pillar structure with these boundaries:

| Pillar | Purpose | Dependencies |
|---|---|---|
| `addons/` | Reusable libraries and tools that work in any 3D game | None (self-contained) |
| `systems/` | Core game rules and mechanics (race logic, physics, economy, AI) | `addons/` only |
| `ui/` | User interface code — reads from systems, never writes | `systems/` (read-only via EventBus signals) |
| `content/` | Game assets, scenes, track geometry, racer definitions, level scripts | `systems/` and `addons/` |

The dependency rule: `content/` → `systems/` → `addons/`. No reverse dependencies. `ui/` reads from `systems/` via signals only — it never calls into systems directly.

## Consequences
- **Positive:** Clear ownership of code. New contributors (including AI agents) can locate the right folder by task type.
- **Positive:** `ui/` can be swapped or iterated without touching game logic.
- **Positive:** `Content/Scripts/` holds level-specific tool scripts like the starting grid generator.
- **Tradeoff:** Requires discipline on signal-based UI reads. The EventBus at `systems/events/event_bus.gd` (see ADR 0002) is the enforcement mechanism.
