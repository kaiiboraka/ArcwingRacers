# Custom Resources

`Godot.Resource` is the Godot equivalent of a data container / configuration asset. This document covers when to use it, how to set it up correctly, and gotchas to avoid.

See also: `technical/singleton-controllers.md` for when shared data belongs on a Resource vs. an Autoload.

---

## When to Use a Custom Resource

Use `Godot.Resource` (step 3 in the Script Architecture decision hierarchy — see `technical/code-standards.md`) when:

- The data is **static configuration** — item stats, spell definitions, element presets, actor data.
- The same data needs to be **shared across multiple nodes** without those nodes knowing about each other.
- The data should be **editable in the Inspector** and saved to disk as a `.tres` asset.

Do not use a Resource for data that changes at runtime and needs to persist — use `systems/game-saving.md` for that.

---

## Defining a Custom Resource

```csharp
[GlobalClass]
public partial class SpellData : Resource
{
    [Export] public string AbilityName { get; set; }
    [Export] public MagicElementType ElementalType { get; set; }
    [Export(PropertyHint.Range, "0,999")] public float BasePotency { get; set; }
    [Export] public float ManaCost { get; set; }
}
```

- **`[GlobalClass]`** is required for the resource to appear in the Inspector's "Create New Resource" dialog and be searchable by type. Always include it on project-defined Resource subclasses.
- All the `[Export]` rules from `technical/code-standards.md` apply — use auto-properties, `[ExportGroup]` for organization, `/// <summary>` doc comments on exported members.
- Resources are `RefCounted` — managed by Godot's reference counting, not the .NET GC.

---

## Runtime Mutation Warning

Modifying a Resource asset's fields at runtime **persists to disk in the editor** (changes survive after stopping Play Mode) but is **lost on exit in a build** — builds cannot write back to `.tres` files. Never treat runtime Resource mutation as a save mechanism. Use `systems/game-saving.md` for actual persistence.

If you need to mutate a Resource at runtime without affecting the shared asset, duplicate it first:

```csharp
// Wrong — mutates the shared asset
_spellData.BasePotency = 999f;

// Right — operates on a per-instance copy
var instanceData = (SpellData)_spellData.Duplicate();
instanceData.BasePotency = 999f;
```

---

## Organizing Resources

Resource assets live under `Assets/CustomResources/`, organized by category:

```
Assets/CustomResources/
  ElementalData.tres
  Abilities/
    Player/
      Fire/
        SpellData_Fire_Attack_Kael.tres
        ...
  ActorData/
  Items/
```

The `GlobalElementalDictionary` Autoload is the runtime access point for elemental and spell data — don't load these resources directly from gameplay code when the dictionary already provides a typed lookup.

---

## Editor Tooling

Resources support `[Tool]` scripts and `[ExportToolButton]` for editor-time utilities (generating default assets, reloading data, etc.). See `ElementalDictionary.cs` for a worked example of a `[Tool]` Resource with bulk asset generation.
