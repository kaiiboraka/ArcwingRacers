# Mana System

**Location:** `systems/mana/mana_component.gd`
**Dependencies:** VehicleStats (component data), EventBus
**Consumed by:** Shield system, Ability system, HUD

---

## ManaComponent

A per-pod node that owns the mana pool. One `ManaComponent` per racer.

```gdscript
# mana_component.gd
class_name ManaComponent
extends Node

# ── Exports (fed from VehicleStats) ──
@export var max_mana: float = 100.0
@export var regen_tick_interval: float = 0.5    # seconds between regen ticks
@export var regen_per_tick: float = 1.0          # mana restored per tick

# ── State ──
var current_mana: float = 100.0
var regen_timer: Timer
var regen_enabled: bool = true   # false while shield active, etc.
```

### Timer-Driven Regen

Regen fires discretely on a Timer, not continuous `_process`. This is critical for:

- **Determinism** — each tick is a discrete event. Rollback re-simulates N ticks, not drifted accumulated delta.
- **Network sync** — tick-based regen is trivial to replicate in rollback. The server/state authoritatively knows "tick X fired, restore Y mana."
- **Testability** — advance the timer, assert mana increased by exactly `regen_per_tick * ticks_elapsed`.
- **Game feel** — readable "ticks" of mana restoration. Players learn the rhythm.

```gdscript
func _ready():
    regen_timer = Timer.new()
    regen_timer.wait_time = regen_tick_interval
    regen_timer.one_shot = false
    regen_timer.timeout.connect(_on_regen_tick)
    add_child(regen_timer)
    regen_timer.start()

func _on_regen_tick():
    if not regen_enabled:
        return
    current_mana = min(current_mana + regen_per_tick, max_mana)
    _emit_state()
```

### Public API

```gdscript
# Attempt to spend mana. Returns false if insufficient.
func spend(amount: float) -> bool:
    if current_mana < amount:
        return false
    current_mana -= amount
    _emit_state()
    return true

# Restore mana (pickup, parry, regen). Clamped to max.
func restore(amount: float):
    current_mana = min(current_mana + amount, max_mana)
    _emit_state()

# Current fraction 0.0..1.0 for UI bars.
func get_fraction() -> float:
    return current_mana / max_mana

func _emit_state():
    mana_changed.emit(current_mana, max_mana)
    if current_mana <= 0.0:
        mana_depleted.emit()
```

### Signals

| Signal | Args | When |
|---|---|---|
| `mana_changed(current, max)` | float, float | Any spend/restore/regen tick |
| `mana_depleted` | — | `current_mana` reaches 0 |
| `mana_restored` | float | Successful parry refund |

---

## Mana Crystal Pickup

**Scene:** `content/pickups/mana_crystal.tscn`
**Node tree:**
```
ManaCrystal (Area3D)
├── CollisionShape3D (trigger)
├── Sprite3D (billboarded, animated)
├── RespawnTimer (Timer)
└── GlowLight (OmniLight3D, optional)
```

### Data Resource (`ManaCrystalResource`)

All crystal data lives in a custom Resource, not on the scene node. This keeps data independent of the scene — you can reuse the same resource across different scenes, swap presets in the inspector, and never lose data to scene corruption.

```gdscript
# Content/Scripts/Data/mana_crystal_resource.gd
class_name ManaCrystalResource
extends Resource

enum CrystalSize { SMALL, LARGE, SUPER }

@export var crystal_size: CrystalSize = CrystalSize.SMALL
@export var display_name: String = "Small Crystal"
@export var mana_value_percent: float = 0.05
@export var respawn_time: float = 8.0
@export var sprite: Texture2D
```

**Presets on disk** (`Content/Data/pickups/`):

| File | `crystal_size` | `mana_value_percent` | `respawn_time` |
|---|---|---|---|
| `mana_crystal_small.tres` | SMALL | 0.05 (5%) | 8s |
| `mana_crystal_large.tres` | LARGE | 0.20 (20%) | 15s |
| `mana_crystal_super.tres` | SUPER | 1.0 (100%) | 45s |

Values lean small deliberately — players want to collect many crystals, not fill from one. Large and Super are route-knowledge rewards.

### Pickup Logic

```gdscript
# mana_crystal.gd
class_name ManaCrystal
extends Area3D

@export var crystal_data: ManaCrystalResource

var _is_collected: bool = false
var _override_percent: float = -1.0   # -1 = use crystal_data default

# ── Initialization ──────────────────────────────────────

func _ready():
    body_entered.connect(_on_collected)
    if crystal_data:
        _apply_data()

func _apply_data():
    sprite.texture = crystal_data.sprite
    respawn_timer.wait_time = crystal_data.respawn_time

func _get_mana_percent() -> float:
    return _override_percent if _override_percent >= 0.0 else crystal_data.mana_value_percent

# ── Pickup Logic ────────────────────────────────────────

func _on_collected(body: Node):
    if _is_collected or not crystal_data:
        return
    var mana_comp = _find_mana_component(body)
    if not mana_comp:
        return
    _is_collected = true
    var amount = mana_comp.max_mana * _get_mana_percent()
    mana_comp.restore(amount)
    hide()
    respawn_timer.start()

func _on_respawn_timer_timeout():
    _is_collected = false
    show()

func _find_mana_component(node: Node) -> ManaComponent:
    var pod = node
    while pod and not pod.has_node("ManaComponent"):
        pod = pod.get_parent()
    return pod.get_node("ManaComponent") if pod else null
```

