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

- **Recipe-phase reference: `https://github.com/iiMidnightii/PathMesh3D`.** Found while building the track editor. Generates a road mesh along a Path3D (spline ribbon + walls) — directly relevant to the ROAD/TUNNEL mesh generation phase (ADR 0010 / `TrackMeshGenerator`). Do NOT adopt the plugin itself; study its approach when implementing our generator.

- **Live path-data editor dock/window.** Phase 2 part 2 of the track editor (see `technical/tracks-and-splines.md` → Track Editor Roadmap). An editor dock/window to modify per-point track data (width, banking/tilt, recipe, recipe param, flags) more easily than raw Inspector arrays — select a point, edit its `SplinePointData` live. Active plan: `agent-context/plans/plan-live-path-data-editor.md`.

- **Test_Level track-data migration.** `Test_Level.tscn` still embeds its spline data inline (`SubResource("Resource_5pj16")` at `Test_Level.tscn:936`); `Test_Level_TrackData.tres` exists (uid://c1t0a5ta0001) but is unwired and currently fails to parse (`Parse Error: Expected '['` at line 1) — the file needs regenerating before it can be referenced. Move Test_Level to the `.tres` data file so gameplay and editor tooling share one source.

