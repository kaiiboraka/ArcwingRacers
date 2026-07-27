# ADR 0001: Demo3 Modular Architecture Migration

## Status
Proposed

## Context

Demo1 (Unity) validated core feasibility: Rina's controller and a data-driven magic element system. Demo2 (Godot 4 / C#) validated the engine switch, frame-based animation, and melee combat. Both demos are functionally successful but were built without enforced dependency boundaries between gameplay systems and UI — in several places UI code reads from and writes to gameplay state directly.

A sequel to Elythia 1 (Elythia 2) is a known, planned future requirement, not a speculative one. The project also currently maintains two disconnected knowledge stores — this `docs/` folder and the Obsidian Vault at `C:\_GameDevelopment\FantasyX_Obsidian\` — with a stated long-term goal of bringing them physically closer together.

Reference: GDQuest's writeup of Epictellers' (Starfinder: Afterlight) four-pillar architecture — `addons` / `systems` / `ui` / `content`, with a strict one-way dependency flow (content → systems → addons; ui → systems only, read-only) plus a per-developer sandbox folder excluded from builds. (https://www.gdquest.com/library/modular_game_architecture/)

The GDQuest piece's own sizing guidance: solo/small teams don't need the full Epictellers rigor (no CI-enforced structural checks), but adopting the basic four-folder split early is worth it for a project expected to run a year or more — which this project is. 

## Decision

Start a new repository ("Demo3") rather than reorganizing Demo2 in place. Existing Demo1/Demo2 systems (Rina's controller, magic element system, melee combat, animation system) are **ported and re-integrated** against the new dependency rules, not rebuilt from scratch. The refactor work is in re-plumbing violated boundaries (primarily gameplay ↔ UI coupling), not in re-deriving game logic already proven twice.

Rejected alternative: incremental reorg inside Demo2. Godot has no build-level folder constraints (unlike Unity assemblies), so a pure folder move would have been low-risk — but the actual goal isn't folder placement, it's enforcing the dependency direction. That requires touching the same hard-coupled callsites either way, and doing it inside Demo2's existing structure risks half-migrated code tempting a reversion to old habits. A clean landing zone removes that temptation.

### Repository Layout

```
repo root/
├── docs/               (agent-context, design, technical, decisions — this store)
├── Vault/              (Obsidian vault, renamed/relocated from FantasyX_Obsidian)
├── Game/               (Godot project root — project.godot lives here)
│   ├── addons/          (Godot-reserved plugin path: ldtk-importer, Maaacks,
│   │                     AND in-house game-agnostic utilities — see note below)
│   ├── systems/         (game rules: combat, magic, state machines, saving)
│   ├── ui/              (reads systems via EventBus only; never mutates state)
│   ├── content/         (levels, dialogue, character-specific data, quests)
│   └── sandbox/         (per-dev prototyping, excluded from exports)
```

`docs/` and `Vault/` sit outside the `Game/` tree entirely, so Godot's asset importer never scans them — no `.gdignore` needed for this reason (only needed if non-code content ever lands inside `Game/` unintentionally).

**Naming note on `addons/`:** Godot reserves `res://addons/` specifically for its editor plugin system (anything with a `plugin.cfg` — `ldtk-importer`, Maaacks). The Epictellers "addons" *pillar* (reusable, engine-only, game-agnostic in-house code) is a different concept that happens to share the name. Per your preference, both live in the same physical `addons/` folder rather than splitting into a separate `utils`/`core` folder — acceptable as long as in-house utility code follows the same addon-independence rule (an addon may talk to the engine, never to another addon or to `systems/`).

`sandbox` replaces the article's "gyms" naming, same function: unstructured per-developer prototyping, git-tracked, excluded from build exports.

### UI Boundary Rule

`ui/` never calls into `systems/` directly. All UI ↔ gameplay communication routes through the existing Tier 2 EventBus Autoload: 
- UI **reads** gameplay state by subscribing to EventBus broadcasts.
- UI **writes** (player input intended to change gameplay state) by firing a request/command through the EventBus; the owning system performs the mutation.

This is the same open question already tracked as a paused audit on `technical/ui-events.md` ("where UI event wiring belongs in the 3-tier event system"). Resolving that design question is a prerequisite for this migration, not a parallel task — it defines the interface every hard-coupled UI script gets ported against.

## Options Considered

**A. Reorganize Demo2 in place.** Rejected — see above; doesn't address the actual coupling problem, and risks a long half-migrated state.

**B. Full rebuild in a new repo.** Rejected — throws away validated gameplay logic (character controller, magic system, combat) for no architectural benefit; the dependency rules constrain *integration*, not the logic itself.

**C. Port + re-integrate in a new repo (chosen).** Existing logic carries over with targeted refactors at coupling points; new repo gives a clean enforcement baseline for the dependency rules from the first commit.

## Consequences

- Demo2 remains untouched and runnable as a working reference during the port.
- UI refactor work is real, not cosmetic — every direct gameplay→UI or UI→gameplay reference found during the port must be re-routed through the EventBus or equivalent. Full elimination of all coupling is not required on day one — see Open Questions.
- Establishes the four-pillar boundary as house style going forward, including for Elythia 2, which is the entire point of doing this now rather than later.
- `decisions/adrs/` in this repo (Demo2) is the current home for this record; once Demo3 exists, its `docs/decisions/adrs/` should carry this ADR forward (copied or referenced — see Open Questions).

## Open Questions (Unresolved — Not Yet Decided)

- **Repo/folder naming.** "Demo3" used as a placeholder throughout this ADR and in conversation. Final repo name, and final name for the `Game/` subfolder, not yet chosen.
- **Vault relocation mechanics.** Moving/renaming `FantasyX_Obsidian/` into a `Vault/` sibling folder — whether this is a straight move (preserving git history if the Vault is version-controlled) or a fresh copy, not yet decided.
- **Migration order.** Which system ports first (magic system was suggested as a pilot candidate for being self-contained and data-driven) — not committed to.
- **Full scope of UI coupling.** Not yet inventoried. The plan assumes triage (refactor couplings tied to things that differ in Elythia 2; tolerate one-off, non-reusable UI coupling) rather than 100% EventBus purity — but no actual audit of Demo2's UI callsites has been done yet to confirm this is sufficient.
- **`sandbox/` build-exclusion mechanism.** Godot export filters (`.gdignore` / export preset exclusion rules) needed to keep sandbox code out of exports — not yet configured or tested.
- **Demo2 retirement plan.** Whether Demo2 stays as a permanent reference repo, gets archived after the port completes, or something else — not decided.
- **Version control strategy.** Whether Demo3 is a new git repo from scratch or retains Demo2's git history via some form of history-preserving copy — not decided.
- **`content/` scope boundary.** Whether LDtk source files and Obsidian-adjacent narrative data count as `content/` (inside `Game/`) or stay purely in `Vault/` with only compiled/exported game data in `content/` — not yet defined.

## Action Items

1. [ ] Resolve the `ui-events.md` EventBus-for-UI design decision (blocks UI port).
2. [ ] Inventory actual UI↔gameplay coupling in Demo2 to size the refactor.
3. [ ] Decide repo name and finalize folder naming.
4. [ ] Pilot-port one self-contained system (e.g. magic system) to validate the
   approach before committing fully.
5. [ ] Resolve open questions above before treating this ADR as Accepted.
