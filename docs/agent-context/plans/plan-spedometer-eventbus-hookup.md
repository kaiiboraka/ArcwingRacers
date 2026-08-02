# Plan: Spedometer ↔ Player Hookup via EventBus

Status: 🔄 IN PROGRESS (2026-08-02). Wire the Spedometer HUD (speed number + color,
boost light, bar fill) to the player pod through the project's intended relay — the
`EventBus` autoload described in `docs/decisions/adrs/0002-eventbus-ui-communication.md`
and referenced throughout `docs/technical/` (`pod-handling-and-boost.md`,
`architecture-plan.md`, `ui-events.md`). The bus does not exist yet; the spedometer
is a standalone scene not placed in any level.

## Goal

`UI/HUD/Spedometer/spedometer.tscn` reacts live to the `Arcwing` pod in `Test_Level.tscn`:
- Speed number + color from pod velocity (`m/s`)
- Boost light (OFF/GREEN/YELLOW/RED → `light_color`)
- Fill-bar reveal percentage from speed fraction

Relay = the EventBus autoload (ADR 0002), NOT direct node refs (four-pillar rule: UI never
references systems; reads only via EventBus signals, subscribed in `_ready()`, never polls).

## Scope IN

| Piece | Files | Notes |
| --- | --- | --- |
| EventBus autoload | `Systems/Events/event_bus.gd` (new) | GDScript `Node` autoload per ADR 0002; strongly-typed signals (below) |
| Autoload registration | `project.godot` | `EventBus="*res://Systems/Events/event_bus.gd"` — matches `InputCollector` script-autoload precedent |
| Pod emissions | `Systems/Pod/PodController.gd` | Speed each physics tick; boost state transitions via one `_change_boost_state()` helper; charge/heat on change |
| Spedometer subscriptions | `UI/HUD/Spedometer/spedometer.gd` | Connect in `_ready()` (runtime only — script is `@tool`); map boost light → color; drive `bar_fill.set_percentage()` |
| Typed bar_fill ref | `UI/HUD/Spedometer/bar_fill.gd` | Add `class_name BarFill` so spedometer can statically call `set_percentage()` |
| Scene placement | `Content/Scenes/Levels/Test_Level.tscn` | Add CanvasLayer + Spedometer instance so it actually receives events |
| Scene default | `spedometer.tscn` root | `light_color` → WHITE (BoostLight.OFF resting state; yellow was a preview value) |

## EventBus signal contract

Following the **technical spec** (`pod-handling-and-boost.md`) for boost event names — it
matches the pod's actual state machine (CHARGING→READY→BOOSTING→OVERHEAT) — plus
`boost_charge_updated` from ADR 0002 for the charge gauge.

```
signal speed_updated(speed_mps: float, speed_fraction: float)   # pod → speed gauge + fill bar
signal boost_light_changed(light: int)                          # BoostLight enum value → HUD light
signal boost_charge_updated(charge_percent: float)              # 0–100, charge gauge (ADR 0002)
signal boost_heat_updated(heat_pct: float)                      # 0–100, heat gauge
signal boost_ready()                                            # charge completed
signal boost_started()                                          # entering BOOSTING
signal boost_ended()                                            # leaving BOOSTING
signal overheat_started()                                       # entering OVERHEAT
signal overheat_ended()                                         # cooled below 0
```

`light: int` semantics documented on the bus: `0 = OFF, 1 = GREEN, 2 = YELLOW, 3 = RED`
(mirrors `PodController.BoostLight`); spedometer maps the int → `Color` locally so UI never
references the system enum.

### Decision (ADR conflict)
ADR 0002 names boost signals `boost_activated`/`boost_overheat`; the newer
`pod-handling-and-boost.md` names them `boost_ready`/`boost_started`/`boost_ended`/
`overheat_started`/`overheat_ended`/`boost_heat_updated` and shows `EventBus.boost_ready.emit()`
in code matching the pod's real state machine. The technical spec wins for boost events;
ADR 0002's `boost_charge_updated` is used for the charge gauge. Spedometer wiring itself only
depends on `speed_updated` + `boost_light_changed`, so the naming choice is low-risk.

