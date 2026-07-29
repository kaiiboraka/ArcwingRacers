# Ability System

**Location:** `systems/abilities/ability_component.gd`, `systems/abilities/ability_resource.gd`
**Dependencies:** ManaComponent, EventBus, InputBuffer
**Consumed by:** Pod controller, HUD

---

## AbilityResource

A read-only data Resource defining one ability. Never mutated at runtime — one `.tres` per ability, shared across all racers that use it.

```gdscript
# systems/abilities/ability_resource.gd
class_name AbilityResource
extends Resource

# ── Identity ──
@export var ability_name: String = "Fireball"
@export var element: ElementType      # enum from global definitions
@export var weapon_type: WeaponType   # enum: PROJECTILE, CONE, AURA, etc.

# ── Type ──
enum AbilityType { ACTIVE, PASSIVE }
@export var ability_type: AbilityType = AbilityType.ACTIVE

# ── Cast Mode (active only) ──
enum CastType { INSTANT, CAST_TIME, CHARGED, CHANNELED }
@export var cast_type: CastType = CastType.INSTANT
@export var cast_time: float = 0.0       # seconds of wind-up (CAST_TIME)
@export var charge_max_time: float = 2.0 # max hold time (CHARGED)

# ── Costs ──
@export var mana_cost: float = 10.0       # flat cost (instant/cast/charge) or per-second (channel)
@export var cooldown: float = 3.0         # seconds before reuse

# ── Effects ──
@export var damage: float = 25.0
@export var effect_radius: float = 2.0
@export var effect_duration: float = 0.0  # lifetime (projectiles) or max channel time
@export var projectile_speed: float = 40.0

# ── Scene ──
@export var effect_scene: PackedScene     # the spawned projectile/hazard/effect
```

**Presets on disk** (`Content/Data/abilities/`):
```
fireball.tres          → PROJECTILE + Fire
cone_of_cold.tres      → CONE + Ice
gust_of_wind.tres      → CONE + Wind
chain_lightning.tres   → PROJECTILE + Lightning
rooting_vines.tres     → PROJECTILE + Wood (slows target)
```

New abilities are created by duplicating a `.tres` and changing element/values. The scene stays untouched.

---

## Weapon Type × Element Composition

One scene per weapon type. The AbilityResource's element drives visual and flavor.

### Weapon Type Scenes

| Weapon Type | Scene | Behavior |
|---|---|---|
| `PROJECTILE` | `Content/Abilities/projectile.tscn` | Fires forward, hits first pod or obstacle. Element sets material color + particle effect. |
| `CONE` | `Content/Abilities/cone.tscn` | Frontal arc, hits all pods within angle. Element sets cone color + particle effect. |
| `AURA` | `Content/Abilities/aura.tscn` | Self-centered radius effect, pulses while active. Element sets ring color. |
| `HOMING` | `Content/Abilities/homing.tscn` | Tracks nearest target pod. Element sets trail color. |
| `DROP` | `Content/Abilities/drop.tscn` | Drops a hazard behind the pod. Element sets hazard visual. |
| `BUFF` | `Content/Abilities/buff.tscn` | Self-targeted stat modifier for duration. Element sets glow. |

### Effect Scene Setup

Each effect scene reads the AbilityResource on spawn to configure itself:

```gdscript
# In projectile.gd (generic projectile scene)
extends Area3D

func init(ability: AbilityResource):
    damage = ability.damage
    speed = ability.projectile_speed
    lifetime = ability.effect_duration
    _apply_element_visual(ability.element)

func _apply_element_visual(element: ElementType):
    match element:
        ElementType.FIRE:
            mesh.material = fire_material
            trail.emitting = true
            trail.modulate = Color.ORANGE_RED
        ElementType.ICE:
            mesh.material = ice_material
            trail.modulate = Color.CYAN
        ElementType.LIGHTNING:
            mesh.material = lightning_material
            trail.modulate = Color.YELLOW
        # ... per-element visual setup
```

No element-exclusive scenes needed. One `projectile.tscn`, N material presets.

---

## AbilityComponent

A per-pod node managing ability state. One `AbilityComponent` per racer.

```gdscript
# ability_component.gd
class_name AbilityComponent
extends Node

enum State { READY, CASTING, CHARGING, CHANNELING, COOLDOWN }

@export var primary_ability: AbilityResource
@export var secondary_ability: AbilityResource   # optional, null if 1-slot racer

var state: State = State.READY
var current_ability: AbilityResource
var _mana: ManaComponent
var _cooldown_timer: float = 0.0
var _cast_timer: float = 0.0
var _charge_time: float = 0.0
var _channel_time: float = 0.0
var _active_effect: Node = null
```