One scene, N `.tres` files. **Editor placement:** assign `crystal_data` in the Inspector → `_ready()` reads from the resource. **Runtime spawn** (combat drops): assign `crystal_data` directly on the export, set `_override_percent` for partial values — never scatter raw fields like `mana_value_percent = 5.0` or mutate the shared Resource.

To make a new crystal variant, duplicate a preset `.tres` and tweak values — the scene stays untouched.

---

## Combat Drop

When a racer is hit by an ability or significant collision, they drop a fraction of their **current** mana as pickups.

### Drop Amount

```gdscript
const DROP_FRACTION: float = 0.15   # 15% of current mana dropped
const MIN_DROP: float = 2.0          # no drops below this threshold
```

At 15% drop rate, full mana (100) drops 15 mana. At low mana (20), drops 3 mana — small pickups only.

### Scatter Pattern

Dropped crystals scatter physically for readable gameplay:

1. Calculate total dropped mana from `current_mana * DROP_FRACTION`
2. Divide into crystals by size using the preset Resources: small (5%) or large (20%), never super (that would be a huge loss)
3. Spawn each crystal at the pod's position with:
   - Random horizontal direction (360°)
   - Random spread radius (2–4 units)
   - Upward arc velocity (launch via tween)
   - On landing, small bounce then settle

```gdscript
@export var small_crystal_data: ManaCrystalResource   # assigned in inspector
@export var large_crystal_data: ManaCrystalResource

const DROP_FRACTION: float = 0.15
const MIN_DROP: float = 2.0

func scatter_drop(origin: Vector3, mana_comp: ManaComponent):
    var dropped = mana_comp.current_mana * DROP_FRACTION
    if dropped < MIN_DROP:
        return
    mana_comp.spend(dropped)

    var remaining = dropped
    while remaining > 0.0:
        var data: ManaCrystalResource
        var value: float

        if remaining >= 20.0:
            data = large_crystal_data
            value = 20.0
        elif remaining >= 5.0:
            data = small_crystal_data
            value = 5.0
        else:
            data = small_crystal_data
            value = remaining

        remaining -= value
        _spawn_crystal(origin, data, value / mana_comp.max_mana)

func _spawn_crystal(origin: Vector3, data: ManaCrystalResource, percent: float):
    var crystal = mana_crystal_scene.instantiate()
    crystal.crystal_data = data
    crystal._override_percent = percent   # per-instance, never writes to the Resource

    var angle = randf_range(0.0, TAU)
    var dist = randf_range(2.0, 4.0)
    crystal.position = origin + Vector3(cos(angle) * dist, 0.5, sin(angle) * dist)

    # Tween: fly up, arc, land with bounce
    var target_y = 0.0
    var peak = origin.y + randf_range(1.5, 3.0)
    var tween = create_tween()
    tween.tween_property(crystal, "position:y", peak, 0.3).set_ease(Tween.EASE_OUT)
    tween.tween_property(crystal, "position:y", target_y, 0.4).set_ease(Tween.EASE_IN)
    tween.tween_property(crystal, "position:y", target_y + 0.3, 0.15).set_ease(Tween.EASE_OUT)
    tween.tween_property(crystal, "position:y", target_y, 0.15).set_ease(Tween.EASE_IN)

    get_tree().current_scene.add_child(crystal)
```

Combat-drop crystals set `respawn_time = 0.0` (they never respawn) by not wiring the RespawnTimer. The crystal scene is reused — only the assigned resource differs.

---

## Integration Points

### Shield System
```gdscript
# Shield active → drain mana per second (continuous, not timer)
func _process_shield_drain(delta: float):
    if shield_active:
        var drain = shield_drain_rate * delta
        if not mana_component.spend(drain):
            _deactivate_shield()   # auto-off on empty

# Parry → restore mana (discrete event)
func _on_parry():
    mana_component.restore(parry_refund_amount)
    mana_component.mana_restored.emit(parry_refund_amount)
```

### Ability System
```gdscript
func try_activate_ability(ability: AbilityResource):
    if not mana_component.spend(ability.mana_cost):
        return  # rejected — not enough mana
    ability.activate(self)
    # cooldown handled by ability system independently
```

### HUD
```gdscript
# In the mana bar UI controller:
mana_component.mana_changed.connect(_on_mana_changed)

func _on_mana_changed(current: float, max: float):
    mana_bar.value = current / max
    # Also triggers glow/dim animation on the bar
```

---

## Multiplayer Considerations

### State Per Player
Each peer owns a `ManaComponent` for their local pod. In rollback:

- **Local prediction** — mana spend/restore executes immediately on input.
- **Server authoritative** — server validates spend/restore on each `_rollback_tick()`. If server disagrees, it overwrites and fires correction.
- **Mana pickups** — server spawns crystals (deterministic seed per track). Collect event is an `INetworkEvent` — if two players claim the same crystal in the same tick, server resolves ownership by order of arrival.

### Regen in Rollback
Timer-based regen maps cleanly to rollback ticks:

```gdscript
# In _rollback_tick(tick_delta):
#   tick_delta = regen_tick_interval means this tick is a regen tick
#   ManaComponent._on_regen_tick() is called by the rollback system
#   exactly once per regen interval, deterministically
```

No accumulation, no drift. The server and all clients agree "tick N fired a regen" because the tick interval is a fixed stat.

---

## Data-Driven Stats (VehicleStats)

These values come from the pod's component/upgrade system, same as EP1R stat slots:

| Stat Key | Default | Component Effect |
|---|---|---|
| `mana_max` | 100 | +20 per tier |
| `mana_regen_rate` | 2.0/s (4 per tick at 0.5s interval) | +0.5/s per tier |
| `mana_drop_resistance` | 0% (full 15% drop) | -3% per tier, min 0% |
