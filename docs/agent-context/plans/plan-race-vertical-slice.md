# Plan: Race Vertical Slice (Time Trial First)

Status: ✅ COMMITTED (2026-08-07). Priority per user: **timer + laps first**, before ALI and
the input-buffer slot model. Floor goal is a playable time trial: countdown, drive N laps,
live lap/best-lap/total time, finish + banner — wired into the current prototype level
(`Level_Grassy.tscn`, the project's main scene) with the HUD living in the global `HUD.tscn`.
Design homes: `technical/race-manager.md`, `technical/starting-grid-and-race-start.md`,
`technical/input-buffer.md`, `game-design/race-structure/race-manager.md`, `game-design/hud/hud.md`.

Open decisions resolved at commit time (2026-08-07, user + agent conversation):
- Decision 1 (EventBus now or later): **now** — EventBus already exists
  (`Systems/Events/event_bus.gd` autoload, ADR 0002); race signals are added there and the
  HUD subscribes via EventBus (per ADR 0002). Direct signals would have been fine but are
  not needed.
- Decision 2 (wrap vs waypoints): **forward seam-wrap only**, keep the hook. `Test_`-level
  has no branches in play.
- Decision 3 (lap count): exported `total_laps`, default 3, per scene.
- Decision 4 — RaceManager as scene node: yes, added to `Level_Grassy.tscn`; LapTracker is
  a `RefCounted` owned by RaceManager (no extra scene node needed).
- Decision 6 (results): finish banner + times on the HUD; full results screen deferred.
- Stretch (takeoff boost): **deferred** to a follow-up — the slice stays small and does not
  touch pod boost/heat code.

## Goal

Turn `Test_Level.tscn` from "drive around" into an actual race feel with the **smallest
single-racer slice**:

- Countdown 3-2-1 → GO, controls locked until GO
- Lap counting via spline projection + forward-wrap detection, lap times, best lap, total time
- Live HUD (lap N/M, current lap time, best lap, total, countdown, finished banner)
- Finish at N laps (exported, default 3) → results
- Stretch (include if slice is small): takeoff-boost window per starting-grid doc

Everything beyond that is explicitly deferred (see Scope Out).

## Scope IN

| Piece | Files | Notes |
| --- | --- | --- |
| Input lock | `Systems/Pod/PodController.gd` | Add `input_locked` flag + `set_input_locked(bool)`; skip input processing when locked (docs specify this; not yet in code) |
| Race Manager | `systems/race/race_manager.gd` | `State { PREGAME, COUNTDOWN, RACING, FINISHED }`; countdown via `SceneTreeTimer` (1s/tick); `race_timer`; finish at N laps; timeout |
| Lap Tracker | `systems/race/lap_tracker.gd` | Per-tick `TrackSpline.project_world(pod.global_position)` → offset/t; forward-only wrap detection increments lap; lap times array; best lap |
| Minimal HUD | `ui/hud/race_hud.gd` + `.tscn` | CanvasLayer HUD: countdown number, lap `N/M`, current lap time, best lap, total time, finished banner |
| Wiring | `Content/Scenes/Levels/Test_Level.tscn` | Add RaceManager node + HUD instance; find existing `StartingLine`, `Arcwing` pod, and the inline `TrackSpline`; place pod at grid slot 0 on PREGAME |
| (stretch) Takeoff boost | `Systems/Pod/PodController.gd` | `check_takeoff_boost()` per starting-grid doc: accelerator held+released during countdown → short full boost on GO |

## Scope OUT (deferred, not forgotten)

- **Input buffer slot model** (`input-buffer.md`) — PodController keeps reading the
  `InputCollector` autoload directly for this slice. No `InputBufferManager` yet.
- **AI racers / opponents** (`racer-ai.md`, `ai-opponents.md`) — single-player time trial; the
  HUD position is always 1.
- **Multi-racer position sorting / live rankings** (`race-manager.md` § Position Sorting) —
  needs >1 racer; single racer trivially first.
- **Waypoint gating** — docs specify waypoints for branch validation; `Test_Level` uses a
  single closed spline with no branches in play, so forward-wrap detection is sufficient now.
  Keep the lap-count hook so waypoints can slot in later without a rewrite.
- **EventBus autoload build-out** — see Decision 1.
- **Network sync / rollback, results screen beyond a banner, HUD polish, audio, minimap.**

## Architecture

```
Test_Level (scene)
├── StartingLine        (existing — get_start_positions()[0] / place_racers())
├── Arcwing             (existing pod; reads InputCollector directly for now)
├── TrackSpline         (existing inline spline — project_world() for lap tracking)
├── RaceManager         (new: systems/race/race_manager.gd)
│   └── LapTracker      (new: systems/race/lap_tracker.gd)
└── RaceHUD             (new CanvasLayer: ui/hud/)
```

RaceManager owns the state machine + timer + countdown. LapTracker owns spline projection +
lap times. HUD listens to RaceManager signals (or EventBus — Decision 1). No autoload
required: RaceManager is a scene node in Test_Level; HUD connects in `_ready()`.

## Implementation Steps (bite-sized)

1. **PodController input lock** — add `input_locked` + `set_input_locked(bool)`; early-return
   in `_physics_process` when locked.
2. **LapTracker** — project pod → spline offset each physics tick; store prev offset; forward
   wrap (diff < -0.5 → +1.0, or prev > 0.8 and curr < 0.2) increments lap; append `lap_time =
   race_timer - lap_start`; track best lap.
3. **RaceManager** — state machine; PREGAME places pod on grid + locks; COUNTDOWN emits
   ticks 3/2/1 (1s each) then GO, unlocks, starts timer; RACING accumulates `race_timer`,
   ticks LapTracker, checks `lap_count >= total_laps` → FINISHED; timeout safety.
4. **HUD** — CanvasLayer + labels: countdown (big, center), lap `N/M`, current lap time,
   best lap, total time, finished banner.
5. **Wire Test_Level** — add RaceManager + RaceHUD; export refs (pod, track, grid, laps);
   place pod at `grid.get_start_positions()[0].global_position`; lock on PREGAME.
6. **(stretch) Takeoff boost** — countdown hold/release tracking in pod + `check_takeoff_boost`.
7. **Verify** — run in editor; parse + log checks; user drives and confirms feel.

## Uncertainties / Decisions to Discuss

1. **EventBus now or later?** `race-manager.md` and `ui-events.md` reference an `EventBus`
   autoload + `InputBufferManager`; neither exists (`game-events.md:26` marks EventBus TBD;
   `project.godot` autoloads confirm none). Options:
   (a) Build a minimal GDScript `EventBus` autoload now — matches the docs, future-proofs
   AI/HUD/multiplayer, but adds a global contract before the second consumer exists.
   (b) Use plain RaceManager signals + direct HUD connection — the Tier-1 default in
   `game-events.md`, least work, trivially swapped for EventBus later.
   (c) Hold and decide when a real second consumer appears.
   **Lean:** (b) for this slice; revisit when AI or network lands.
2. **Lap counting: pure wrap vs waypoints.** Docs mandate waypoint gating (branch validation),
   but no branches are in play on Test_Level. **Lean:** forward-wrap only, keep the hook.
3. **Lap count.** Exported `total_laps`, default 3. Make it per-track data later?
4. **RaceManager as scene node vs autoload.** Docs allow either. **Lean:** scene node in
   Test_Level; promote to autoload only if a second scene needs it.
5. **Takeoff boost in this slice?** Adds race-feel but touches the pod's boost/heat code.
   **Lean:** include if the first 5 steps stay small; otherwise defer with a follow-up.
6. **Results** — finish banner only now, or a dedicated results panel (per `race-manager.md`
   § Results Data)? **Lean:** banner + times on the HUD; full results screen is its own slice.

## File List

| File | Purpose |
| --- | --- |
| `systems/race/race_manager.gd` | State machine, countdown, timer, finish/timeout |
| `systems/race/lap_tracker.gd` | Spline projection, forward-wrap lap count, lap/best times |
| `ui/hud/race_hud.gd` | HUD logic (signals → label updates) |
| `ui/hud/race_hud.tscn` | CanvasLayer + labels |
| `Systems/Pod/PodController.gd` | + `input_locked`/`set_input_locked`; (stretch) takeoff boost |
| `Content/Scenes/Levels/Test_Level.tscn` | Add RaceManager + RaceHUD wiring |
