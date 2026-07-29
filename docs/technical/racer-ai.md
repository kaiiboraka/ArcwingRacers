# AI Racer

**Location:** `systems/ai/racer_ai.gd`, `systems/ai/ai_personality_resource.gd`
**Dependencies:** Spline, InputBuffer, ManaComponent, ShieldComponent, AbilityComponent
**Consumed by:** Slot system (fills empty player slots)

---

## AI_PersonalityResource

A read-only data Resource defining one AI behavior preset. Never mutated at runtime.

```gdscript
# systems/ai/ai_personality_resource.gd
class_name AIPersonalityResource
extends Resource

@export var preset_name: String = "Balanced"

# ── Core Driving ──
@export var lookahead_distance: float = 40.0       # spline lookahead in units
@export var steering_aggression: float = 0.5       # 0.0 = lazy, 1.0 = sharp
@export var boost_aggression: float = 0.5           # 0.0 = never boost, 1.0 = always when possible
@export var brake_aggression: float = 0.5           # 0.0 = late/minimal, 1.0 = early/heavy
@export var starting_boost_precision: float = 0.5   # 0.0 = bad timing, 1.0 = perfect

# ── Combat ──
@export var ram_aggression: float = 0.5             # 0.0 = avoid, 1.0 = actively hunt
@export var avoidance: float = 0.5                  # 0.0 = no dodge, 1.0 = always dodge
@export var shield_usage: float = 0.5               # chance to raise shield when threat detected
@export var parry_ability: float = 0.5              # chance to parry when shield is raised
@export var ability_usage: float = 0.5              # chance to activate ability per valid opportunity

# ── Branching ──
@export var shortcut_tendency: float = 0.5          # 0.0 = stay main, 1.0 = always take shortcut
```

**Presets on disk** (`Content/Data/ai_personalities/`):
```
balanced.tres
aggressive.tres
precision.tres
reckless.tres
defensive.tres
cautious.tres
hot_headed.tres
```

---

## AITraitOverride

A small Resource used for character-specific trait overrides. Stored in an array on RacerData — the user adds as many as needed in the Inspector.

```gdscript
# systems/ai/ai_trait_override.gd
class_name AITraitOverride
extends Resource

@export var stat: String = "ram_aggression"   # matches AIPersonalityResource export names
@export var value: float = 0.9
```

The stat field uses the export name from `AIPersonalityResource` as a string key. This avoids an enum that would need updating for every new personality field.

---

## RacerData (Character Data)

A per-character Resource that stores identity, stats, and AI trait overrides.

```gdscript
# Content/Scripts/Data/racer_data.gd
class_name RacerData
extends Resource

@export var racer_name: String = "Kael"
@export var element: ElementType
@export var primary_ability: AbilityResource
@export var secondary_ability: AbilityResource

# ── Base Stats ──
@export var base_stats: Dictionary = {
    "mana_max": 100.0,
    "mana_regen_rate": 2.0,
    "shield_strength": 1.0,
    # ... vehicle stats
}

# ── Track Affinity ──
@export var favorite_tracks: Array[String] = []   # TODO: replace with track resource reference once track data model is defined

# ── AI Trait Overrides ──
@export var ai_trait_overrides: Array[AITraitOverride]
```

Character `.tres` files live at `Content/Data/racers/`. Each racer has their own file with their specific trait overrides.

---

## RacerAI Component

One `RacerAI` per AI-controlled slot. Writes to the same InputBuffer as human players.

```gdscript
# racer_ai.gd
class_name RacerAI
extends Node

@export var personality: AIPersonalityResource
@export var racer_data: RacerData

var _buffer: SlotBuffer
var _spline: Spline
var _difficulty_multiplier: float = 1.0
var _pod: Node3D
var _mana: ManaComponent
var _shield: ShieldComponent
var _ability: AbilityComponent
var _effective_values: Dictionary = {}
var _starting_boost_timer: float = 0.0

# ── Initialization ──

var _affinity_multiplier: float = 1.0

func init(slot_buffer: SlotBuffer, spline: Spline, difficulty: float, pod: Node3D, track_name: String = ""):
    _buffer = slot_buffer
    _spline = spline
    _difficulty_multiplier = difficulty
    _pod = pod
    _affinity_multiplier = 1.15 if track_name in racer_data.favorite_tracks else 1.0
    _resolve_effective_values()

func _resolve_effective_values():
    for prop in AIPersonalityResource.properties():
        var base = personality[prop]
        for override in racer_data.ai_trait_overrides:
            if override.stat == prop:
                base = override.value
        _effective_values[prop] = base * _difficulty_multiplier * _affinity_multiplier
```

