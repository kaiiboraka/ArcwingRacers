# Input Buffer

## Design Intent

The input buffer is the single abstraction that decouples input sources from the race simulation. Every racer slot (player, AI, or network peer) writes to the same buffer format, and the pod physics reads from it identically. This is the foundation that makes multiplayer "free" — any slot can be any input type without branching code.

---

## Why a Buffer Instead of Direct Input

Direct `Input.is_action_pressed()` reads during physics ticks cause three problems:

1. **Multiplayer impossible** — network peers can't press your keyboard. You'd need `if` branches everywhere for local/AI/network.
2. **Determinism gap** — replay and network sync need the exact same input sequence replayed. Direct input can't be recorded.
3. **Input timing** — physics ticks may not align with frame input events. A buffer decouples the variable-rate input layer from the fixed-timestep simulation.

The solution: a per-slot input buffer that records the latest input state and is consumed once per physics tick.

---

## Slot Model

A race defines up to 16 slots. Each slot has:

```
slot.input_buffer  — the buffer the physics reads from
slot.input_source  — who writes to it:
    • LOCAL_PLAYER  — keyboard/gamepad
    • AI            — AI decision system
    • NETWORK_PEER  — deserialized remote input (future)
    • REPLAY        — recorded input playback
    • EMPTY         — no racer, slot unused
```

The Race Manager owns the slot array. It assigns input sources at race start and reads all buffers each tick.

---

## What the Buffer Carries

The buffer stores the current state of every control the pod needs each physics tick:

| Field | Type | Range | Description |
|---|---|---|---|
| steering | float | -1.0 to 1.0 | Left analog horizontal. Negative = left, positive = right |
| acceleration | float | 0.0 to 1.0 | Accelerator pedal. 0 = released, 1 = full |
| braking | float | 0.0 to 1.0 | Brake pedal |
| nose_pitch | float | -1.0 to 1.0 | Vertical analog. Negative = nose down (boost charge, needs full deflection within the charge deadzone), positive = nose up (air control) |
| boost | bool | | Activate boost |
| shield | bool | | Shield held (drains mana while true) |
| ability | bool | | Fire ability |
| look_behind | bool | | Toggle rear-view camera |
| repair | bool | | Hold to repair |
| tilt | float | -1.0 to 1.0 | Right analog horizontal. 90° ship tilt |

These are the **consumed** values — what the physics actually reads. The buffer is not concerned with how they were produced (keyboard, gamepad stick, AI decision, network packet).

---

## Input Sources

### Local Player
Keyboard/gamepad input is sampled each frame and written to the buffer. The `Input` singleton reads are mapped to the buffer fields via the controls mapping (see `controls-and-camera.md`). Raw stick values pass through; digital buttons (boost, shield, ability) are debounced or edge-detected as needed.

### AI
The AI decision system writes to the same buffer fields. Rather than simulating a virtual gamepad, AI directly sets `steering`, `acceleration`, `boost`, etc. based on its target position on the spline and its boost/brake decisions (see `docs/game-design/tracks/track-layout.md`).

### Network Peer (Future)
Remote input arrives as a small packet containing the same buffer fields. The packet is deserialized directly into the buffer on the host. The host is authoritative; remote inputs are just suggestions that the host simulation applies.

### Replay
A recorded sequence of buffer snapshots is played back tick-by-tick. The replay system writes each frame's snapshot into the buffer in sequence.

---

## Record / Replay

Every tick, the entire buffer state for all slots is recorded into a ring buffer:

```
race_recording[race_tick] = snapshot_of_all_slot_buffers
```

This recording is used for:
- **Replays** — watch a race from any camera after finishing
- **Ghost racers** — time trial ghosts are recorded inputs played back
- **Debugging** — reproduce a bug by replaying the exact input sequence

Replays are stored as compact binary data (not JSON) — each snapshot is a fixed-size struct, so seeking to any tick is O(1).

---

## Why Not Just Use Godot's Input Map

Godot's Input Map is designed for frame-by-frame polling, not tick-aligned simulation. The buffer layer exists because:
- AI and network inputs don't go through the Input Map at all
- Record/replay needs tick-aligned snapshots, not frame-variable reads
- The buffer provides a clean seam for netcode (serialize buffer ↔ serialize input packet)

---

## Technical Reference

See `docs/technical/input-buffer.md` for the implementation — data structure, tick consumption, record/replay format, and serialization.
