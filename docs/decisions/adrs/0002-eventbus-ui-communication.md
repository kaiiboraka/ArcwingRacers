# ADR 0002: UI–System Communication via EventBus

## Status
Accepted

## Context
The four-pillar architecture (ADR 0001) mandates that `ui/` never calls into `systems/` directly. UI needs to display gameplay state (speed, lap, position, heat) and the player needs to trigger gameplay actions (pause, activate ability, navigate menus) from UI. Without a communication layer, these two requirements conflict.

A generic EventBus addon cannot know what signals the game needs — it would be a string-keyed relay with no type safety. The hyper-specific signal contracts (what events exist, what data they carry) are inherently project-scoped and belong in systems.

## Decision
Place the EventBus under `systems/events/event_bus.gd` as an autoload. It is a GDScript `Node` that defines every game signal as a strongly-typed Godot signal declaration:

```gdscript
extends Node

# Race events (system → UI / system → system)
signal race_started(countdown_seconds: float)
signal lap_completed(racer_id: int, lap: int, total_laps: int)
signal racer_finished(racer_id: int, position: int, race_time: float)
signal racer_crashed(racer_id: int)
signal position_changed(racer_id: int, position: int)

# Boost/heat events
signal boost_activated(racer_id: int)
signal boost_overheat(racer_id: int)
signal boost_charge_updated(racer_id: int, charge_percent: float)

# UI request events (UI → system — "call down, signal up")
signal pause_requested()
signal ability_activated(racer_id: int, ability_name: String)
signal race_restart_requested()
```

Two communication patterns:
1. **UI reads** — Systems emit state-change signals on the EventBus. UI subscribes in `_ready()` and updates its display. UI never polls or queries systems.
2. **UI writes** — Player input in UI intended to change gameplay state fires a request signal on the EventBus. The owning system listens and performs the mutation.

Strongly typed signals give editor autocomplete and compile-time checking. No string keys, no magic.

## Consequences
- **Positive:** UI can be reworked, themed, or replaced without touching game logic.
- **Positive:** Systems never need to know which UI elements exist.
- **Positive:** Autocomplete works — no string-keyed dispatch.
- **Positive:** Lives in `systems/` where signal contracts are designed and maintained alongside the systems that own them.
- **Tradeoff:** Signal-heavy code can be harder to follow than direct calls. Consistent naming conventions (past tense for state changes, `_requested` suffix for UI commands) mitigate this.
- **Tradeoff:** EventBus becomes a coupling point — all event definitions in one file. Adding a new event requires touching the bus. This is acceptable because the bus is the explicit coupling layer, not hidden coupling scattered across files.
