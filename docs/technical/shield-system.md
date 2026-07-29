# Shield System

**Location:** `systems/shield/shield_component.gd`
**Dependencies:** ManaComponent, EventBus
**Consumed by:** Pod damage pipeline, HUD

---

## ShieldComponent

A per-pod Area3D that serves as both the collision volume and the shield controller. One per racer.

```gdscript
# shield_component.gd
class_name ShieldComponent
extends Area3D

enum Direction { FRONT, BACK, LEFT, RIGHT }

# ── Exports (tunable) ──
@export var mana_drain_rate: float = 8.0          # per second while held
@export var parry_window_frames: int = 10          # at 60fps ≈ 167ms
@export var shield_strength: float = 1.0           # multiplier: higher = less mana lost per hit
@export var damage_to_mana_base: float = 0.5       # base mana lost per damage blocked (divided by strength)
@export var parry_refund: float = 15.0             # mana restored on successful parry
@export var shield_radius: float = 3.0             # distance from pod origin
@export var stick_deadzone: float = 0.5
@export var tween_duration: float = 0.15
@export var break_stun_duration: float = 1.5       # seconds of spin-out on break
@export var min_mana_to_raise: float = 10.0        # can't re-raise below this

# ── State ──
var is_active: bool = false
var current_direction: Direction = Direction.FRONT
var _mana: ManaComponent
var _parry_timer: Timer
var _parry_active: bool = false
var _broken: bool = false
var _target_angle: float = 0.0
```

### Parry Window Timer

```gdscript
func _ready():
    _mana = _find_mana_component()
    _parry_timer = Timer.new()
    _parry_timer.one_shot = true
    _parry_timer.timeout.connect(_on_parry_window_closed)
    add_child(_parry_timer)
    collision_layer = 0   # doesn't collide with world
    collision_mask = 0     # set dynamically per ability layer
    area_entered.connect(_on_hit)
```

---

## Activation & Direction

Shield is toggled by holding the shield button. Direction is read from the right analog stick.

### Quadrant Mapping

The stick's full 360° is divided into four 90° quadrants. With up/north at 0°:

```
       Front
   -45°  |  45°
      \  |  /
  Left  --+--  Right
      /  |  \
  -135°  |  135°
       Back
```

```gdscript
func set_active(active: bool):
    is_active = active
    if active and not _broken:
        _on_shield_raised()
    elif not active:
        _on_shield_lowered()

func _on_shield_raised():
    visible = true
    _parry_active = true
    # Shield strength extends parry window slightly
    var frames = int(parry_window_frames * (1.0 + shield_strength * 0.1))
    _parry_timer.start(float(frames) / 60.0)

func _on_shield_lowered():
    visible = false
    _parry_active = false
    _parry_timer.stop()

func on_stick_input(stick: Vector2):
    if stick.length() < stick_deadzone:
        return
    var angle = atan2(stick.x, -stick.y)   # up = 0°, right = -90°
    var dir = _angle_to_direction(angle)
    if dir != current_direction:
        current_direction = dir
        _tween_to_direction(dir)
```

### Angle to Quadrant

```gdscript
func _angle_to_direction(angle: float) -> Direction:
    # angle in radians, up = 0°, clockwise positive
    var deg = rad_to_deg(angle)
    if deg > -45.0 and deg <= 45.0:
        return Direction.FRONT
    elif deg > 45.0 and deg <= 135.0:
        return Direction.RIGHT
    elif deg > -135.0 and deg <= -45.0:
        return Direction.LEFT
    else:
        return Direction.BACK
```

### Elastic Tween

When the direction changes, the shield tweens to its new position with bounce, not a snap:

```gdscript
func _tween_to_direction(dir: Direction):
    match dir:
        Direction.FRONT: _target_angle = 0.0
        Direction.RIGHT:  _target_angle = -PI / 2.0
        Direction.BACK:   _target_angle = PI
        Direction.LEFT:   _target_angle = PI / 2.0

    var tween = create_tween()
    tween.set_trans(Tween.TRANS_ELASTIC)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "rotation:y", _target_angle, tween_duration)
```

The CollisionShape3D child is offset forward (local +Z) by `shield_radius`. Rotating the Area3D around Y moves the collision volume to the correct side.

---

## Continuous Mana Drain

Shield drains mana every frame while active. This is input-driven (the player holds or releases the button), so `_process` is appropriate — not every system needs a discrete timer.

```gdscript
func _process(delta: float):
    if not is_active or _broken:
        return
    if not _mana.spend(mana_drain_rate * delta):
        _break_shield()
```

