# Game Events

This document covers the event architecture for this project: when to use each tool, how they're implemented, and naming conventions.

See also: `technical/singleton-controllers.md` for global coordinator patterns and Autoload access.
See also: `technical/code-standards.md` → Events & Messaging for the tier summary.

---

## Three-Tier Model

| Tier | Tool | Coupling | Use when |
|---|---|---|---|
| 1 | Godot `[Signal]` | Low | Node-to-node or node-to-Autoload. Inspector-connectable. Cross-system but structurally related. |
| 2 | C# `EventBus` Autoload | None | [TBD] Fully decoupled cross-system broadcast. Evaluate when Tier 1 creates unacceptable coupling. |
| 3 | C# `event Action` | Direct | Same-class or tightly coupled pair. High-frequency callbacks where signal overhead matters. |

Default to Tier 1. Evaluate Tier 2 if Tier 1 requires a node to hold a reference to something it has no other reason to know about. Drop to Tier 3 only when the coupling already exists and performance demands it.

---

## Tier 1: Godot Signals

The primary pattern. Signals are declared on the emitting class and connected by whoever needs to listen.

```csharp
// Declaration — on the emitting node
[Signal] public delegate void DiedEventHandler(DeathContext context);
[Signal] public delegate void HitReceivedEventHandler(double damage);

// Emission — always use the generated wrapper, never EmitSignal(string)
EmitSignalDied(context);
EmitSignalHitReceived(damage);
```

### Connecting Signals

Prefer code-based connections in `_Ready()` over editor-wired connections. Code connections are version-controlled and visible to agents.

```csharp
public override void _Ready()
{
    // Preferred — SafeSubscribe prevents duplicate connections
    enemy.SafeSubscribe(ActorCore.SignalName.Died, OnEnemyDied);

    // Standard Connect — use where SafeSubscribe doesn't apply
    someNode.Connect(Node.SignalName.TreeExited, Callable.From(OnNodeRemoved));
}

public override void _ExitTree()
{
    // Always unsubscribe — prevents callbacks firing on freed nodes
    enemy.SafeUnsubscribe(ActorCore.SignalName.Died, OnEnemyDied);
}
```

Use `SafeSubscribe`/`SafeUnsubscribe` from `NodeExtensions.cs` for all programmatic Tier 1 connections. Use `Connect`/`Disconnect` directly only where the extension doesn't fit.

### Signals to Autoloads

When a node needs to notify a global system (e.g. a dying enemy notifying `ItemDropSpawner`), connect to the Autoload's method in `_Ready()`:

```csharp
public override void _Ready()
{
    this.SafeSubscribe(SignalName.Died, Callable.From<DeathContext>(ItemDropSpawner.Instance.CalculateLootDrops));
}
```

The Autoload exposes a static `Instance` property (see `technical/singleton-controllers.md`). The node doesn't need a direct reference to the Autoload beyond that.

---

## Tier 2: C# EventBus Autoload

[TBD] — Not yet implemented. Evaluate if a situation arises where Tier 1 requires nodes to hold references to systems they have no other reason to know about. When introduced, document the implementation here.

---

## Tier 3: C# `event Action`

Raw C# delegates. Use when the publisher and subscriber are already tightly coupled and the event fires frequently enough for signal overhead to matter.

```csharp
// On a plain C# class or tightly coupled component
public event Action OnDeath;
public event Action<ChangeMeterContext> OnParameterChanged;

private void ApplyDamage(float amount)
{
    _current -= amount;
    OnParameterChanged?.Invoke(new ChangeMeterContext(this, -amount));

    if (_current <= 0f)
        OnDeath?.Invoke();
}
```

```csharp
// Subscriber — already holds a direct reference, so coupling is free
public override void _Ready()
{
    _lifeComponent.OnDeath += HandleDeath;
    _lifeComponent.OnParameterChanged += HandleParameterChanged;
}

public override void _ExitTree()
{
    _lifeComponent.OnDeath -= HandleDeath;
    _lifeComponent.OnParameterChanged -= HandleParameterChanged;
}
```

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Signal delegate | PascalCase + `EventHandler` suffix | `DiedEventHandler`, `HitReceivedEventHandler` |
| Signal emission | Generated wrapper method | `EmitSignalDied(context)` |
| Signal name reference | `SignalName` enum | `SignalName.Died` |
| C# event field | `On` + noun | `OnDeath`, `OnParameterChanged` |
| Subscriber method | `On` + source + event, or `Handle` + event | `OnEnemyDied()`, `HandleDeath()` |

---

## What Never to Do

- **String-based signal emission** — `EmitSignal("died")` is untyped and refactor-invisible. Always use the generated wrapper.
- **Subscribing without unsubscribing** — missing `-=` or `SafeUnsubscribe` in `_ExitTree()` causes callbacks on freed nodes. Silent, hard to reproduce.
- **Static C# events on manager classes** — this is a hidden singleton. Use Signals or the future EventBus instead.
- **Connecting signals in `_EnterTree()` without disconnecting in `_ExitTree()`** — same problem as above.
