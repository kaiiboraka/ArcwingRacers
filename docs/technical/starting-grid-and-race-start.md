# Starting Grid & Race Start

---

## Starting Grid (`starting_line.gd`)

**Location:** `Content/Scripts/starting_line.gd`
**Scene:** `Content/Scenes/starting_line.tscn`
**Dependencies:** None (self-contained `@tool` script)

### Grid Layout Math

```
GRID_COLS = 4
MAX_RACER_SLOTS = 16

Position_N where N = 1..16
    col = (N-1) % 4      → 0,1,2,3
    row = (N-1) / 4      → 0,1,2,3
    position = Vector3(
        col * RACER_POSITION_WIDTH,     # X: 0, 15, 30, 45
        RACER_POSITION_MARKER_HEIGHT,   # Y: 0.2 (slightly above ground)
        -row * RACER_ROWS_SPACING       # Z: 0, -25, -50, -75
    )
```

Position_01 is at the origin (0, 0.2, 0) — the front-left slot. Subsequent positions fill right-to-left across columns, then back row-by-row.

### Exported Properties

| Property | Default | Range | Description |
|---|---|---|---|
| `RACER_POSITION_WIDTH` | 15.0 | 0–100 | Horizontal spacing between columns |
| `RACER_ROWS_SPACING` | 25.0 | 0–100 | Vertical (Z) spacing between rows |
| `RACER_POSITION_MARKER_HEIGHT` | 0.2 | 0–10 | Y offset for the Marker3D position |
| `racer_count` | 8 | 0–16 | Number of active positions (visible ground markers) |

### Public API

```gdscript
var start_positions: Array[Marker3D]         # Ordered array of all Marker3D children

func get_start_positions() -> Array[Marker3D]  # Returns a duplicate
func place_racers(racers: Array[Node3D])        # Moves each racer to its grid position
```

### Rebuild Logic

The `@tool` script auto-generates the 16 Marker3D positions on property change or `_ready()`:

1. Scans existing children — reuses any `Position_NN` Marker3D found, frees unknown children
2. Creates missing Marker3D nodes, sets `owner` to edited scene root
3. Positions each marker by column/row math
4. Adds a `Sprite3D` child (`GroundMarker`) with the starting position texture for visible positions (index < `racer_count`)
5. Positions beyond `racer_count` have no Sprite3D (hidden on ground)

### Placement

`place_racers(racers)` sets each racer's `global_position` to the corresponding `start_positions[i]`. The racer count is clamped to the number of available positions:

```gdscript
var count = min(racers.size(), start_positions.size())
for i in count:
    racers[i].global_position = start_positions[i].global_position
```

---

## Race Start Sequence (Race Manager)

**Location:** `systems/race/race_manager.gd`

### State Machine

```
PREGAME → COUNTDOWN → RACING
```

### PREGAME State

Triggered when the race scene loads. Duration: ~2 seconds.

```gdscript
func _enter_pregame():
    # 1. Place racers on grid
    var grid = track.starting_grid
    grid.place_racers(all_racers)

    # 2. Assign grid positions based on qualifying order
    for i in racer_count:
        var qualifier = qualifying_order[i]
        var slot = assign_grid_slot(qualifier, i)
        racers[slot].global_position = grid.start_positions[i].global_position

    # 3. Lock all racer controls
    for racer in all_racers:
        racer.set_input_locked(true)

    # 4. Fire pregame-ready signal
    EventBus.race_pregame_ready.emit()

    # 5. Start camera intro sequence (sweep from behind grid to front)
    camera_controller.play_intro_sequence()

    # 6. Transition after intro completes
    await camera_controller.intro_finished
    transition_to(State.COUNTDOWN)
```

**Grid slot assignment** maps qualifying position to grid slot number:

```gdscript
func assign_grid_slot(qualifier_index: int, grid_position: int) -> int:
    # Qualifier 0 (pole) → grid position 0 (front row, left)
    # Qualifier 1 → grid position 1 (front row, second)
    # etc.
    return grid_position
```

Straight mapping: the Nth qualifier gets grid position N. No snake/alternating pattern — front row is the fastest qualifiers, back row the slowest.

### COUNTDOWN State

Duration: exactly 3 seconds (timed via `SceneTreeTimer`).

```gdscript
func _enter_countdown():
    countdown_ticks = [3, 2, 1]
    current_tick = 0
    _tick_countdown()

func _tick_countdown():
    if current_tick < countdown_ticks.size():
        var number = countdown_ticks[current_tick]
        EventBus.race_countdown_tick.emit(number)
        # Visual: huge number on screen with screen shake
        # Audio: beep at note F-sharp (3), D (2), A (1)

        get_tree().create_timer(1.0).timeout.connect(_tick_countdown)
        current_tick += 1
    else:
        _go()

func _go():
    EventBus.race_countdown_go.emit()
    # Audio: distinct GO sound
    # Visual: "GO!" text flash

    for racer in all_racers:
        racer.set_input_locked(false)
        racer.check_takeoff_boost()

    transition_to(State.RACING)
```

