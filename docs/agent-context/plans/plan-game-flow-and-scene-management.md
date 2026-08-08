# Plan: Game Flow + Scene Management Consolidation (`[GFT]`)

Status: ✅ COMMITTED (2026-08-08). Consolidates `GameManager` (script autoload + single
master main scene) with Maaack's Game Template (autoloads `SceneLoader`/`AppConfig`/
music/UI-SFX), and introduces the project-specific flow controller
(`Systems/Loading/ProjectLoader.gd`) that chains them per ADR 0011's "composition lives in
the flow" addendum.

## Goal

- `game_manager.tscn` is retired; `GameManager.gd` becomes a **script** autoload (the
  `InputCollector` pattern: `Xyz="*res://.../Xyz.gd"`). Containers are injected at runtime
  by the boot script instead of `@export` node paths baked into a scene.
- A new **main scene** (`ArcwingRacers.tscn`) owns the three container nodes — `World3D`
  (`Node3D`), `World2D` (`Node2D`), `UI` (`CanvasLayer` host) — plus a minimal boot script
  that assigns the refs to the `GameManager` autoload once. One-and-only master scene;
  everything else instantiates inside its containers.
- `Systems/Loading/ProjectLoader.gd` (script autoload) is the project's flow controller:
  holds project scene references, offers async chain helpers (`SceneLoader` background load
  → `GameManager.change_*_packed`), and is the future ADR-0011 composition hub
  (spawn pod + `RaceManager` + `begin_race(...)`).
- Adopt from Maaack's template: `SceneLoader` autoload + loading screen, main menu /
  options / pause / credits windows, `PlayerConfig`/`AppSettings`/`GlobalState` settings
  save. **Skip:** `LevelManager`/`SceneLister`/win-lose flow, `opening.tscn` as main scene,
  example `game.tscn`/levels.
- `AppConfig` is NOT used for flow logic (user dislikes the buried export field). The
  template plugin registers it, so leave the autoload present for template compatibility,
  but ProjectLoader owns scene references via constants/exports. Template scenes get their
  path exports set directly so they never fall back to `AppConfig`.

## Scope IN (this session)

| Piece | Files | Notes |
| --- | --- | --- |
| GameManager → script autoload | `addons/utility_scripts/SceneManagement/GameManager.gd` | Remove `@export world_3D/world_2D/ui`; add `configure(world3d, world2d, ui)`; keep `change_*_scene(String, mode)`; add packed variants `change_*_scene_packed(packed, mode)` for async handoff |
| Master main scene | `Content/Scenes/ArcwingRacers.tscn` + boot script | Root `ArcwingRacers` (Node) with `World3D`/`World2D`/`UI`; boot assigns refs into autoload once, then calls `ProjectLoader.bootstrap()` |
| Flow controller | `Systems/Loading/ProjectLoader.gd` | Scene-path table, async load helpers, `bootstrap()`, menu→race handoff |
| Main menu / options / pause wiring | `UI/Example_Scenes/scenes/menus/...`, `scenes/windows/pause_menu_layer.tscn` | GUI scenes under `GameManager.ui`; New Game → ProjectLoader → test level; `ui_cancel` → pause layer. **Done:** main menu host is the project copy `main_menu.tscn` (`ProjectLoader.MAIN_MENU_SCENE`); opening splash is the project copy `opening.tscn`+`opening.gd`; New Game → `ProjectLoader.DEFAULT_TRACK_SCENE` (`Level_Grassy.tscn`); HUD mounted by uid (`res://UI/HUD/HUD.tscn` = `uid://c1gnx5bseg8ac`, `ProjectLoader.HUD_SCENE_UID`) |
| Settings save | `PlayerConfig`, `AppSettings`, `GlobalState` (template) | Options windows persist via template scripts; autoloads already registered by plugin |
| project.godot | `project.godot` | `GameManager` → script autoload; add `ProjectLoader` autoload; `main_scene` → ArcwingRacers uid |

## Scope OUT (deferred, not forgotten)

- **AI/opponents, multi-racer sorting, full results screen** — race slice later.
- **`RaceManager.begin_race(...)` conversion** — ADR 0011's agreed next step; land it when
  the race slice is reached, not in the scene-mgmt session.
- Opening/splash, `LevelManager`/level-lister/win-lose, example `game.tscn`/levels.
- Minimap, audio, netfox scene-rollback integration.

## Architecture