### State Machine

```
                    press[INSTANT]
 READY ────────────────────────────────→ COOLDOWN
  ↑  press[CAST_TIME]   cast complete     │
  ├──→ CASTING ──────────────────────────→┤
  │    release early  ↓(interrupted)       │
  │    └──→ COOLDOWN (short penalty)      │
  │                                        │
  │  press[CHARGED]   release              │
  ├──→ CHARGING ─────────────────────────→┤
  │    held past max  ↓(auto-fire)         │
  │    └────────────────────────────────→┤│
  │                                        │
  │  press[CHANNELED]  release / mana=0    │
  ├──→ CHANNELING ───────────────────────→┤
  │                                        │
  └──→ COOLDOWN ──── timer done ────────→ READY
```

### State Logic

```gdscript
func try_activate(slot: int = 0):
    if state != State.READY:
        return
    var ability = primary_ability if slot == 0 else secondary_ability
    if not ability or ability.ability_type != AbilityResource.AbilityType.ACTIVE:
        return

    current_ability = ability
    match ability.cast_type:
        AbilityResource.CastType.INSTANT:
            if _mana.spend(ability.mana_cost):
                _fire(ability)
                _start_cooldown(ability.cooldown)
        AbilityResource.CastType.CAST_TIME:
            _enter_casting(ability)
        AbilityResource.CastType.CHARGED:
            _enter_charging(ability)
        AbilityResource.CastType.CHANNELED:
            _enter_channeling(ability)

func _fire(ability: AbilityResource):
    var effect = ability.effect_scene.instantiate()
    effect.init(ability)
    # Position relative to pod forward
    get_parent().add_child(effect)
    EventBus.ability_fired.emit(ability.ability_name, ability.element)

func _start_cooldown(duration: float):
    state = State.COOLDOWN
    _cooldown_timer = duration

func _process(delta: float):
    match state:
        State.COOLDOWN:
            _cooldown_timer -= delta
            if _cooldown_timer <= 0.0:
                state = State.READY
                EventBus.ability_ready.emit()
        State.CASTING:
            _cast_timer -= delta
            if _cast_timer <= 0.0:
                if _mana.spend(current_ability.mana_cost):
                    _fire(current_ability)
                    _start_cooldown(current_ability.cooldown)
                else:
                    state = State.READY   # insufficient mana after cast
        State.CHARGING:
            _charge_time += delta
            if _charge_time >= current_ability.charge_max_time:
                _release_charge()
        State.CHANNELING:
            _channel_time += delta
            if not _mana.spend(current_ability.mana_cost * delta):
                _end_channel()   # out of mana
            elif _channel_time >= current_ability.effect_duration:
                _end_channel()   # max duration reached
```

### Cast Type Implementations

```gdscript
func _enter_casting(ability: AbilityResource):
    state = State.CASTING
    _cast_timer = ability.cast_time
    EventBus.ability_cast_started.emit(ability.ability_name, ability.cast_time)

# Call when button released during cast
func interrupt_cast():
    if state == State.CASTING:
        state = State.READY
        _cast_timer = 0.0
        EventBus.ability_cast_interrupted.emit()

func _enter_charging(ability: AbilityResource):
    state = State.CHARGING
    _charge_time = 0.0
    EventBus.ability_charge_started.emit()

# Call when button released
func _release_charge():
    if state != State.CHARGING:
        return
    var scale = clamp(_charge_time / current_ability.charge_max_time, 0.0, 1.0)
    if _mana.spend(current_ability.mana_cost * scale):
        var ability = current_ability
        ability.damage *= scale          # WRONG — mutates shared Resource
        # ... correct approach below
        _fire(current_ability)
        _start_cooldown(current_ability.cooldown)

# CORRECT: per-instance override, Resource stays pristine
# Store charge scale on the component, pass to effect on fire
var _charge_scale: float = 1.0

func _enter_charging(ability: AbilityResource):
    state = State.CHARGING
    _charge_time = 0.0
    _charge_scale = 0.0

func _release_charge():
    _charge_scale = clamp(_charge_time / current_ability.charge_max_time, 0.0, 1.0)
    if _mana.spend(current_ability.mana_cost * _charge_scale):
        _fire(current_ability)
        _start_cooldown(current_ability.cooldown)

# Effect reads _charge_scale via the component during init
```

