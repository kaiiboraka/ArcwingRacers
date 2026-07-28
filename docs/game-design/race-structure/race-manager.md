# Race Manager

## What a Race Is

A race is a contest of N racers completing L laps on a track defined by a spline. The first racer to complete all laps wins; remaining positions are determined by their progress when the first racer finishes, or when a global timeout expires.

## State Machine

```
PREGAME → COUNTDOWN → RACING → FINISHED → RESULTS
```

Each state is owned and driven by the Race Manager — the single authoritative simulation for the race. All visual/audio output is driven by EventBus signals fired at state transitions.

| State | What Happens |
|---|---|
| PREGAME | Racers placed on grid, controls locked, camera intro plays |
| COUNTDOWN | 3-2-1 tick, takeoff boost window |
| RACING | Physics ticks, AI ticks, lap/position checks, collision handling |
| FINISHED | All racers finished or timeout, results computed |
| RESULTS | Results displayed, player advances to garage/track select |

## Position Tracking

Every physics tick, position is recomputed:

1. Each racer projects their world position onto the main spline → `spline_t` (0.0 to 1.0)
2. Position rank = sort racers by `(lap_count, spline_t)` descending
3. The leader is the racer with the highest `lap_count`, then highest `spline_t`

This is a **continuous** position — it doesn't snap to discrete "who crossed the line first." It updates every tick, so the HUD always shows live positions.

## Lap Counting (Waypoint Gating)

Laps are tracked via **waypoints** — discrete positions on the main spline at strategic choke points (before splits, after merges, at start/finish). Waypoints must be cleared in ascending index order.

- A racer clears a waypoint when their `spline_t` passes the waypoint's `spline_t - activation_radius`
- Backward movement or crossing waypoints out of order has no effect
- A lap is complete when:
  1. All waypoints in the current loop have been cleared
  2. The racer's `spline_t` wraps past the start/finish line

**Why waypoint gating instead of just line crossings:** Branching paths mean racers can skip parts of the main spline. Waypoints at split/join points let the system validate that the racer followed a valid path around the track. A racer on an alternate path may skip some main-spline waypoints — that's fine, the next waypoint index is still tracked by ascending order.

## Finish Conditions

| Condition | Behavior |
|---|---|
| First racer completes all laps | Race continues for remaining racers, but lap counter stops. As they cross the finish line, they fill remaining positions. |
| Timeout (TBD duration) | Race ends. Unfinished racers are DNF (Did Not Finish), sorted by last known position. |
| All racers finished | Race ends immediately; no need for timeout. |
| Player DNF (crashed, eliminated) | If no respawns remain, player is DNF. Race continues (AI races to finish). |

### Number of Racers

Configurable per race: 2–16. Filled in order: local players → network peers → AI bots.

## Race Results

When all racers have finished or the timeout fires:

| Data | Description |
|---|---|
| Finish order | Position 1..N by crossing order after all laps complete |
| Total race time | Per racer, from GO to finish (or DNF marker) |
| Best lap time | Per racer, fastest single lap |
| Lap times | Array of each lap time per racer |
| DNF flag | True if racer didn't finish |
| Grid position | Starting grid slot for reference |

Results fire on EventBus for the UI/results screen.

## Timeout

A global race timeout prevents infinite races. If any racer hasn't finished by the timeout, the race ends and unfinished racers are DNF. Timeout scales with lap count and estimated track length. Baseline: 2× the leader's estimated completion time.

## AI Position Awareness

AI does not use the Race Manager's position data. AI decisions use the spline's `project()` function and lookahead, not the rank array. The Race Manager's position is for HUD display and finish order only. This prevents oscillation where AI tries to respond to its own position.

## Technical Reference

See `docs/technical/race-manager.md` for implementation — state machine transitions, rejoin/respawn, lap tracker algorithm, timeout logic.
