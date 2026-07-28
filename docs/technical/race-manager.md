# Race Manager

**Location:** `systems/race/race_manager.gd`
**Dependencies:** EventBus, InputBufferManager, Spline (track resource), Pod Physics, Starting Grid

---

## State Machine

```gdscript
enum State { PREGAME, COUNTDOWN, RACING, FINISHED, RESULTS }

class_name RaceManager
extends Node

var state: State = State.PREGAME
var input_buffers: InputBufferManager
var all_racers: Array[PodController]
var lap_tracker: LapTracker
var race_timer: float = 0.0       # elapsed race time (RACING state only)
var finish_order: Array[int]      # slot indices, winner first
var timeout_duration: float       # computed from lap count + track length
```

### State Transitions

```gdscript
func transition_to(new_state: State):
    state = new_state
    match state:
        State.PREGAME:   _enter_pregame()
        State.COUNTDOWN: _enter_countdown()
        State.RACING:    _enter_racing()
        State.FINISHED:  _enter_finished()
        State.RESULTS:   _enter_results()
    EventBus.race_state_changed.emit(state)
```

### PREGAME → COUNTDOWN

```gdscript
func _enter_pregame():
    var grid = track.starting_grid
    grid.place_racers(all_racers)

    for racer in all_racers:
        racer.set_input_locked(true)
        racer.global_position = grid.start_positions[racer.slot_index].global_position

    await camera_controller.play_intro_sequence()
    transition_to(State.COUNTDOWN)
```

### COUNTDOWN → RACING

```gdscript
func _enter_countdown():
    for tick in [3, 2, 1]:
        EventBus.race_countdown_tick.emit(tick)
        await get_tree().create_timer(1.0).timeout
    EventBus.race_countdown_go.emit()

    for racer in all_racers:
        racer.set_input_locked(false)
        racer.check_takeoff_boost()

    transition_to(State.RACING)
```

### RACING Loop

```gdscript
func _physics_process(delta):
    if state != State.RACING:
        return

    race_timer += delta

    # 1. Consume all input buffers
    var snapshots = input_buffers.consume_all()

    # 2. Tick each pod's physics with its buffer
    for racer in all_racers:
        if racer.is_dnf:
            continue
        racer.physics_tick(snapshots[racer.slot_index], delta)

    # 3. Update lap tracking
    for racer in all_racers:
        if racer.is_dnf:
            continue
        lap_tracker.update(racer)

    # 4. Check for finish
    _check_finish_conditions()

    # 5. Check timeout
    if race_timer >= timeout_duration:
        _force_finish()
```

### FINISHED → RESULTS

```gdscript
func _enter_finished():
    for racer in all_racers:
        racer.set_input_locked(true)
    EventBus.race_finished.emit(finish_order)
    # Hold for brief celebration moment
    await get_tree().create_timer(2.0).timeout
    transition_to(State.RESULTS)

func _enter_results():
    EventBus.race_results_ready.emit(_build_results())
```

---

## Lap Tracker

**Location:** `systems/race/lap_tracker.gd`
**Dependencies:** Spline resource (waypoints)

### Per-Racer State

```gdscript
class RacerProgress:
    var slot: int
    var spline_t: float = 0.0
    var last_cleared_waypoint: int = -1  # index, -1 = none
    var lap_count: int = 0
    var finished: bool = false
    var finish_position: int = -1
    var lap_times: Array[float] = []
    var lap_start_time: float = 0.0
```

### Update (Called Every Physics Tick)

```gdscript
func update(racer: PodController):
    var progress = _progress[racer.slot_index]

    # 1. Project racer position onto main spline
    progress.spline_t = track.spline.project(racer.global_position)

    # 2. Waypoint gating
    _check_waypoints(progress)

    # 3. Lap increment check
    _check_lap_completion(progress)
```

### Waypoint Gating

```gdscript
func _check_waypoints(progress: RacerProgress):
    var next_idx = progress.last_cleared_waypoint + 1
    if next_idx >= waypoints.size():
        return  # All waypoints cleared this loop

    var wp = waypoints[next_idx]
    if progress.spline_t > wp.spline_t - wp.activation_radius:
        # Also verify racer is moving forward on the spline
        # (compare with last-known t or use velocity projection)
        if _is_forward_motion(progress):
            progress.last_cleared_waypoint = next_idx
            EventBus.racer_cleared_waypoint.emit(progress.slot, next_idx)
```

**Forward-motion check:** Compare `spline_t` with the previous frame's value. If `spline_t` increased (allowing for wrap at 0→1), the racer is going forward. Backward movement doesn't clear waypoints.