Regen pauses during shield because `_process` drain runs every frame. The ManaComponent's regen timer still fires, but `spend()` keeps the pool from building up as long as drain ≥ regen.

---

## Hit Detection & Parry

The shield's Area3D detects incoming projectiles and abilities via `area_entered`.

```gdscript
func _on_hit(hit_area: Area3D):
    if not is_active or _broken:
        return

    var damage = _get_damage(hit_area)

    if _parry_active:
        _on_parry(damage)
    else:
        _on_block(damage)

func _on_parry(damage: float):
    # Successful parry: no mana cost, refund instead
    _mana.restore(parry_refund)
    EventBus.shield_parried.emit(current_direction, damage)
    # Visual: bright flash, brief shield pulse
    _parry_active = false   # only first hit parries

func _on_block(damage: float):
    # Blocked: mana cost proportional to damage, reduced by shield strength
    var mana_cost = damage * damage_to_mana_base / shield_strength
    if not _mana.spend(mana_cost):
        _break_shield()
        return
    EventBus.shield_blocked.emit(current_direction, damage)
    # Visual: shield hit effect
```

### Parry Window

The parry window opens when the shield is initially raised and closes after `parry_window_frames`. Only the first hit within the window counts as a parry — subsequent hits are normal blocks.

```gdscript
func _on_parry_window_closed():
    _parry_active = false
```

This rewards proactive reads — raising the shield just before an incoming attack. Holding it up indefinitely only gives normal blocks, not parries.

---

## Shield Break

When mana hits zero during active shielding:

```gdscript
func _break_shield():
    _broken = true
    is_active = false
    visible = false
    _parry_active = false
    _parry_timer.stop()
    EventBus.shield_broken.emit()
    # Request pod stun — pod_controller listens for this
    # Triggers a brief spin-out (handling disabled, velocity perturbed)

func _recover():
    _broken = false

# Called by ManaComponent when mana recovers above threshold after break
func _on_mana_recovered():
    if _broken and _mana.current_mana >= min_mana_to_raise:
        _recover()
```

The pod controller listens for `shield_broken` and enters a stun state — handling inputs are ignored, velocity is perturbed for a spin-out effect, controlled by `break_stun_duration`.

---

## Signals

| Signal | Args | When |
|---|---|---|
| `shield_raised` | — | Shield activated |
| `shield_lowered` | — | Shield deactivated |
| `shield_blocked(direction, damage)` | Direction, float | Hit blocked normally |
| `shield_parried(direction, damage)` | Direction, float | Hit parried (first hit in parry window) |
| `shield_broken` | — | Mana depleted while active → stun |
| `shield_direction_changed(direction)` | Direction | Shield rotated to new quadrant |

---

## Integration

### Input
```gdscript
# In pod_controller.gd input handling:
var shield_held: bool = Input.is_action_pressed("shield")
var stick: Vector2 = Input.get_vector("shield_left", "shield_right", "shield_up", "shield_down")
shield_component.set_active(shield_held)
shield_component.on_stick_input(stick)
```

### HUD
```gdscript
# Shield direction indicator (around mana bar):
shield_component.direction_changed.connect(_on_shield_dir_changed)
shield_component.shield_blocked.connect(_on_shield_hit_feedback)
shield_component.shield_parried.connect(_on_parry_feedback)
```

### ManaComponent
The `ManaComponent` on the same pod is read directly. After a shield break, the shield listens for mana recovery above `min_mana_to_raise` to re-enable.

---

## Visual

- **In-world:** A 3D mesh (oval/rect hard-light barrier) parented under the ShieldComponent Area3D. Rotates with the collision volume. Translucent material with a slight glow.
- **UI:** A ring or arc indicator around the mana bar showing which direction the shield currently faces. Updates on `shield_direction_changed`.

---

## Multiplayer Considerations

Shield state is part of the local pod simulation under rollback:

- **Active + direction** are input-derived (shield button held + stick), so they're deterministic from the input snapshot. Each `_rollback_tick()` samples the buffered input and recomputes shield state.
- **Parry vs block** is frame-perfect — the rollback re-simulates the exact frame window. If a hit arrives on the server at a different tick than it predicted locally, the server's determination wins.
- **Shield break + stun** is a state effect — the stun duration is a fixed stat, so it resolves deterministically under rollback.
- The collision layer/mask for the shield Area3D only includes ability projectiles, not vehicle bodies or track geometry.

---

## Data-Driven Stats (VehicleStats)

These values come from the pod's component/upgrade system, same as EP1R stat slots:

| Stat Key | Default | Component Effect |
|---|---|---|
| `shield_strength` | 1.0 | +0.2 per tier — less mana lost per hit blocked, slightly wider parry window |