### Per-Tick Decision Pipeline

```gdscript
func ai_tick(delta: float):
    if not _pod or not _spline:
        return

    var snapshot = InputSnapshot.new()

    # 1. Get current spline position
    var pod_t = _spline.nearest_t(_pod.global_position)

    # 2. Compute steering toward lookahead target
    var lookahead = _effective_values["lookahead_distance"]
    var target = _spline.get_ai_target(pod_t, lookahead)
    snapshot.steering = _compute_steering(target)

    # 3. Accelerate always (AI doesn't lift unless braking)
    snapshot.acceleration = 1.0

    # 4. Boost decision
    if _should_boost(pod_t):
        snapshot.boost = true

    # 5. Brake decision
    if _should_brake(pod_t):
        snapshot.braking = 1.0

    # 6. Ram / avoid opponents
    var threat = _evaluate_nearby_opponents()
    if threat != 0.0:
        snapshot.steering = _adjust_for_ramming(snapshot.steering, threat)

    # 7. Shield decision
    if _should_shield():
        snapshot.shield = true

    # 8. Ability decision
    if _should_use_ability():
        snapshot.ability = true

    # Write to the shared input buffer
    _buffer.write_snapshot(snapshot)
```

### Steering

```gdscript
func _compute_steering(target: Vector3) -> float:
    var local_target = _pod.to_local(target)
    var steer = atan2(local_target.x, -local_target.z)
    var agg = _effective_values["steering_aggression"]
    return clampf(steer * agg * 2.0, -1.0, 1.0)
```

### Boost Decision

```gdscript
func _should_boost(spline_t: float) -> bool:
    var roll = randf()
    if roll > _effective_values["boost_aggression"]:
        return false

    # Only boost on straight or gentle curves
    var curvature = _spline.curvature_at(spline_t, lookahead_distance)
    return curvature < 0.3
```

### Brake Decision

```gdscript
func _should_brake(spline_t: float) -> bool:
    var roll = randf()
    if roll > _effective_values["brake_aggression"]:
        return false

    # Brake when upcoming curve is too sharp for current speed
    var curvature = _spline.curvature_at(spline_t, lookahead_distance * 0.5)
    return curvature > 0.6
```

### Ramming

```gdscript
func _evaluate_nearby_opponents() -> float:
    var ram = _effective_values["ram_aggression"]
    var avoid = _effective_values["avoidance"]

    if ram <= 0.0 and avoid <= 0.0:
        return 0.0

    var nearest = _find_nearest_opponent()
    if not nearest:
        return 0.0

    var local_pos = _pod.to_local(nearest.global_position)
    var lateral = local_pos.x

    if ram > avoid and randf() < ram:
        # Steer toward opponent
        return sign(lateral) * -1.0   # push steering toward them
    elif avoid > ram and randf() < avoid:
        # Steer away from opponent
        return sign(lateral) * 1.0    # push steering away

    return 0.0

func _adjust_for_ramming(base_steer: float, threat: float) -> float:
    # Blend base steering with ramming/avoidance impulse
    var impulse_strength = max(
        _effective_values["ram_aggression"],
        _effective_values["avoidance"]
    )
    return lerp(base_steer, threat, impulse_strength * 0.3)
```

### Shield Usage

```gdscript
func _should_shield() -> bool:
    var chance = _effective_values["shield_usage"]
    if randf() > chance:
        return false
    # Detect incoming threats: opponents nearby who have abilities off cooldown
    var threat = _detect_incoming_ability()
    return threat > 0.5

func _detect_incoming_ability() -> float:
    # Check if any nearby opponent is facing toward this AI
    # and has line-of-sight (simplified: within 45° cone + 30 units)
    for opponent in _get_nearby_opponents(30.0):
        var dir_to_ai = (_pod.global_position - opponent.global_position).normalized()
        var opponent_fwd = -opponent.global_transform.basis.z
        if dir_to_ai.dot(opponent_fwd) > 0.7:   # roughly within 45°
            return 1.0
    return 0.0
```

### Parry

If the shield is raised and an incoming hit is detected within the parry window (first ~10 frames of shield), roll parry chance:

```gdscript
func _should_parry() -> bool:
    return randf() < _effective_values["parry_ability"]
```