```gdscript
func _is_forward_motion(progress: RacerProgress) -> bool:
    var diff = progress.spline_t - progress._prev_spline_t
    # Handle wrap: if diff is very negative, they wrapped forward (0→1)
    if diff < -0.5:
        diff += 1.0
    return diff > 0.0
```

### Lap Completion

```gdscript
func _check_lap_completion(progress: RacerProgress):
    # Detect wrap: spline_t crossed from near-1.0 to near-0.0 (or vice versa)
    var wrap_detected = (progress._prev_spline_t > 0.8 and progress.spline_t < 0.2) \
                     or (progress.spline_t < progress._prev_spline_t - 0.5)

    if not wrap_detected:
        return

    # All waypoints must be cleared to count the lap
    if progress.last_cleared_waypoint >= waypoints.size() - 1:
        progress.lap_count += 1
        var lap_time = race_timer - progress.lap_start_time
        progress.lap_times.append(lap_time)
        progress.lap_start_time = race_timer
        progress.last_cleared_waypoint = -1  # Reset for next lap

        EventBus.racer_completed_lap.emit(progress.slot, progress.lap_count, lap_time)

        if progress.lap_count >= total_laps:
            progress.finished = true
```

### Wrap Direction

The wrap detector must distinguish **forward** (completed a lap) from **backward** (went the wrong way). Since spline_t is monotonic forward and wraps at 1.0→0.0:

- Forward wrap: `prev ≈ 1.0`, `curr ≈ 0.0`, diff very negative (e.g. 0.95 → 0.05 = -0.9)
- Backward wrap: `prev ≈ 0.0`, `curr ≈ 1.0`, diff very positive (e.g. 0.05 → 0.95 = +0.9)

Only forward wraps trigger lap completion. Backward wraps have no effect.

---

## Position Sorting

```gdscript
func get_rankings() -> Array[int]:
    # Returns slot indices sorted by position (best first)
    var entries = []
    for racer in all_racers:
        var p = lap_tracker.get_progress(racer.slot_index)
        entries.append({
            "slot": racer.slot_index,
            "lap": p.lap_count,
            "t": p.spline_t,
            "finished": p.finished
        })

    entries.sort_custom(func(a, b): return _compare_position(a, b))
    return entries.map(func(e): return e.slot)

func _compare_position(a, b) -> bool:
    if a.finished != b.finished:
        return a.finished  # Finished racers beat unfinished ones
    if a.lap != b.lap:
        return a.lap > b.lap
    return a.t > b.t  # Higher spline_t = further along
```

**Tiebreaker:** If two racers have identical `(lap, spline_t)`, they are tied. The sort is stable — they retain their relative order from the previous tick, preventing visual jitter.

---

## Finish Detection

```gdscript
func _check_finish_conditions():
    var finished_count = 0
    for racer in all_racers:
        var p = lap_tracker.get_progress(racer.slot_index)
        if p.finished and p.finish_position == -1:
            p.finish_position = finish_order.size() + 1
            finish_order.append(racer.slot_index)
            EventBus.racer_finished.emit(racer.slot_index, p.finish_position)
        if p.finished:
            finished_count += 1

    # Race ends when all racers finish OR first racer + all others are close enough
    if finished_count >= all_racers.size():
        transition_to(State.FINISHED)

    # Early end: when first racer finishes, remaining racers get one extra lap max
    if finish_order.size() >= 1:
        var leader_finish_time = race_timer
        for racer in all_racers:
            var p = lap_tracker.get_progress(racer.slot_index)
            if not p.finished and (race_timer - leader_finish_time) > EXTRA_LAP_TIMEOUT:
                p.finished = true
                p.dnf = false  # They finished, just behind
                # Position assigned in next tick's finish check
```

---

## Timeout

```gdscript
const BASE_LAP_TIME_ESTIMATE: float = 60.0  # 60 seconds per lap (estimate)
const TIMEOUT_MULTIPLIER: float = 3.0

func _compute_timeout() -> float:
    return total_laps * BASE_LAP_TIME_ESTIMATE * TIMEOUT_MULTIPLIER

func _force_finish():
    for racer in all_racers:
        var p = lap_tracker.get_progress(racer.slot_index)
        if not p.finished:
            p.finished = true
            p.dnf = true
    transition_to(State.FINISHED)
```

---

## Network Sync

