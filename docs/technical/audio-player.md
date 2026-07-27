# Audio Player

## Import Settings (Load Type)

Pick deliberately per clip — this is a real memory budget, not a minor setting:

| Load Type | Memory | Use for |
|---|---|---|
| Decompress On Load | ~10x clip size (Vorbis) | Short, frequently-triggered SFX (bite, coin pickup) |
| Compressed In Memory | Moderate, decompresses on the fly | Medium-length, less frequent SFX |
| Streaming | Small fixed buffer (~200KB), continuous I/O | Music, ambient loops |

Enable **Force To Mono** on any clip that plays through a positional/3D-blended `AudioSource` — stereo channels collapse to mono during spatialization anyway, so a stereo import just wastes memory for no audible benefit.

## Playback

- `AudioSource.Play()` restarts/cuts off whatever that source is currently playing. `PlayOneShot()` layers a new instance over whatever's already playing without interrupting it — use `PlayOneShot` for anything that can legitimately overlap (rapid coin pickups, multiple simultaneous bites).
- **Never use `AudioSource.PlayClipAtPoint`** for frequent effects — it instantiates and destroys a temporary GameObject *per call*, which is exactly the kind of runtime allocation `technical/object-pooling.md` exists to eliminate. Pool a small set of `AudioSource`s via `UnityEngine.Pool.ObjectPool<T>` instead, following the same self-injecting pattern as any other pooled object in this project.
- Only one `AudioListener` may be active per scene. With the project's additive Bootstrap + content scene architecture, make sure a content scene's camera never carries a second `AudioListener` — keep it on the Bootstrap-owned camera only.

## Audio Mixer

`AudioMixer.SetFloat`/`GetFloat` parameters are in **decibels, not linear 0–1**. Setting a "volume" parameter to `0.5f` is nearly silent, not half volume. Convert from a linear UI slider value with:

```csharp
mixer.SetFloat("Volume", Mathf.Log10(Mathf.Max(linearValue, 0.0001f)) * 20f);
```