The AI calls `set_active(true)` to raise the shield, which opens the natural parry window. The parry ability check happens internally in ShieldComponent — the AI just decides when to raise.

### Ability Usage

```gdscript
func _should_use_ability() -> bool:
    var chance = _effective_values["ability_usage"]
    if randf() > chance:
        return false
    # Check cooldown and mana implicitly — AbilityComponent.try_activate() rejects
    # if unavailable. The AI just rolls the chance each valid tick.
    return true
```

The `try_activate()` call on AbilityComponent handles the actual cooldown and mana check. The AI doesn't need to track those separately.

### Starting Boost

```gdscript
func _process_starting_boost(delta: float):
    # At race start, AI times boost based on precision stat
    var precision = _effective_values["starting_boost_precision"]
    _starting_boost_timer += delta

    # Perfect precision = 0% deviation, low = random delay
    var target_delay = 1.0 + (1.0 - precision) * randf_range(0.0, 2.0)
    if _starting_boost_timer >= target_delay:
        _buffer.write_snapshot({"boost": true})
```

---

## Difficulty Multiplier

Applied once at initialization. Multiplies every effective value:

| Difficulty | Multiplier | Effect |
|---|---|---|
| Easy | 0.6 | Traits subdued — less aggressive, less precise |
| Medium | 1.0 | Baseline — presets as authored |
| Hard | 1.3 | Traits amplified — sharper behavior |
| Expert | 1.6 | Max amplification |

Values are clamped to `[0.0, 1.0]` after multiplication.

### Track Affinity Multiplier

Applied on top of difficulty. If the current track is in this racer's `favorite_tracks`, their effective values are multiplied by an additional ×1.15. A racer on their home track outperforms their normal personality — creating natural, track-specific spread without randomness.

---

## Branch Selection

AI delegates branch selection to the spline system (see `tracks-and-splines.md`):

```gdscript
func _select_branch(spline_t: float) -> int:
    var tendency = _effective_values["shortcut_tendency"]
    return _spline.select_branch(spline_t, tendency)
```

The spline's `select_branch()` evaluates all paths from the split point, scoring shortcuts higher for AI with high shortcut tendency.

---

## Loadout Randomization

When a tournament starts, each AI racer gets a randomized component loadout:

```gdscript
func generate_loadout(tier_min: int, tier_max: int) -> Dictionary:
    return {
        "traction":       _random_component(tier_min, tier_max),
        "turn_response":  _random_component(tier_min, tier_max),
        "acceleration":   _random_component(tier_min, tier_max),
        "top_speed":      _random_component(tier_min, tier_max),
        "air_brake":      _random_component(tier_min, tier_max),
        "cool_rate":      _random_component(tier_min, tier_max),
        "repair_rate":    _random_component(tier_min, tier_max),
    }

func _random_component(tier_min: int, tier_max: int) -> ComponentResource:
    var tier = randi_range(tier_min, tier_max)
    return load("res://Content/Data/components/tier_%d_random.tres" % tier)
```

This is called once per tournament save and persists. The same loadout is used for every race in that tournament.

---

## Slot Integration

`RacerAI` is instantiated for each AI-filled slot:

```gdscript
# In race setup:
for slot_index in range(racer_count):
    if slot_is_human(slot_index):
        continue
    var ai = RacerAI.new()
    ai.init(
        input_buffer.get_slot(slot_index),
        track_spline,
        difficulty_multiplier,
        spawn_pods[slot_index]
    )
    add_child(ai)
```

The AI tick is driven by the same physics frame as human inputs:

```gdscript
# In RaceManager._process_race(delta):
for ai in ai_racers:
    ai.ai_tick(delta)
```

---

## Signals

| Signal | Args | When |
|---|---|---|
| `ai_personality_assigned(racer_name, preset_name)` | String, String | Tournament start |
| `ai_loadout_generated(racer_name, loadout)` | String, Dictionary | Per AI at tournament start |

---

## Multiplayer Considerations

- **AI runs locally** on each peer in multiplayer. The AI decision system is deterministic (seeded random).
- **AI fills slots** not occupied by local or remote players. Same slot abstraction — the AI writes to the slot's InputBuffer.
- **No network sync** for AI state — only the input it writes to the buffer matters. The rollback system treats AI inputs the same as player inputs.
- **Seeded RNG** for personality assignment and loadout generation ensures all peers see the same AI opponents.
