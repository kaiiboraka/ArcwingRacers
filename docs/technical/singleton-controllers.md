# Singleton Controllers

Singletons solve a discovery problem: *how does System A find System B?* This document covers better answers to that question, and when a true Autoload singleton is still justified.

See also: `technical/game-events.md` for the signal/event architecture. `technical/code-standards.md` for the plain-C#-class → Resource → Node decision hierarchy. `technical/resources.md` for Custom Resource patterns.

---

## The Problem With Singletons

`GameManager.Instance` seems convenient until:
- Initialization order causes a null reference because `Instance` isn't ready yet
- Tests can't run in isolation because static state bleeds between them
- Scenes can't load independently because they all assume the singleton exists

The alternatives below replace *discovery* with *pre-wired references*.

---

## Preferred Alternatives

### 1. Inspector Injection (Export References)

For dependencies within a scene, wire them at design time. The Inspector is the dependency injection layer.

```csharp
public partial class PlayerBody : CharacterBody2D
{
    [Export] public LifeComponent Life { get; set; }
    [Export] public ManaComponent Mana { get; set; }
    [Export] public StatsComponent StatsComponent { get; set; }
}
```

No discovery at runtime. No `GetNode` path strings. The scene ships with its dependencies already wired. If a reference is null, it fails immediately in `_Ready()` via a `Debug.Assert` (see `technical/code-standards.md` → Inspector & Editor Conventions).

### 2. Signal-Based Decoupling

When a node needs to notify another system without holding a direct reference to it, use Godot Signals. The emitter doesn't know who's listening.

```csharp
// Emitter — knows nothing about who receives this
EmitSignalDied(context);

// Listener — connected in _Ready(), wired to whatever needs to respond
lifeComponent.SafeSubscribe(LifeComponent.SignalName.Died,
    Callable.From<DeathContext>(ItemDropSpawner.Instance.CalculateLootDrops));
```

See `technical/game-events.md` for the full tier model.

### 3. Custom Resources as Shared Data

For configuration or data that multiple systems read but no one "owns," use a `Godot.Resource` subclass saved as a `.tres` file. Any node can load or export-reference the same asset.

```csharp
[GlobalClass]
public partial class ElementalData : Resource
{
    [Export] public Godot.Collections.Dictionary<MagicElementType, float> Multipliers { get; set; }
}
```

Both a combat system and a UI system can hold a reference to the same `ElementalData.tres` without knowing about each other. See `technical/resources.md`.

---

## When an Autoload Singleton Is Justified

Use an Autoload when a system is genuinely global, has exactly one instance, must persist across all scene changes, and needs to be accessible from anywhere in the codebase. Autoloads are registered in `project.godot` and initialized before any scene loads.

**Before adding a new Autoload, confirm it cannot be solved by Inspector injection, a signal, or a shared Resource.** The bar is high — the project currently has 16 Autoloads (see `technical/code-standards.md` → Scenes & Scene Organization). Don't add to that list casually.

### Autoload Pattern

Every C# Autoload exposes a static `Instance` property initialized in `_EnterTree()`:

```csharp
public partial class GlobalGameState : Node
{
    public static GlobalGameState Instance { get; private set; }

    public override void _EnterTree()
    {
        Instance = this;
    }
}
```

Access it statically from anywhere: `GlobalGameState.Instance.CurrentPlayer`.

GDScript Autoloads are accessed directly by name as a global: `GlobalGameState.CurrentPlayer`.

### Autoload Initialization Order

Autoloads initialize in the order they appear in `project.godot`. If Autoload B depends on Autoload A being ready, A must be registered first. Never assume an Autoload is ready in another Autoload's `_EnterTree()` — use `_Ready()` for cross-Autoload access, as all Autoloads will be initialized by then.
