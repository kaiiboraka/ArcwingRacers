# Input Buffer

**Location:** `systems/input/input_buffer.gd`
**Dependencies:** None
**Consumed by:** Pod physics (`Content/Scripts/pod/pod_controller.gd`), Race Manager, Replay system

---

## Data Structure

```gdscript
# input_buffer.gd
class_name InputBuffer
extends RefCounted

# ── Per-slot snapshot ────────────────────────────────────
struct InputSnapshot:
    var steering: float       # -1.0 .. 1.0
    var acceleration: float   #  0.0 .. 1.0
    var braking: float        #  0.0 .. 1.0
    var nose_pitch: float     # -1.0 .. 1.0
    var boost: bool
    var shield: bool
    var ability: bool
    var look_behind: bool
    var repair: bool
    var tilt: float           # -1.0 .. 1.0
```

The snapshot is a **fixed-size struct** — every field is the same size every tick. This is critical for record/replay (constant-size per-tick frames) and networking (predictable packet size).

---

## Slot Buffer

```gdscript
# Manages one slot's input pipeline.
class_name SlotBuffer
extends RefCounted

enum InputSource { LOCAL_PLAYER, AI, NETWORK_PEER, REPLAY, EMPTY }

var source: InputSource
var _buffer: InputSnapshot          # latest written state
var _pending: InputSnapshot         # written during frame, consumed on tick
var _consumed: InputSnapshot        # last tick's snapshot (for record)
var _previous: InputSnapshot        # tick before last (for edge detection)

# Called by input source (frame-rate).
func write(snapshot: InputSnapshot) -> void:
    _pending = snapshot

# Called by Race Manager (physics-tick rate).
func consume() -> InputSnapshot:
    _previous = _consumed
    _consumed = _pending
    _buffer = _pending
    return _consumed

func get_previous() -> InputSnapshot:
    return _previous
```

The double-buffer (`_pending` / `_consumed`) prevents a physics tick from reading a half-written frame. The write side runs at display frame rate; consume runs at physics tick rate (60 Hz).

---

## Input Buffer Manager

```gdscript
# Owned by Race Manager. Holds all slot buffers.
class_name InputBufferManager
extends RefCounted

const MAX_SLOTS := 16

var slots: Array[SlotBuffer]

func _init():
    slots.resize(MAX_SLOTS)
    for i in MAX_SLOTS:
        slots[i] = SlotBuffer.new()

func set_source(slot: int, source: SlotBuffer.InputSource) -> void:
    slots[slot].source = source

func write(slot: int, snapshot: InputSnapshot) -> void:
    slots[slot].write(snapshot)

func consume_all() -> Array[InputSnapshot]:
    var result: Array[InputSnapshot]
    result.resize(MAX_SLOTS)
    for i in MAX_SLOTS:
        result[i] = slots[i].consume()
    return result
```

The Race Manager calls `consume_all()` once per physics tick and passes the array to pod controllers.

---

## Live Side — Local Player Input

```gdscript
# Writes keyboard/gamepad state to the buffer each frame.
# Attached to the viewport or as an autoload.
class_name LocalInputWriter
extends Node

@export var slot_index: int = 0
var _buffer: InputBufferManager

func _ready():
    _buffer = RaceManager.input_buffers

func _process(_delta: float):
    var snap = InputSnapshot.new()
    snap.steering      = Input.get_axis(&"steer_left", &"steer_right")
    snap.acceleration  = 1.0 if Input.is_action_pressed(&"accelerate") else 0.0
    snap.braking       = 1.0 if Input.is_action_pressed(&"brake") else 0.0
    var pitch = Input.get_axis(&"pitch_up", &"pitch_down")
    snap.nose_pitch    = -pitch  # invert: down = positive in EP1R convention
    snap.boost         = Input.is_action_just_pressed(&"boost")
    snap.shield        = Input.is_action_pressed(&"shield")
    snap.ability       = Input.is_action_just_pressed(&"ability")
    snap.look_behind   = Input.is_action_just_pressed(&"look_behind")
    snap.repair        = Input.is_action_pressed(&"repair")
    snap.tilt          = Input.get_axis(&"tilt_left", &"tilt_right")
    _buffer.write(slot_index, snap)
```

**Key detail:** `_process()` (not `_physics_process()`) — input is sampled at frame rate, then consumed at physics rate. This avoids input being lost between physics ticks and lets the buffer decouple the two rates entirely.

---

## Local Player Edge Detection

Boost and ability use `is_action_just_pressed` in the writer, which means they fire once per press even if the physics tick hasn't consumed yet. This is correct — the writer is the gate. For replay, the recorded snapshot includes the edge, so replay playback writes `boost: true` for exactly one tick.

For actions that must stay active (shield, repair), the writer writes the held state every frame. The consumer sees it as long as the button is held.

---

## Replay Side — Record