In multiplayer (see the [multiplayer design doc](../game-design/multiplayer.md) for architecture and [Godot's High-Level Multiplayer API](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) for transport), the host runs the Race Manager authoritatively. Remote peers send input packets at frame rate; the host consumes them into the slot buffers and simulates.

State snapshots are broadcast from host to all peers at a tunable rate (default 20 Hz) via `@rpc("authority", "unreliable_ordered")`:

```gdscript
@rpc("authority", "unreliable_ordered")
func sync_race_state(state: PackedByteArray):
    # Deserialize and interpolate on clients
    # Contains: per-racer transform, lap_count, spline_t, heat, boost, shield, ability cooldown
```

The host serializes the current state of every racer into a compact binary frame and broadcasts it. Clients interpolate between the last two received snapshots for smooth visuals. See the [input buffer serialization](input-buffer.md#network-serialization-future) for the same pattern applied to input packets.

### Rollback Netcode (Post-Launch)

For responsive online play, the [netfox](https://github.com/foxssake/netfox) addon provides rollback netcode that replaces `_physics_process()` with `_rollback_tick(dt, tick, is_fresh)`. In this model:

- Every node participating in rollback implements `_get_rollback_state_properties()` (listing properties to save/restore) and `_rollback_tick()` instead of `_physics_process()`
- The `RollbackSynchronizer` handles state save/restore when the host detects a misprediction and rewinds
- Input gathering uses `BaseNetInput._gather()` instead of direct `Input` reads — maps directly to our per-slot input buffer
- `RewindableRNG` ensures deterministic random during re-simulation (e.g. collision outcomes, AI decisions)
- NPCs and other non-input nodes participate the same way via `RollbackSynchronizer` (see [rollback-npc example](https://github.com/foxssake/netfox/tree/main/examples/rollback-npc))

**Migration path:** For Lan/online post-launch, pod physics and the Race Manager loop would switch from `_physics_process()` to `_rollback_tick()`. The per-slot input buffer becomes a `BaseNetInput` subclass. NPC AI (which is deterministic from spline state + RNG) participates in rollback natively. See the [multiplayer design doc](../game-design/multiplayer.md) for the full rollback strategy and references.

For single-player and splitscreen/LAN (launch targets), rollback is unnecessary — direct sync is sufficient.

---

---

## Rejoin / Respawn on Track

When a racer respawns (after crash or DNF recovery), their `spline_t` must be reset to the nearest valid position:

```gdscript
func respawn_racer(slot: int, respawn_t: float):
    var racer = _get_racer(slot)
    racer.respawn_at_spline_t(respawn_t)
    lap_tracker.set_spline_t(slot, respawn_t)
```

The respawn `t` is provided by the nearest respawn point on the spline (see `tracks-and-splines.md` § Respawn Points). The racer's `last_cleared_waypoint` is adjusted to the waypoint immediately before the respawn `t`.

---

## EventBus Signals

| Signal | Payload | Fired When |
|---|---|---|
| `race_state_changed` | `state: int` | Any state transition |
| `race_countdown_tick` | `tick: int` | 3, 2, 1 |
| `race_countdown_go` | — | GO |
| `racer_cleared_waypoint` | `slot: int, waypoint_index: int` | Racer passes a waypoint |
| `racer_completed_lap` | `slot: int, lap: int, lap_time: float` | Racer finishes a lap |
| `racer_finished` | `slot: int, position: int` | Racer crosses finish line after all laps |
| `race_finished` | `finish_order: Array[int]` | All racers done or timeout |
| `race_results_ready` | `results: RaceResults` | Results screen data available |

---

## Results Data

```gdscript
class RaceResults:
    var track_name: String
    var total_laps: int
    var finish_order: Array[FinishEntry]

class FinishEntry:
    var slot: int
    var position: int
    var racer_name: String
    var total_time: float
    var best_lap_time: float
    var lap_times: Array[float]
    var dnf: bool
    var starting_grid: int
```

---

## Integration Summary

```
                        ┌──────────────────┐
                        │  RaceManager      │  Node, scene-level or autoload
                        │  (State Machine)  │
                        └──┬────┬────┬──────┘
                           │    │    │
              ┌────────────┘    │    └──────────────┐
              │                 │                   │
     ┌────────▼───┐   ┌────────▼────┐   ┌──────────▼─────┐
     │ InputBuffer │   │ LapTracker  │   │ ResultsBuilder │
     │ Manager     │   │ (spline_t,  │   │ (finish data)  │
     │             │   │  waypoints) │   │                │
     └─────────────┘   └─────────────┘   └────────────────┘
```

## File List

| File | Purpose |
|---|---|
| `systems/race/race_manager.gd` | State machine, physics loop, finish/timeout logic |
| `systems/race/lap_tracker.gd` | Per-racer spline_t, waypoint gating, lap increment |
| `systems/race/race_results.gd` | Result data class, builder |
| `systems/race/position_sorter.gd` | Live ranking sort each tick |
