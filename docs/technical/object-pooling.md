# Object Pooling

Instantiating and destroying nodes at runtime allocates heap memory and triggers GC. Object pooling pre-allocates instances at startup, lends them out when needed, and reclaims them when done — zero allocations in steady-state gameplay.

**Rule:** Any node that is spawned and destroyed repeatedly during gameplay must be pooled.

---

## The Project Pool Implementation

The project provides two pool base classes:

- **`ObjectPoolManager<T>`** (`Scripts/Utility/ObjectPoolManager.cs`) — C# generic base. `T` must be a `Node`. Used for C#-based pooled objects.
- **`GDObjectPoolManager`** (`Scripts/Utility/GDObjectPoolManager.gd`) — GDScript equivalent for GDScript-based pooled objects.

Both follow the same pattern: a pool Autoload or manager node subclasses the base, exports a `PackedScene` and a `PoolMaxSize`, and calls `Get()` / `Release()` to lend and return objects.

### How It Works

On `_EnterTree()`, `ObjectPoolManager<T>` creates a dedicated `CanvasLayer` under the scene root to parent all pooled instances — keeping them out of the active scene tree and invisible until lent out.

**`Get()`** — returns a pooled instance (or instantiates one if the pool is empty), re-enables process ticking, and makes it visible.

**`Release(obj)`** — disables process ticking, hides the object, calls `Reset()` on it if the method exists, and returns it to the queue. If the pool is at `PoolMaxSize`, the object is freed instead.

```csharp
// Subclass example — ItemDropSpawner is an Autoload
public partial class ItemDropSpawner : ObjectPoolManager<ItemInstance>
{
    public static ItemDropSpawner Instance { get; private set; }

    public override void _Ready()
    {
        Instance = this;
    }

    public void SpawnItem(ItemData data, Vector2 position)
    {
        ItemInstance item = Get();
        if (item == null) return; // pool at capacity

        item.Initialize(data, this); // caller passes itself as the pool reference
        item.GlobalPosition = position;
    }
}
```

```csharp
// The pooled object — calls Release() on itself when done
public partial class ItemInstance : RigidBody2D
{
    private ItemDropSpawner _pool;

    public void Initialize(ItemData data, ItemDropSpawner pool)
    {
        _pool = pool;
        // set up state...
    }

    public void ReturnToPool()
    {
        _pool.Release(this);
    }

    // Called automatically by ObjectPoolManager.Release() if present
    public void Reset()
    {
        // clear runtime state: velocity, data references, subscriptions, etc.
    }
}
```

The pool injects itself into the object at initialization. The pooled object never needs to discover its pool — it's handed the reference directly.

---

## What to Pool in This Project

| Object | Manager |
|---|---|
| Item drops | `ItemDropSpawner` (Autoload) |
| Floating combat text | `FloatingTextManager` (Autoload) |
| Projectiles | [TBD] — when implemented |
| Particle/VFX bursts | [TBD] — if managed outside GPUParticles |

Player and enemy actors are not pooled — they are present for the full session or cleanly freed between levels.

---

## Reset vs. Initialize

The most common pooling bug is **stale state from a prior use.**

- **`Reset()`** — called automatically by `Release()` if the method exists. Clears all runtime state: velocity, active timers, signal subscriptions, animation state. The object must be inert and neutral after `Reset()`.
- **`Initialize(params)`** — called by the spawner after `Get()`. Configures the object for its new use: position, data, pool reference.

Never rely on `Reset()` alone to set up state for a new use, and never rely on `Initialize()` to clear state from the last use.

---

## Pool Sizing

`PoolMaxSize` is exported and Inspector-configurable per pool manager. Set it to the realistic peak concurrent count for that object type. When the pool is at capacity, `Get()` returns `null` — callers must null-check the result.

Objects returned beyond `PoolMaxSize` are freed via `QueueFree()` rather than recycled. If this is happening frequently during gameplay, raise the cap.

---

## New Pool Checklist

1. Create a C# class that extends `ObjectPoolManager<T>` (or `GDObjectPoolManager` for GDScript).
2. Export the `PackedScene` and set `PoolMaxSize` in the Inspector.
3. Register it as an Autoload in `project.godot` if it needs to be globally accessible.
4. Implement `Reset()` on the pooled node to clear all runtime state.
5. Implement `Initialize(...)` on the pooled node to configure it per use.
6. Have the pool pass itself to the pooled object in `Initialize()` so it can self-release.