**Timing note:** The timer is `SceneTree.create_timer(1.0)` — one second per tick. Not physics-tick dependent. Must be precise enough that the takeoff boost window is consistent across frame rate variations.

### Visual & Audio Events Fired

```gdscript
# EventBus signals
signal race_pregame_ready            # Intro sequence can start
signal race_countdown_tick(tick: int) # 3, 2, 1
signal race_countdown_go              # GO
```

UI layer listens for these to display countdown numbers, camera intro, etc.

---

## Takeoff Boost

### Timing Check

The takeoff boost check fires on the first physics tick after GO is emitted:

```gdscript
# Inside pod_controller.gd (or a race_start_manager)
var _countdown_released := false
var _countdown_held := false
var _takeoff_boost_active := false

func check_takeoff_boost():
    # Called on first physics frame after countdown
    _takeoff_boost_active = _countdown_held and _countdown_released

func _input(event):
    if race_manager.state == RaceManager.State.COUNTDOWN:
        if Input.is_action_just_pressed(&"accelerate"):
            _countdown_held = true
        if Input.is_action_just_released(&"accelerate"):
            _countdown_released = true

func _physics_process(_delta):
    if _takeoff_boost_active:
        # Apply full boost thrust for a fixed duration (~1.5s)
        apply_takeoff_boost()
        _takeoff_boost_active = false
```

**Conditions for success:**
1. Accelerator was **held** at some point during countdown (`_countdown_held = true`)
2. Accelerator was **released** at some point during countdown (`_countdown_released = true`)
3. The release followed the hold — order matters

**Why this works in EP1R:** The announcer's "GO" fades in over ~150ms. The player sees the fade, releases the accelerator as the GO appears, then re-presses. The game checks: "was accelerator held during countdown?" and "was accelerator released since the countdown ended?" If both are true on the first post-GO frame, full boost activates.

### Implementation Notes

- The check is **not** frame-timing-sensitive — it doesn't measure how many milliseconds between release and re-press. It only checks that the accelerator was pressed and released at some point during the countdown phase, then re-pressed after GO.
- The boost duration on takeoff is shorter than a normal boost (~1.5s vs 3–5s) but provides the same thrust multiplier.
- No heat is generated during takeoff boost (in EP1R the heat bar starts empty regardless).
- AI racers have a difficulty-scaled success rate for takeoff boost (easy AI: 10%, medium: 50%, hard: 90%).

### AI Takeoff Boost

```gdscript
# AI decision system
func _on_countdown_start():
    ai_countdown_start_time = Time.get_ticks_usec()

func _on_go():
    if ai_should_takeoff_boost():
        # Simulate the hold-release-repress pattern
        apply_takeoff_boost()
    else:
        # Normal acceleration
        pass

func ai_should_takeoff_boost() -> bool:
    var roll = randf()
    match ai_difficulty:
        AI_Difficulty.EASY:   return roll < 0.10
        AI_Difficulty.MEDIUM: return roll < 0.50
        AI_Difficulty.HARD:   return roll < 0.90
```

---

## Locked Controls During Countdown

During PREGAME and COUNTDOWN, pod controllers must ignore all input from the buffer:

```gdscript
# pod_controller.gd
var input_locked := false

func set_input_locked(locked: bool):
    input_locked = locked

func _physics_process(_delta: float):
    if input_locked:
        return  # Skip all physics input processing
    process_input(buffers[my_slot])
```

This is distinct from the pod being frozen in place — during PREGAME, the pod is at its grid position with physics disabled or position forced. Locked controls only prevent the input from affecting behavior. The pod can still visually idle (engine hum, thruster flicker).

---

## Integration Summary

```
Race Manager
    │
    ├── PREGAME: place_racers() on grid, lock controls, play intro
    │
    ├── COUNTDOWN: emit 3-2-1 ticks (1s each), track accelerator state
    │
    └── GO: unlock controls, check_takeoff_boost(), transition to RACING

StartingLine (@tool)
    │
    ├── Auto-generates 16 Marker3D positions
    ├── Responds to editor property changes
    └── Public API: get_start_positions(), place_racers()

Pod Controller
    │
    ├── input_locked flag suppresses buffer reading during pre-race
    └── check_takeoff_boost() applies boost thrust on first post-GO tick
```

## File List

| File | Purpose |
|---|---|
| `Content/Scripts/starting_line.gd` | `@tool` script, auto-generates 4×4 grid of Marker3D positions |
| `Content/Scenes/starting_line.tscn` | Reusable scene, instances 16 positions with ground sprites |
| `Content/Textures/starting_position.png` | Ground marker sprite for active grid slots |
| `systems/race/race_manager.gd` | State machine (PREGAME → COUNTDOWN → RACING) |
| `systems/race/takeoff_boost.gd` | (Optional extracted module) countdown input tracking + boost check |
