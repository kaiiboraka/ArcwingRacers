# Audio System (Draft)

> **Status:** Settled decisions recorded, open questions flagged.

## Bus Architecture

```
Master
├── Music                ← regular stereo AudioStreamPlayer (non-spatial)
├── SFX
│   ├── Engine           ← per-pod engine loops, 3D spatial
│   ├── Boost            ← boost/heat SFX, 3D spatial
│   ├── Collision        ← crash/scrape, 3D spatial
│   ├── Abilities        ← weapon/ability SFX, 3D spatial
│   ├── Hazards          ← environmental hazard loops, 3D spatial
│   ├── Ambience         ← track ambience loops — spatial or 2D? TBD
│   ├── UI               ← menu/navigation sounds, 2D
│   └── Voice            ← announcer, crowd, 2D
```

Decided:
- Engine, abilities, collisions, hazards = **`AudioStreamPlayer3D`** (spatial)
- UI, Voice = **`AudioStreamPlayer`** (2D)
- Music = **stereo `AudioStreamPlayer`**, non-spatial, on its own bus
- Ambience = **undecided** — could be 3D (positioned in track geometry) or 2D (scene-filling crossfade)

## Import Settings

**Deferred — needs research.** Tradeoff summary for later decision:

| Setting | Tradeoff |
|---|---|
| **Load Mode: Decompress On Load** | Higher memory (~10×), no decode cost at playback. Good for short frequent SFX. |
| **Load Mode: Streaming** | Tiny buffer (~200KB), reads from disk. Good for long ambience/music loops. |
| **Force To Mono on spatial clips** | Godot's 3D spatializer collapses stereo anyway, so stereo data on a 3D-only clip is wasted memory. Mono halves the memory on those clips. But if a clip sounds better in stereo even when spatialized, keep stereo. |

TBD per-clip after auditioning in-editor.

## Doppler

**Enabled.** Defer performance/memory concerns — try it first.

## Reverb

Per-spline flag. Each spline segment stores a `reverb_preset` (e.g., `"none"`, `"tunnel"`, `"indoor"`, `"cave"`). The ambience system switches the reverb send on the master or ambience bus when the player enters that segment.

Implementation options:
- **Bus effect:** `AudioEffectReverb` on a send bus, toggled by segment
- **Per-player:** `ReverbBus` property on `AudioStreamPlayer3D` (simpler)

## Music

Don't rule out dynamic layering. Track design needs to happen first before locking this down. Keep open for now.

## Custom Audio Resources

Three GDScript `Resource` subclasses at `Content/Scripts/Resources/`, ported from C# originals. Class definitions live here; actual `.tres` asset files go in `Content/Resources/`.

### AudioFile (`audio_file.gd`)
Wraps a single stream with baked-in pitch/volume defaults. Subclasses `AudioStream` — assign directly to any `AudioStreamPlayer`.

```gdscript
class_name AudioFile
extends AudioStream

@export var stream: AudioStream
@export var pitch_scale: float = 1.0
@export var volume_db: float = 0.0
```

`PitchScale` and `VolumeDb` live on the asset, not in code. The player inherits them automatically.

### AudioBucket (`audio_bucket.gd`)
Random-variant container. Subclasses `AudioStream` — assign to a player directly; picks a random entry on each `_instantiate_playback()`.

```gdscript
class_name AudioBucket
extends AudioStream

@export var bucket: Array[AudioStream]
@export var pitch_scale: float = 1.0
@export var volume_db: float = 0.0
```

**Impact:** Instead of pooling 3–4 players and picking variants in code, assign a single `AudioBucket` (with all metal variants in its `bucket`) to one player. The bucket randomizes on every `.Play()`, `PitchScale`/`VolumeDb` are baked in. Simpler, more data-driven.

### AudioData (`audio_data.gd`)
Named dictionary of sounds. The `.tres` asset is authored per-pod or per-category.

```gdscript
class_name AudioData
extends Resource

@export var sounds: Dictionary = {}

func get_sound(key: String) -> AudioStream:
    return sounds.get(key) as AudioStream
```

Usage: assign a pod's `AudioData` `.tres` to its `EngineAudio` controller. Lookup by key (`"engine_lo"`, `"engine_hi"`, `"boost"`, `"collision_metal"`, etc.).

## Per-Pod Engine Architecture

Each pod gets an `AudioStreamPlayer3D` per layer, plus an `AudioData` `.tres` asset.

```
Arcwing (CharacterBody3D)
└── EngineAudio (Node)     ← references AudioData.tres for this pod
    ├── AudioStreamPlayer3D (steady_lo)
    ├── AudioStreamPlayer3D (steady_hi)
    ├── AudioStreamPlayer3D (varipitch)
    ├── AudioStreamPlayer3D (maw)
    ├── AudioStreamPlayer3D (boost)
    ├── AudioStreamPlayer3D (flame)
    ├── AudioStreamPlayer3D (scrape)
    └── AudioStreamPlayer3D (flamethrower_ability)
```

Pitch blending per-frame on the `pitch_scale` property:

```gdscript
func update_engine(speed_fraction: float, heat_pct: float):
    var pitch = lerp(0.6, 1.8, speed_fraction)
    pitch += heat_pct * 0.3

    steady_lo.pitch_scale = pitch * 0.9
    steady_hi.pitch_scale = pitch * 1.1
```

**Questions:**
- How many layers? Pare down during implementation.
- Boost: separate player or modify steady loops + one-shot?
- Which clips are loops vs one-shots?

### Heat Beeps

AudioFile or plain AudioStream assigned to dedicated players. Event-driven from `BoostComponent`:

```gdscript
func _on_boost_heat_updated(heat_pct: float):
    if heat_pct < 0.5:
        _stop_beep()
    elif heat_pct < 0.85:
        _start_beep_slow()
    else:
        _start_beep_fast()
```

Beep clips TBD — `sfx_beeps_misc_a`/`b`/`c` need auditioning.

## Collision SFX

Assign an `AudioBucket` (with all `sfx_crash_metal_*` variants) to a single `AudioStreamPlayer3D`. No code randomization needed — bucket picks a random variant on each `.Play()`.

Same pattern for scrape: separate player with a looping `AudioFile`. Start on contact enter, stop on exit.

## Music

**Don't rule out dynamic layering** — revisit after track/music composition begins.

## SFX Inventory

Cross-reference to `docs/game-design/audio-direction/audio-overview.md` — the per-category tables there map EP1R assets to proposed use. `sfx_pod_seb_*` is Sebulba's EP1R flame weapon — not used in ArcwingRacers. `sfx_flame_burst_*` is generic, available for fire effects.

## Remaining Decisions

- **Import settings** per clip (Decompress vs Streaming, mono vs stereo) — needs research, then per-clip after auditioning in-editor
- **Ambience** — 3D spatial or 2D scene-filling?
- **Music** approach — revisit later
- **Engine layer count** — pare down during implementation
