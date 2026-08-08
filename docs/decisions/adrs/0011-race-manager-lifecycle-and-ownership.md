# ADR 0011: Race Manager Lifecycle and Ownership

## Status
Proposed

> **WIP.** This record captures a design conversation (2026-08) that reached a partial conclusion but ended with an explicit *unresolved* owner. The one thing the conversation agreed should change is recorded below; whether a level loader is built now, and whether the manager becomes an autoload, is still open. Do not treat the Decision section as final.

## Context

The time-trial slice wires the `RaceManager` (`Systems/Race/race_manager.gd`) as a scene node inside the level, with `pod`, `track`, and `starting_line` exported and set in the inspector (`Content/Scenes/Levels/Test_Level.tscn`, `Level_Grassy.tscn`). The HUD finds it at runtime via the `"RaceManager"` group and polls it per tick.

Two observations prompted a challenge to this shape:

1. **A level doesn't own a pod.** Pod selection happens in an unrelated menu. The race's player data is "piped in" from that selection, so the pod must be instanced at runtime and handed to the manager — it cannot be authored into the level and exported at edit time. The inspector-export `pod` is a slice artifact, not the target architecture (the design doc `docs/technical/race-manager.md` already models `all_racers: Array[PodController]` passed into the manager).
2. **Skepticism about the level-instantiated manager** as "clunky" — everything a race needs lives scattered in the level scene, and adding it to each level is "another thing to have to remember."

The question considered: should `RaceManager` be a global autoload (ever-present, toggled on/off when a race needs it) because it drives the entire game loop?

## Considered Options

### Option A — Autoload RaceManager

Make the manager a registered autoload; it always exists, and each race "turns it on."

**For:** one instance; always accessible; no per-level wiring; survives scene changes.

**Against:**
- An autoload initializes before any scene loads, so it **cannot** hold the inspector-exported `pod`/`track`/`starting_line` refs that make the current design work. The level→manager handshake would have to move to runtime registration, which is *more* fragile than the edit-time wiring it replaces.
- The manager is not genuinely global — menus and idle scenes have no race. It is a per-race controller whose state must die when the race dies. An autoload keeps stale state and forces an explicit reset path (a footgun) for no gain.
- The project bar is already high (`docs/technical/singleton-controllers.md`: 16 autoloads; use one only when genuinely global, exactly one instance, persists across all scene changes, reachable from anywhere).
- The keep-alive / turn-on-and-off need is a *flow* concern, not a race-state-machine concern.

### Option B: Keep the manager scene-in-level (status quo)

**For:** inspector wiring works today; a level is self-contained; opening a level and pressing play runs a race with zero orchestration.

**Argument against:** fails the moment the pod moves out of the level — the `pod` export cannot be authored in the level anymore, so the primary argument for scene placement evaporates. It also perpetuates "every level must remember to include the manager."

### Option C — Level loader / race bootstrap composes the race (tentatively favored)

A level loader / race bootstrap / flow controller:

1. receives the player's selections (track, pod, laps) from the menu,
2. instantiates the level scene,
3. spawns the chosen pod,
4. creates the `RaceManager` as a child of the race root,
5. hands it `pod`, `track`, `starting_line`, race config via injection,
6. starts the countdown.

The manager becomes an assembly of per-race wiring that is destroyed with the race — stale state dies with the scene.

**For:** composition lives in one place so levels don't need to remember to include the manager; pod selection sits where the data comes from; mirrors the design doc's `all_racers` model; "ever-present flow" becomes a thin session/flow controller if ever needed anywhere else.

**Against / still open:** this is real machinery (a loader scene or script) that a one-level slice does not yet justify. The design doc outright does not resolve the question (`race-manager.md` integration summary: "Node, scene-level **or autoload**"). Whether to build the bootstrapping logic now, and whether the manager is a loader-created per-race node vs. an autoloaded session controller, remain unresolved.

## Decision (unresolved — captured, not final)

- **Agreed now:** the manager's lifecycle must move to **handoff/injection** — `begin_race(pod, track, grid, config)` — rather than inspector exports. This is correct under every future option (loader or autoload) and is cheap to do now.
- **Open:** build a level loader / race bootstrap now, or wait until a menu and a second level exist. Whether the bootstrapping role is a loader-created node or an autoloaded flow/session controller is unresolved.

## Addendum — Scene Management Layer (2026-08)

Option C is realized as a **generic master scene**, per the session's discussion:

- **Chosen:** a `GameManager` scene (scene `addons/utility_scripts/SceneManagement/game_manager.tscn`, root + `GameManager.gd`) is registered as the project autoload and is the only scene that never changes. Every gameplay scene is instantiated inside one of its three containers — `World3D` (`Node3D`), `World2D` (`Node2D`), `UI` (`CanvasLayer`, whose `Control` child sits full-rect as the HUD host). Game code reaches it directly as `GameManager`; therefore **no separate `Globals` autoload and no `Globals.game_manager = self` registration are used** — the autoload registration itself supplies the global reference.
- **Transition API:** `change_gui_scene` / `change_3d_scene` / `change_2d_scene(path, mode)` with a single `ChangeMode` enum — DELETE (queue_free + drop from cache), HIDE (in-tree, still processing, invisible), REMOVE (out-of-tree, cached, stopped) — replacing the `delete: bool + keep_running: bool` pair.
- **Game composition lives in the flow, not the master:** a game-flow controller (`Systems/GameFlow/`) listens on EventBus requests (ADR 0002), picks the selected track/scene, then calls `RaceManager.begin_race(pod, track, grid, config)` — the injection API decided above. The master-scene addon stays generic/reusable; the flow dictates what gets assembled.
- **Levels drop pod/race wiring:** levels are authored as pure environment + track + grid; the flow spawns the pod and the manager from the menu's selection.

## Consequences
- **Positive:** narrowing the "would rather not manage a per-level node" gripe to a named composer (level bootstrap) gives the orchestrator a home instead of a scattered requirement.
- **Tradeoff accepted if Option B stays:** the pod-in-level authoring is a throwaway that gets reworked when the menu/pod-selection exists.
- **Tradeoff accepted if Option C is adopted:** a new runtime piece (bootstrapper) must be built and tested; its interface must be defined before the menu exists.

## Open Questions

- Build the level bootstrap point now, or after the menu + a second level exist?
- If the session controller were autoloaded, how would it persist the pod selection across a scene change?
- Should the manager's inputs (the `TrackSplineData` asset, grid, race config) eventually be handed in as resources rather than node references, per ADR 0008? The track definition is already a serialized `.tres` (`TrackSplineData`).

## Addressed By

- `addons/utility_scripts/SceneManagement/GameManager.gd` + `game_manager.tscn` — the generic master scene (autoload), World3D/World2D/UI containers, ChangeMode transition API.
- `Systems/GameFlow/` — game-flow controller (composition hub) still to be built; it will subscribe to EventBus and drive `RaceManager.begin_race(...)`.
- In progress — `race_manager.gd` still exports `pod`/`track`/`starting_line` (unchanged).
- Recommended next step: change the manager to a `begin_race(...)`/start API before the first tracked pod selection lands.