## Pod emission points (`PodController.gd`)

- **Speed** — after `_current_speed = velocity.length();` (line ~369):
  `EventBus.speed_updated.emit(_current_speed, _speed_fraction());`
- **State machine** — replace every `_boost_state = X;` with `_change_boost_state(X);`
  (8 sites: lines ~693, 698, 703, 719, 729, 745, 748, 756). Helper emits the matching
  transition signal (READY→`boost_ready`, BOOSTING→`boost_started`, OVERHEAT→
  `overheat_started`, NORMAL-from-BOOSTING→`boost_ended`, NORMAL-from-OVERHEAT→
  `overheat_ended`) + `boost_light_changed(get_boost_light())` only when the light changes.
- **Charge** — in `_charge_boost()` after `_charge` mutates (and on reset in
  `_reset_charge_level()` / `_normal_boost`): emit `boost_charge_updated(_charge * 100.0)`
  when the integer percent changes (track `_last_charge_pct`).
- **Heat** — in `_boost_update()` (rising) and `_cool_heat()`/`_cool_after_overheat()`
  (falling): emit `boost_heat_updated(_heat * 100.0)` when integer percent changes
  (track `_last_heat_pct`). No emission when heat stays 0.

## Spedometer changes (`spedometer.gd`)

- In `_ready()` after existing setup, if `not Engine.is_editor_hint()`:
  `EventBus.speed_updated.connect(_on_speed_updated)` +
  `EventBus.boost_light_changed.connect(_on_boost_light_changed)`.
- `_on_speed_updated(speed_mps, speed_fraction)` → `speed_mph = speed_mps * MPS_TO_MPH;`
  then `bar_fill.set_percentage(clampf(speed_fraction, 0.0, 1.0) * 100.0);` (guard `bar_fill != null`).
- `_on_boost_light_changed(light)` → `light_color = _boost_light_color(light);`
- `_boost_light_color(light)` local map: `0→WHITE, 1→GREEN, 2→YELLOW, 3→RED`.
- Retype `@onready var bar_fill: TextureRect` → `: BarFill` (after adding `class_name BarFill`).

## Placement (`Test_Level.tscn`)

Add via editor MCP: `CanvasLayer` (name `SpedometerLayer`) → instance `spedometer.tscn`
under it. Anchors stay `preset 0` (top-left of screen) for now; user positions later.

## Out of scope

- Race signals (race manager doesn't exist yet), minimap, ability/shield signals.
- `traction_modifier` — pod has no traction-modifier system yet.
- HUD polish / anchoring / layout; heat & charge gauges (no HUD element consumes them yet —
  signals exist for when they do).

## Verification

1. `script_create`/edit files; reload `spedometer.tscn` + `Test_Level.tscn`; check parse/logs.
2. `project_run` — drive in Test_Level; confirm speed number/color, boost light, and bar
   fill track the pod; check `logs_read(source='game')` for EventBus errors.
3. User visually confirms feel/colors.

## Uncertainties / Decisions to Discuss

1. **Bar fill full-scale** — fill % = `speed_fraction` (fraction of `max_speed`=30 m/s), so
   it pegs at 100% during boost (pod hits ~80 m/s). Alternative: scale to `max_speed +
   boost_speed_bonus` so boost is visible as the last segment. **Lean:** clamp at 100% (boost
   = full bar = "all in"); user can retune via a spedometer export later.
2. **Speed emit rate** — every physics tick (60 Hz). Fine for one HUD; note if it ever
   becomes a perf concern, emit on delta threshold.
3. **`light_color` scene default** — changing yellow→WHITE to match OFF resting state; user
   had yellow only for preview.
