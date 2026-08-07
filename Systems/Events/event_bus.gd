extends Node

## Central game-event relay (ADR 0002). GDScript autoload defining every game
## signal as a strongly-typed declaration. Systems emit state changes; UI reads by
## subscribing in _ready(). UI never references systems directly (ADR 0001).
##
## Naming: past tense for state changes (speed_updated, boost_ended); boost event
## names follow pod-handling-and-boost.md (matches the pod's real state machine);
## boost_charge_updated comes from ADR 0002.

# Pod → HUD / systems
## Current pod speed in mph plus its fraction of max_speed (0..1, may exceed 1 during boost).
signal speed_updated(speed_mph: float, speed_fraction: float)

## Pod boost state (BoostState enum). Emitted on every state change.
signal boost_state_changed(state : PodController.BoostState)

## Boost charge gauge 0-100 (ADR 0002). Emitted when the integer percent changes.
signal boost_charge_updated(charge_percent: float)

## Boost heat gauge 0-100. Emitted when the integer percent changes (incl. cooling).
signal boost_heat_updated(heat_pct: float)

# Boost transitions
signal boost_ready()
signal boost_started()
signal boost_ended()
signal overheat_started()
signal overheat_ended()

# Repair
## Hold-to-repair entered / exited. Repair is NOT a boost state (it can overlap with
## OVERHEAT, so it gets its own channel) — HUD subscribes to tint the light.
signal repair_started()
signal repair_ended()

# Race (RaceManager → HUD). Naming follows technical/race-manager.md.
## Every RaceManager.State transition (PREGAME/COUNTDOWN/RACING/FINISHED).
signal race_state_changed(state : int)
## PREGAME complete — the pod is on the grid and locked; the intro can start.
signal race_pregame_ready()
## Countdown numerals 3, 2, 1 (one per second).
signal race_countdown_tick(tick : int)
## GO — countdown over, controls unlocked, race clock just started.
signal race_countdown_go()
## RACING entered (the running clock begins; countdown _go_ already fired).
signal race_started()
## A lap was completed: lap number (1-based), its time, and the new best lap (INF→unset).
signal race_lap_completed(lap : int, lap_time : float, best_lap : float)
## Race over: total elapsed time and all completed lap times.
signal race_finished(total_time : float, lap_times : Array)
