# Thief MVP Design
_2026-06-24_

## Scope

First playable character implementation. Covers the Thief from static sprite through grid-based movement, with a separate player controller layer. Excludes: abilities (Bribe/Steal), coin purse, camera follow, world tiles, collision with real map geometry.

This design deliberately excludes the Viper — but the movement system is built to be reused by Vipers with no structural changes, only different `GridMoverSettings` values.

---

## Build Sequence

1. Static Thief sprite as a prefab (no movement)
2. Grid configuration ScriptableObject
3. Grid movement system (pure C# logic + thin MonoBehaviour wrapper)
4. Player input controller (separate GameObject, drives the Thief)

---

## Architecture

### Layer Split

All game logic lives in plain C# classes, testable without a running Unity scene. MonoBehaviours are thin wrappers that wire Unity lifecycle and physics to the logic layer.

Reference: `technical/code-standards.md`, `technical/testing.md`.

### Pure C# Classes

| Class | Location | Responsibility |
|---|---|---|
| `Direction` | `Systems/Movement/` | Enum: `Up Down Left Right`. Helpers: `Opposite()`, `ToVector2Int()` |
| `IMapQuery` | `Systems/Movement/` | Interface: `bool IsPassable(Vector2Int cell)` |
| `AlwaysPassableMap` | `Systems/Map/` | Stub `IMapQuery` returning `true` for all cells — used until real map exists |
| `GridMover` | `Systems/Movement/` | All movement logic: position, interpolation, turn queueing, stopping |

### ScriptableObjects

| Class | Location | Fields | Asset path |
|---|---|---|---|
| `GridConfig` | `Systems/Map/` | `float CellSizeWorldUnits` | `ScriptableObjects/Config/GridConfig.asset` (one, project-wide) |
| `GridMoverSettings` | `Systems/Movement/` | `float SpeedCellsPerSecond`, `bool CanImmediatelyReverse` | `ScriptableObjects/Config/ThiefMoverSettings.asset` |

`GridConfig` is project-wide shared config, not per-character. It is currently injected as a serialized field on `GridMoverComponent` because no Map/Spawner system exists yet. When that system is built, it should hold `GridConfig` and inject the cell size at character spawn — the field moves off the prefab at that point.

### MonoBehaviours

| Component | Location | Responsibility |
|---|---|---|
| `GridMoverComponent` | `Characters/Shared/` | Owns `GridMover`. Ticks it in `FixedUpdate`. Calls `MovePosition`. Exposes `RequestTurn(Direction)` |
| `ThiefComponent` | `Characters/Thief/` | Marks the prefab as a Thief. Stub — grows to hold `ThiefCharacterData` SO reference and ability state |

### Prefab Structure

```
Thief.prefab  (Assets/_Project/Prefabs/Characters/)
  ├─ SpriteRenderer      Sorting Layer: Characters
  ├─ Rigidbody2D         Body Type: Kinematic, Interpolate: Interpolate
  ├─ GridMoverComponent
  └─ ThiefComponent
```

**Thief variants** (ThiefLord, etc.) are Prefab Variants of `Thief.prefab`. They override only the `SpriteRenderer` sprite and the Animator Controller. All component logic is inherited unchanged. Character-specific data (name, portrait, starting quests) will live on a `ThiefCharacterData` ScriptableObject referenced by `ThiefComponent` — not built yet.

---

## GridMover Internals

### State

| Field | Type | Meaning |
|---|---|---|
| `CurrentCell` | `Vector2Int` | Cell most recently fully entered |
| `TargetCell` | `Vector2Int` | Cell currently being moved toward |
| `CurrentDirection` | `Direction` | Direction of travel |
| `Progress` | `float` | 0→1 interpolation progress between the two cells |
| `_queuedDirection` | `Direction?` | Pending turn, applied at next cell boundary |
| `IsMoving` | `bool` | False when stopped against an impassable tile |

### Construction

```
GridMover(GridConfig, GridMoverSettings, Vector2Int startCell, Direction startDirection, IMapQuery)
```

On construction: `CurrentCell = startCell`, `TargetCell = startCell + startDirection.ToVector2Int()`, `Progress = 0`, `IsMoving = true`.

The spawn position and direction are set by whatever places the character into the world (initially hardcoded; later set by the spawner system).

### Tick Algorithm

Progress advances by `SpeedCellsPerSecond × deltaTime`. A `while` loop handles the cell-boundary crossing (rare multi-cell skips at high speed are handled correctly; in practice the loop body executes once per tick):

```
if not IsMoving: return

Progress += SpeedCellsPerSecond × deltaTime

while Progress >= 1.0:
    Progress -= 1.0
    CurrentCell = TargetCell
    fire OnCellReached(CurrentCell)

    candidate = _queuedDirection ?? CurrentDirection
    _queuedDirection = null

    nextCell = CurrentCell + candidate.ToVector2Int()

    if mapQuery.IsPassable(nextCell):
        if candidate != CurrentDirection: fire OnDirectionChanged(candidate)
        CurrentDirection = candidate
        TargetCell = nextCell
    else if candidate != CurrentDirection:
        // Queued turn was blocked — try continuing straight
        straightCell = CurrentCell + CurrentDirection.ToVector2Int()
        if mapQuery.IsPassable(straightCell):
            TargetCell = straightCell   // discard the blocked turn, keep direction
        else:
            IsMoving = false; Progress = 0; fire OnStopped(); return
    else:
        IsMoving = false; Progress = 0; fire OnStopped(); return
```

### Immediate Reversal (Thief only)

When `RequestTurn(direction)` is called with `Opposite(CurrentDirection)` and `CanImmediatelyReverse` is true, the reversal is applied immediately without waiting for the cell boundary:

```
swap CurrentCell ↔ TargetCell
CurrentDirection = requested direction
Progress = 1.0 - Progress
fire OnDirectionChanged(CurrentDirection)
```

Vipers set `CanImmediatelyReverse = false`. Their `RequestTurn` silently discards any direction equal to `Opposite(CurrentDirection)` — no special case needed in Tick.

### WorldPosition

```
Vector3.Lerp(CurrentCell × CellSizeWorldUnits, TargetCell × CellSizeWorldUnits, Progress)
```

Returned as a `Vector3` (z = 0). This is what `GridMoverComponent` passes to `Rigidbody2D.MovePosition()` each `FixedUpdate`.

### Events (Tier 3 — C# events)

| Event | Signature | Purpose |
|---|---|---|
| `OnCellReached` | `Action<Vector2Int>` | AI perception ticks, future pickup triggers |
| `OnDirectionChanged` | `Action<Direction>` | Sprite facing/flip |
| `OnStopped` | `Action` | Animation state, future wall-bump feedback |

---

## GridMoverComponent

```csharp
[Header("Config")]
[SerializeField] GridConfig _gridConfig       // project-wide; will move to Map/Spawner system
[SerializeField] GridMoverSettings _settings

[Header("References")]
[SerializeField] Rigidbody2D _rigidbody

// Owns the logic class
private GridMover _mover

Awake():
    _mover = new GridMover(_gridConfig, _settings,
                           startCell: Vector2Int.zero,
                           startDirection: Direction.Right,
                           new AlwaysPassableMap())

FixedUpdate():
    _mover.Tick(Time.fixedDeltaTime)
    _rigidbody.MovePosition(_mover.WorldPosition)

// Public API consumed by controllers
public void RequestTurn(Direction direction) => _mover.RequestTurn(direction)
public Vector2Int CurrentCell                => _mover.CurrentCell
public Direction CurrentDirection            => _mover.CurrentDirection
```

Subscribe/unsubscribe to `_mover` events in `OnEnable`/`OnDisable` as needed.

---

## File Layout

```
Assets/_Project/
  Scripts/
    Characters/
      Thief/
        ThiefComponent.cs
      Shared/
        GridMoverComponent.cs
    Systems/
      Movement/
        GridMover.cs
        GridMoverSettings.cs
        Direction.cs
        IMapQuery.cs
      Map/
        AlwaysPassableMap.cs
        GridConfig.cs
    Editor/
      Setup/
        SetupThiefPrefab.cs       ← one-shot setup script
  Prefabs/
    Characters/
      Thief.prefab
  ScriptableObjects/
    Config/
      GridConfig.asset
      ThiefMoverSettings.asset
```

---

## Out of Scope (Next Phases)

- Player input controller (separate GameObject with WASD/arrow input driving `GridMoverComponent.RequestTurn`)
- Cinemachine camera follow (belongs with the player controller)
- Real `IMapQuery` implementation backed by tilemap data
- Thief abilities: Bribe, Steal, coin purse
- `ThiefCharacterData` ScriptableObject for variant-specific data
- Animation (Animator Controller, sprite sheet)
- Object pooling for Thief spawning
