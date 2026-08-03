# Follow-Up Tasks

Tasks explicitly deferred to a later session — not urgent, not forgotten. Remove an item once it's done and note where the resulting changes landed.

---

## Deferred Tasks

- **Write `game-design/overview.md` for ArcwingRacers.** ✅ Done — racing game design replaces Fantasy X.

- **Document starting grid system.** ✅ Done in `technical/starting-grid-and-race-start.md`.

- **Write ADR for folder architecture.** ✅ Done — ADR 0001.

- **Populate `decisions/adrs/`.** ✅ 9 ADRs recorded (0001–0009), including modeling pipeline.

- **Replace legacy `game-design/` content.** Most core docs rewritten. Still pending: `game-design/world/locations/`, `game-design/gameplay/enemies/`, `game-design/art-direction/` need review and replacement.

- **Audit `technical/` docs for 3D vs 2D correctness.** Several were written for 2D tilemaps/collisions. Check: `technical/tilemaps.md`, `technical/collisions.md`, `technical/state-machines.md`, `technical/animation.md`.

- **Replace legacy `systems/` content.** `systems/game-saving.md`, `systems/dialog.md` still describe Fantasy X. Replace for racing game.

- **Clear `unfiled-ideas.md`.** Currently empty — new items filed as they come.

- **Input buffer implementation.** Item 2 on `technical/next-technical-breakdowns.md`. Needed before full pod controller — decides whether to build it first or use raw input for MVP.

- **Pod steering implementation detail.** ✅ Done in `technical/pod-handling-and-boost.md` and `Systems/Pod/PodController.gd` — yaw + traction, plus the two turn stats (`max_turn_rate` sharpness, `turn_response` ramp) matching the EP1R model.

- **Banking model (TBD).** `technical/pod-hover-system.md` has banking as TBD. Needs EP1R playtesting notes before settling.

- **Legacy doc review.** `game-design/world/locations/`, `game-design/gameplay/enemies/`, `game-design/art-direction/` still describe Fantasy X. Replace for racing game.

- **Recipe-phase reference: PathMesh3D.** Found while building the track editor. Generates a road mesh along a Path3D (spline ribbon + walls) — directly relevant to the ROAD/TUNNEL mesh generation phase (ADR 0010 / `TrackMeshGenerator`). Downloaded 2026-08 to `C:\Projects\Godot\Plugins\PathMesh3D` (upstream `https://github.com/iiMidnightii/PathMesh3D`, MIT license). It is a C++ GDExtension with no prebuilt binaries; its core extrude algorithm is portable to GDScript. Approach + uncertainties captured in `agent-context/plans/plan-mesh-generation.md`. Do NOT adopt the plugin itself; study/port its approach.

- **Live path-data editor dock/window.** ✅ Done — `addons/arcwing_track_editor/path_data_dock.gd` + gizmo selection + Path Controls (path names + three delete levels), nav-bar Save button, saved-spline resource naming, and toolbar/dock selector display names. Closed plan: `agent-context/plans/plan-live-path-data-editor.md`. See `technical/tracks-and-splines.md` → Track Editor Roadmap, Phase 2 part 2.

- **Track editor Phase 3 — mesh generation.** The only remaining track-editor piece (ADR 0010 `TrackMeshGenerator`): bake `ROAD`/`TUNNEL` ribbon + walls + tunnel roof from the spline, honoring per-point width/tilt/recipe. Rabbit-hole sized — deliberately parked for a later session. Cursory plan + surfaced uncertainties written: `agent-context/plans/plan-mesh-generation.md`. Reference (downloaded locally, MIT, C++ GDExtension): `C:\Projects\Godot\Plugins\PathMesh3D`.

- **Track editor: "The axis ... must be normalized" spam when dragging alternate-path handles.** Reproducer: select an alternate path, drag any point/control handle → errors like `The axis Vector3 (-0.719279, 0.0, -0.696391) must be normalized.` (one per point per frame during the drag). Not game-breaking; low priority. Attempted fix: normalized the axis in `Spline.sample_normal_banked()` at `Systems/Track/spline.gd:212` (`Basis(forward, bank)` → `Basis(forward.normalized(), bank)`) — did NOT resolve the spam. Root cause still unknown. Investigated and eliminated: `up_vector_enabled` is false project-wide, so the engine's loop-smoothing twist (`curve.cpp:1770`) is unreachable; `_sample_posture` tilt (`:1897`) only runs via `sample_baked_with_rotation`/`get_point_baked_posture`, which the gizmo doesn't call; the `_draw_path:202` stack points at the stale pre-parse gizmo, so attribution is unreliable. Next step when picked up: reproduce with a freshly-parsed gizmo and instrument which `Basis(axis, angle)` call actually fires. (Reported 2026-08.)

- **Test_Level track-data migration.** `Test_Level.tscn` still embeds its spline data inline (`SubResource("Resource_5pj16")` at `Test_Level.tscn:936`); `Test_Level_TrackData.tres` exists (uid://c1t0a5ta0001) but is unwired and currently fails to parse (`Parse Error: Expected '['` at line 1) — the file needs regenerating before it can be referenced. The track editor's nav-bar Save button and saved-spline resource naming are ready to write it once wired. Move Test_Level to the `.tres` data file so gameplay and editor tooling share one source.

- **Race vertical slice (time trial first).** 🔜 DRAFT plan: `agent-context/plans/plan-race-vertical-slice.md`. Priority: timer + laps before AI/buffer. Scope: PodController input lock, `systems/race/race_manager.gd` (PREGAME→COUNTDOWN→RACING→FINISHED), `systems/race/lap_tracker.gd` (spline projection + forward-wrap lap count), minimal `ui/hud/race_hud.tscn` (countdown, lap N/M, lap/best/total times, finished banner), Test_Level wiring, stretch = takeoff boost. Deferred: input-buffer slot model, AI racers, multi-racer position sorting, waypoint gating. Open decisions recorded in the plan (wrap-vs-waypoints, RaceManager scene node vs autoload, takeoff boost in-slice, results scope).

- **Spedometer ↔ player via EventBus.** ✅ Done — `Systems/Events/event_bus.gd` autoload (ADR 0002) created + registered in `project.godot`; PodController emits `speed_updated`, `boost_state_changed`, charge/heat + transition signals; spedometer subscribes in `_ready()` (speed number/color, boost light, fill bar); spedometer instanced in `Test_Level.tscn` under `SpedometerLayer` CanvasLayer. Plan: `agent-context/plans/plan-spedometer-eventbus-hookup.md`. Note: `EventBus` now exists — the race-slice plan's "EventBus now-or-later" is resolved (build it now).

- **Spedometer 3-bar fill (bar_fill_uncharged / bar_fill_charging / bar_fill_BOOST + bar_Background_Black).** 🔄 In progress — scene structure + onready refs are in `spedometer.tscn`/`spedometer.gd`; the driving logic (replace the dead single `bar_fill` call, drive each bar from boost state, toggle black bg during BOOSTING, reset appropriately) is the current task. Spec in the bar-fill-v2 section of `agent-context/plans/plan-spedometer-eventbus-hookup.md`. Also fixed the stale signal name: the bus declares `boost_state_changed`, not `boost_light_changed` (PodController:348 + spedometer `_ready()` connect updated).

- **Wing open/close animations (state ladder + turn/pitch drive).** 🔄 In progress — drive the 4-idle + 2-transition library (`Arcwing.res`) from `|turn_frac|` and nose pitch (nose-up opens more, nose-down closes), one state per 0.5s, rendered through the transition animations. Plan: `agent-context/plans/plan-wing-open-animations.md`.