```gdscript
# Ring buffer of all snapshots.
class_name RaceRecording
extends RefCounted

const SNAPSHOT_SIZE := 6 * 4 + 5 * 1  # 6 floats × 4 bytes + 5 bools × 1 byte = 29 bytes per slot
const SLOT_COUNT := 16
const FRAME_SIZE := SLOT_COUNT * SNAPSHOT_SIZE  # 464 bytes per tick

var _ring: PackedByteArray
var _capacity: int        # number of ticks stored
var _head: int = 0        # write position (bytes)
var _count: int = 0       # ticks written so far
var _total_ticks: int = 0 # total ticks recorded (for seeking)

func record(snapshots: Array[InputSnapshot]) -> void:
    var offset = _head
    for i in SLOT_COUNT:
        _ring.encode_float(offset, snapshots[i].steering);      offset += 4
        _ring.encode_float(offset, snapshots[i].acceleration);  offset += 4
        _ring.encode_float(offset, snapshots[i].braking);       offset += 4
        _ring.encode_float(offset, snapshots[i].nose_pitch);    offset += 4
        _ring.encode_float(offset, snapshots[i].tilt);          offset += 4
        _ring.encode_u8(offset, _pack_bools(snapshots[i]));     offset += 1
    _head = (_head + FRAME_SIZE) % (_capacity * FRAME_SIZE)
    if _count < _capacity:
        _count += 1
    _total_ticks += 1
```

## Replay Side — Playback

```gdscript
class_name ReplayPlayer
extends RefCounted

var _data: RaceRecording
var _current_tick: int = 0
var _buffer: InputBufferManager

func play() -> void:
    _current_tick = 0

func tick_forward() -> void:
    if _current_tick >= _data.total_ticks:
        return
    var frame = _data.read_frame(_current_tick)
    for i in frame.size():
        _buffer.write(i, frame[i])
    _current_tick += 1
```

Replay playback writes into the buffer as `InputSource.REPLAY`, which the consuming code treats identically to any other source.

---

## Network Serialization (Future)

Godot's [High-Level Multiplayer API](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) handles connection management (`ENetMultiplayerPeer`), property sync (`MultiplayerSynchronizer`), scene spawning (`MultiplayerSpawner`), and remote procedure calls (`@rpc`). The input buffer feeds into this system: each remote client serializes its own slot's buffer into a 29-byte packet and sends it to the host via `@rpc("any_peer", "unreliable_ordered")`. The host deserializes into the corresponding slot buffer and simulates. See the [multiplayer design doc](../game-design/multiplayer.md) for the full architecture and the [community guide](https://old.reddit.com/r/godot/comments/1lt0wdc/online_coopmultiplayer_guide_for_beginners_beyond/) for practical patterns.

```gdscript
# INPUT_PACKET = 29 bytes per slot (sent only for the player's own slot).
# Future: compress bools into a bitfield, reduce float precision to 8 bits.

func serialize(snapshot: InputSnapshot) -> PackedByteArray:
    var pba = PackedByteArray()
    pba.resize(SNAPSHOT_SIZE)
    var offset = 0
    pba.encode_float(offset, snapshot.steering);      offset += 4
    pba.encode_float(offset, snapshot.acceleration);  offset += 4
    pba.encode_float(offset, snapshot.braking);       offset += 4
    pba.encode_float(offset, snapshot.nose_pitch);    offset += 4
    pba.encode_float(offset, snapshot.tilt);          offset += 4
    pba.encode_u8(offset, _pack_bools(snapshot));     offset += 1
    return pba

func deserialize(data: PackedByteArray) -> InputSnapshot:
    var s = InputSnapshot.new()
    var offset = 0
    s.steering      = data.decode_float(offset);  offset += 4
    s.acceleration  = data.decode_float(offset);  offset += 4
    s.braking       = data.decode_float(offset);  offset += 4
    s.nose_pitch    = data.decode_float(offset);  offset += 4
    s.tilt          = data.decode_float(offset);  offset += 4
    _unpack_bools(data.decode_u8(offset), s);      offset += 1
    return s

func _pack_bools(s: InputSnapshot) -> int:
    return (int(s.boost) << 0) \
         | (int(s.shield) << 1) \
         | (int(s.ability) << 2) \
         | (int(s.look_behind) << 3) \
         | (int(s.repair) << 4)

func _unpack_bools(byte: int, s: InputSnapshot) -> void:
    s.boost       = bool(byte & (1 << 0))
    s.shield      = bool(byte & (1 << 1))
    s.ability     = bool(byte & (1 << 2))
    s.look_behind = bool(byte & (1 << 3))
    s.repair      = bool(byte & (1 << 4))
```

---

## Integration Summary

```
            ┌──────────────────┐
            │  LocalInput      │  _process() (60+ FPS)
            │  Writer          │
            └──────┬───────────┘
                   │ write()
            ┌──────▼───────────┐
            │  SlotBuffer[0]   │  double-buffered
            │  (pending)       │
            └──────┬───────────┘
                   │ consume()  ← Race Manager _physics_process() (fixed 60 Hz)
            ┌──────▼───────────┐
            │  InputSnapshot[] │  16 snapshots, one per slot
            └──────┬───────────┘
                   │
        ┌──────────┼──────────────┐
        │          │              │
  ┌─────▼────┐ ┌──▼───┐   ┌─────▼─────┐
  │Pod       │ │Race  │   │Race       │ ← record()
  │Physics   │ │Mgr   │   │Recording  │
  └──────────┘ └──────┘   └───────────┘
```

---

## File List

| File | Purpose |
|---|---|
| `systems/input/input_buffer.gd` | `InputSnapshot` struct, `SlotBuffer`, `InputBufferManager` |
| `systems/input/local_input_writer.gd` | Samples keyboard/gamepad → writes slot buffer |
| `systems/input/race_recording.gd` | Ring buffer record/playback |
| `systems/input/replay_player.gd` | Reads recording → writes slot buffer |
| `systems/input/network_input.gd` | (Future) serialize/deserialize for P2P |
