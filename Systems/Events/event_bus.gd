extends Node

## Central game-event relay (ADR 0002). GDScript autoload defining every game
## signal as a strongly-typed declaration. Systems emit state changes; UI reads by
## subscribing in _ready(). UI never references systems directly (ADR 0001).
##
## Naming: past tense for state changes (speed_updated, boost_ended); boost event
## names follow pod-handling-and-boost.md (matches the pod's real state machine);
## boost_charge_updated comes from ADR 0002.

# Pod → HUD / systems
## Current pod speed in m/s plus its fraction of max_speed (0..1, may exceed 1 during boost).
signal speed_updated(speed_mps: float, speed_fraction: float)

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