```gdscript
func _enter_channeling(ability: AbilityResource):
    state = State.CHANNELING
    _channel_time = 0.0
    _active_effect = ability.effect_scene.instantiate()
    _active_effect.init(ability)
    get_parent().add_child(_active_effect)
    EventBus.ability_channel_started.emit()

func _end_channel():
    if _active_effect:
        _active_effect.queue_free()
        _active_effect = null
    _start_cooldown(current_ability.cooldown)

# Call when button released
func release():
    if state == State.CHANNELING:
        _end_channel()
    elif state == State.CHARGING:
        _release_charge()
```

---

## Passive Abilities

Passive abilities have no activation flow. They apply their effect when the component initializes.

```gdscript
func _ready():
    _mana = _find_mana_component()
    _apply_passives()

func _apply_passives():
    if primary_ability and primary_ability.ability_type == AbilityResource.AbilityType.PASSIVE:
        _apply_passive(primary_ability)
    if secondary_ability and secondary_ability.ability_type == AbilityResource.AbilityType.PASSIVE:
        _apply_passive(secondary_ability)

func _apply_passive(ability: AbilityResource):
    match ability.weapon_type:
        WeaponType.PASSIVE_DEFENSE:
            # e.g., "Defensive Armor" — boosts shield strength while in play
            EventBus.shield_strength_mod.emit(ability.damage)
        WeaponType.PASSIVE_REGEN:
            # e.g., "Mana Font" — increases mana regen rate
            EventBus.mana_regen_mod.emit(ability.damage)
        # Other passive weapon types...

```

Passive `.tres` files define the effect values. The component reads them once on ready and emits modifier signals. No ongoing state machine.

---

## Input Integration

```gdscript
# In pod_controller.gd:
func _read_ability_input():
    if Input.is_action_just_pressed("ability_primary"):
        ability_component.try_activate(0)
    if Input.is_action_just_pressed("ability_secondary"):
        ability_component.try_activate(1)

    # Release for charged/channeled
    if Input.is_action_just_released("ability_primary"):
        ability_component.release()
```

For buffer-based input (multiplayer):

```gdscript
# InputSnapshot includes:
var ability: bool          # edge-triggered
var ability_hold: bool     # held state (for charged/channeled)

# In AbilityComponent.rollback_tick():
func rollback_tick(snapshot: InputSnapshot):
    if snapshot.ability and state == State.READY:
        try_activate(0)
    elif not snapshot.ability_hold:
        release()
```

---

## Signals

| Signal | Args | When |
|---|---|---|
| `ability_ready` | — | Cooldown finished, ability usable |
| `ability_fired(name, element)` | String, ElementType | Ability effect spawned |
| `ability_cast_started(name, cast_time)` | String, float | Wind-up began (CAST_TIME) |
| `ability_cast_interrupted` | — | Wind-up cancelled |
| `ability_charge_started` | — | Charging began |
| `ability_channel_started` | — | Channeling began |
| `ability_channel_ended` | — | Channeling ended (release or mana empty) |

---

## Integration

### ManaComponent
`_mana.spend(cost)` gates activation and channel upkeep. If mana is insufficient, the ability is rejected during READY or ends early during channel.

### Shield System
Shield does not block friendly abilities. Projectiles from the same pod pass through the shield's collision layer.

### HUD
```gdscript
ability_component.ability_ready.connect(_on_ability_icon_ready)
ability_component.ability_fired.connect(_on_ability_icon_cooldown)
# Cooldown timer shown on ability icon — read from component state
func _process(_delta):
    ability_icon.cooldown_fill = ability_component._cooldown_timer / ability_component.current_ability.cooldown
```

---

## Multiplayer Considerations

- **Ability activation** is input-derived (edge from InputSnapshot). Under rollback, `try_activate()` is called per rollback tick with the buffered input.
- **Effect spawning** is a local prediction. The server validates the mana spend and cooldown start on its authoritative tick. If the client predicted incorrectly, the server overwrites (effect may despawn).
- **Hit detection** for projectiles uses the same rollback-friendly collision model as the rest of pod physics — hits are validated server-side on each tick.
- **Cooldown** is timer-based (deterministic under rollback — fixed tick rate, no drift).
- **Charged abilities** are tricky: charge time is real-time. Under rollback, the server may disagree with how long the player held the button. Solution: the client sends the charge duration with the release input, server validates it's within the max window.

---

## Data-Driven Stats (VehicleStats)

Abilities themselves are defined by their `.tres` resource. However, character-specific cooldown reduction is a potential stat:

| Stat Key | Default | Component Effect |
|---|---|---|
| `ability_haste` | 0% | -5% cooldown time per tier (multiplicative with ability's base cooldown) |