```
Autoloads (order: EventBus … GameManager, SceneLoader, ProjectMusicController,
           ProjectUISoundController, ProjectLoader)
GameManager (script autoload)  -- generic scene-swap + containers + cache (ChangeMode)
ProjectLoader (script autoload) -- scene paths, async chain helpers (SceneLoader → GameManager),
                                   bootstrap(), menu→race composition (ADR-0011)
SceneLoader (Maaack autoload)  -- load_threaded background + loading screen + scene_loaded
AppConfig (Maaack autoload)    -- present (template/plugin wiring); UNUSED by our flow code

ArcwingRacers.tscn  (main scene, never changes)
├── World3D  (Node3D)  -- scenes loaded here (Test_Level / Level_Grassy; future race)
├── World2D  (Node2D)  -- 2D worlds/effects
├── UI       (CanvasLayer root) -- menu windows, pause layer, HUD host
└── _Boot    (script)  -- assigns containers into GameManager, starts ProjectLoader.bootstrap()
```

Core transition (the chain the user asked about):

```
ProjectLoader.load_scene_into_world3d(path):
    GameManager.change_gui_scene(loading_screen_path)   # show loading screen in UI container
    SceneLoader.load_scene(path, true)                  # background threaded load
    await SceneLoader.scene_loaded
    GameManager.change_3D_scene_packed(SceneLoader.get_resource(), DELETE)
```

No `get_tree().change_scene_*` anywhere — containers only.

## Implementation Steps (bite-sized)

1. **GameManager refactor** — remove `@export` container fields; add
   `func configure(world3d : Node3D, world2d : Node2D, ui : CanvasLayer)`; add
   `change_2D_scene_packed` / `change_3D_scene_packed` / `change_gui_scene_packed(packed,
   mode)` that reuse `_swap_scene` (path keyed by `packed.resource_path`). Keep
   DELETE/HIDE/REMOVE semantics identical.
2. **Master scene + boot** — create `Content/Scenes/ArcwingRacers.tscn` with containers +
   `_Boot` script; `_Boot._ready()`: `GameManager.configure(...)`, then
   `ProjectLoader.bootstrap()`.
3. **ProjectLoader** — create script with: scene-path constants (main menu, options, pause,
   loading screen, test track), `bootstrap()` (loads main menu into UI container), async
   helpers above, and a `start_race(track_path)` stub that loads the track into `World3D`
   and will spawn `RaceManager` (ADR-0011 composition) later.
4. **project.godot** — swap `GameManager` autoload to script path; add
   `ProjectLoader="*res://Systems/Loading/ProjectLoader.gd"`; set `run/main_scene` to the
   ArcwingRacers scene uid.
5. **Menu wiring** — main menu GUI scene under `UI` container; New Game → ProjectLoader
   loads the test rig (`Level_Grassy.tscn` or `Test_Level.tscn`); `ui_cancel` → pause layer;
   options window persists via template autoloads.
6. **Verify** — editor parse via `scene_open` / project launch for errors; user drives the
   menu→race flow and reports feel.

## Uncertainties / Decisions to Confirm

1. **Flow controller name/location** — resolved: `Systems/Loading/ProjectLoader.gd`
   (user's explicit choice).
2. **GameManager stays in the generic `addons/utility_scripts/SceneManagement/` folder**
   even though the master scene moves to `Content/Scenes/`. Keep the addon generic;
   containers configured at boot → addon stays reusable.
3. **UI container / HUD.** User says UI auto-spawning HUD is a temporary dead-end. New
   hierarchy: `UI` host is a plain CanvasLayer; the HUD (`UI/HUD.tscn`) is loaded as its own
   GUI scene when a race is active — no special-casing inside `UI/UI.tscn`.
4. **Loading screen** shown as a GUI scene inside the UI container (not a whole-tree swap).
5. **`AppConfig`** left registered (plugin adds it) but unused by our flow; template scene
   path exports set directly.

## File List

| File | Purpose |
| --- | --- |
| `addons/utility_scripts/SceneManagement/GameManager.gd` | Script autoload; containers; ChangeMode; sync + packed swap API |
| `Content/Scenes/ArcwingRacers.tscn` | Master scene: World3D / World2D / UI / _Boot |
| `Systems/Loading/ProjectLoader.gd` | Project flow controller (scene refs, async helpers, race bootstrap) |
| `UI/Example_Scenes/scenes/menus/main_menu/main_menu.tscn` | Project main menu host GUI (project copy; not `main_menu_with_animations.tscn`) |
| `UI/Example_Scenes/scenes/opening/opening.tscn` + `opening.gd` | Project opening splash; handoff → `ProjectLoader.opening_finished()` |
| `UI/HUD/HUD.tscn` (`uid://c1gnx5bseg8ac`) | Race HUD mounted as UI-container overlay during a race |
| `project.godot` | autoloads, main scene |
| `addons/utility_scripts/SceneManagement/game_manager.tscn` | Deleted after the swap |
