# Code Standards

Godot 4.7, C# (Godot .NET), Forward Plus (Desktop). These are firm conventions — not suggestions. Deviations require a decision record in `decisions/adrs/`.

---

## Rendering Resolution

**Internal resolution:** 640×360 (pixel-art base). Configured via project stretch settings (viewport mode, integer scaling).
See [art-direction.md](../game-design/art-direction/art-direction.md) for full visual guidelines, layout margins, and character portrait dimensions.

---

## Godot Version

Targeting **Godot 4.7 (C# / .NET 8.0)**. Use documentation specific to Godot 4.7 to prevent API discrepancies.

- Manual: https://docs.godotengine.org/en/4.7/
- Best Practices: https://docs.godotengine.org/en/4.7/tutorials/best_practices/index.html

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Class / Struct | PascalCase | `PlayerBody` |
| Interface | `I` prefix + PascalCase | `IInteractable` |
| Method | PascalCase | `CastSpell()` |
| Public property | PascalCase | `MaxHPRegen` |
| Private field | `_camelCase` | `_lifeBar` |
| Constant | UPPER_SNAKE_CASE | `GRAVITY_PX` |
| Boolean | `is` / `has` / `can` prefix | `isDead`, `hasComponent` |
| Signal Delegate | PascalCase + `EventHandler` suffix | `[Signal] public delegate void HitReceivedEventHandler(...)` |
| Timer callback | Descriptive verb phrase | `FadeOutTimer()` |
| Collection | Plural noun | `_captives`, `_enemies` |
| Scene node name | PascalName_PascalType | `CameraMount_SpringArm3D`, `HoverRaycasts_Node3D` |

**Never** use abbreviations (`mgr`, `ctrl`, `tmp`) — names should be self-explanatory at a glance.

### Godot C# Naming Specifics:
* **Lifecycle Overrides**: Prefix with an underscore and use PascalCase (e.g., `_Ready()`, `_Process()`, `_PhysicsProcess()`).
* **Signal Emission**: Always prefer the code-generated wrapper methods (e.g., `EmitSignalHitReceived(...)`) over generic string-based `EmitSignal(SignalName.HitReceived, ...)`.
* **Custom Signal Connection**: For UI and game systems, use `SafeSubscribe` and `SafeUnsubscribe` extensions from [NodeExtensions.cs](../../Scripts/Utility/Extensions/Nodes/NodeExtensions.cs) (e.g., `button.SafeSubscribe(BaseButton.SignalName.Pressed, OnButtonPressed)`) to avoid duplicate subscriptions. Use C# native event syntax (`+=` / `-=`) or standard `Connect` only where performance warrants or standard structures require it.
* **Autoload Access**: C# Autoloads must expose a static `Instance` property initialized in `_EnterTree()` for direct type-safe access:
  ```csharp
  public static GlobalGameState Instance { get; private set; }
  public override void _EnterTree() { Instance = this; }
  ```

---

## File & Folder Structure

One class per file. Filename must exactly match the class name.

```
Demo2/
  addons/                 ← third-party plugins (Dialogic, LimboAI, etc.) — never put project code here
  Assets/
    _ProjectMeta/         ← sorts above ad-hoc imports; project-only metadata
    Art/
      Player/             ← Kael/, Rina/ — entity-first: sprites, animations, masks per protagonist
      Enemies/            ← one subfolder per enemy type once it has multiple assets
      Environment/        ← level art, doodads, interactables
        Objects/
        Tilesets/
        [LocationName]/   ← per-area art (e.g. Train_Town, Backyard_Woods)
      Items/
        Bubbles/
      Magic/
        Orbs/
        Projectiles/
      UI/
      Shaders/
      CustomNodes/Icons/  ← custom node class icons for the editor
    Audio/
      Music/
      SFX/
    CustomResources/      ← .tres data: Abilities, Items, Stats, Matchups, Loadouts, etc.
    Dialogic/             ← dialogue plugin assets (characters, timelines, styles)
    Fonts/
    Levels/               ← LDTk projects, exported level data, tileset atlases
    Materials/
    Themes/               ← Godot Theme resources for GUI
  Scenes/
    Actors/               ← Player, Enemies, NPC — reusable character scenes (.tscn)
    Autoloads/
    Camera/
    Environment/          ← platforms, destructibles, interactables
    Hitboxes/
    Items/
    UI/                   ← HUD, menus, debug overlays
    Tools/                ← one-shot [Tool] setup scenes
  Scripts/
    Actors/
    Autoloads/
    Components/
    DataContainers/
    GameplayAbilities/
    Items/
    Levels/
    UI/
    Utility/              ← extensions, constants, pooling helpers
    ErrorLog.txt          ← engine/compile errors copied here for agent debugging
    sample_code.txt       ← paste-bin for external reference snippets
  docs/                   ← design + technical docs (this repo's working layer)
```

**Rules:**
- No `.cs` scripts in `Assets/` — scripts live under `Scripts/` only.
- Reusable entities are `.tscn` scenes under `Scenes/`; serializable data/config is `.tres` under `Assets/CustomResources/` (or co-located with the plugin that owns them, e.g. `Assets/Dialogic/`).
- `.godot/` and `Library/` are engine-generated — do not hand-edit or treat as source of truth.
- Documentation lives in `docs/`; lore and full design detail live in the Obsidian Vault (`FantasyX_Obsidian/`).

Before importing or committing any non-original audio asset, see `technical/audio-licensing.md` — every such file needs a license-traceability entry there.

---

## Script Architecture

**The decision hierarchy:**

1. **Plain C# Class** — Pure data models, stateless helpers, or logic decoupled entirely from Godot. Managed by .NET GC. Fast and easiest to unit test.
2. **RefCounted (`Godot.RefCounted`)** — Lightweight classes that need to emit Godot signals, bridge between C# and GDScript, or interact with engine APIs, but do not require scene tree or disk storage. Automatically managed by Godot's C++ reference counting.
3. **Custom Resource (`Godot.Resource`)** — Subclass of `RefCounted`. Used for static configuration assets, item/ability databases, or element presets. Saved to disk as `.tres` files. Must be marked with `[GlobalClass]`.
4. **Godot Node (`Godot.Node` or Subclasses)** — Used only when the script needs scene tree presence, visual rendering, physics colliders, or lifecycle ticking.

### GDScript Typing

**Always annotate types explicitly. Never use the `:=` (walrus) inference operator.** Inferred types can differ from the intended type and surface only as runtime-exclusive compilation errors when the script loads — the exact failure mode that GDScript's explicit syntax exists to prevent.

```gdscript
# Wrong — inferred type (runtime-exclusive errors)
var speed := 30.0
var mid := (a + b) * 0.5

# Right — explicit
var speed: float = 30.0
var mid: Vector3 = (a + b) * 0.5
```

Exceptions: only where dynamic typing is genuinely required (polymorphic `Variant` values), and even then annotate `Variant` explicitly rather than inferring.

---

### GDScript Doc Comments on `@export` Variables

**Every exported variable gets a `##` doc comment block** describing (1) what the variable affects, (2) its intended purpose, and (3) example effects of higher / lower / different values (e.g. "higher = faster", "lower = more drift"). They render as inspector tooltips and show up in the class reference.

**Formatting rules:**
- Each section (description / purpose / examples) lives on its **own single line** in code — do not split a sentence across lines.
- Separate sections with **`[br]` appended to the end of the line** (Godot's BBCode line break) — not a blank `##` line, not a trailing-space markdown break.
- The final line has no `[br]`.
- Same template and `[br]` rule applies to enum-member doc comments.

```gdscript
## Top forward speed in m/s reached when the accelerator is held at full input.[br]
## Intended purpose: defines the pod's base performance ceiling; the boost charge threshold is derived from this value.[br]
## Higher = faster pod at cruise; lower = slower pod, easier to charge boost.
@export var max_speed: float = 30.0
```

---

### `@export` vs Custom Resource

| Use | When |
|---|---|
| `@export` on a node | Scene-specific wiring: node references, visual toggles, one-off tweaks. Data that only this scene instance cares about. |
| Custom `Resource` class | Any data that should be **persistent, reusable, or shared** between scenes. Survives scene corruption. Can be repurposed across different scenes. |

**Guideline: when in doubt, make it a Resource.** A `.tres` file on disk is never accidentally lost to scene corruption, can be assigned to multiple scenes, and can be iterated on independently of any scene. Scene exports are for *wiring*, not *data*.

A good litmus test: if you could imagine wanting the same values on a different scene, or wanting to swap between presets in the inspector, it should be a `Resource`.

```gdscript
# Bad — data embedded in the scene
@export var mana_value_percent: float = 0.05
@export var respawn_time: float = 8.0

# Good — data lives in a .tres, scene just references it
@export var crystal_data: ManaCrystalResource
```

**Resource files (`.tres`/`.res`)** are Godot's serialized data containers. Create a `class_name` script extending `Resource`, define your exports, then instantiate presets in the inspector and save as `.tres` files. These live in `Content/Data/` (or wherever is appropriate for the system).

### Scene Initialization from Data Resources

Every scene that consumes a data Resource must expose an `init(data)` method. This keeps creation explicit, works whether the resource is assigned in the inspector or at runtime, and avoids scattering resource-reading logic across random call sites.

```gdscript
# mana_crystal.gd
extends Area3D

@export var crystal_data: ManaCrystalResource   # assigned in inspector or via init()

func init(data: ManaCrystalResource):
    crystal_data = data
    _apply_data()

func _ready():
    if crystal_data:
        _apply_data()

func _apply_data():
    sprite.texture = crystal_data.sprite
    respawn_timer.wait_time = crystal_data.respawn_time
```

Two paths:
- **Editor placement:** assign `crystal_data` in the inspector → `_ready()` applies it.
- **Runtime spawn** (combat drops, pickups): call `init(data)` after instantiate — the method sets the export and applies.

This replaces ad-hoc property copying after `instantiate()`. Never do:

```gdscript
# Wrong — scattering raw values, defeats the Resource pattern
var crystal = scene.instantiate()
crystal.mana_value_percent = 0.05
crystal.respawn_time = 8.0

# Right — assign a data Resource, _ready() applies it
var crystal = scene.instantiate()
crystal.crystal_data = preload("res://Content/Data/pickups/mana_crystal_small.tres")
add_child(crystal)   # _ready() reads crystal_data and applies
```

One scene, N `.tres` files. The data drives appearance and behavior; the scene is a generic shell. Per-instance overrides (e.g. partial-mana combat drops) use an instance property that shadows the Resource — they never write to the Resource itself.

Pattern for creating a custom data Resource:

```gdscript
# Content/Scripts/Data/mana_crystal_resource.gd
class_name ManaCrystalResource
extends Resource

@export var display_name: String = "Small Crystal"
@export var mana_value_percent: float = 0.05
@export var respawn_time: float = 8.0
@export var sprite: Texture2D
```

Then right-click in the FileSystem dock → New Resource → `ManaCrystalResource` → set values → Save As `mana_crystal_small.tres`.

### Hard Rule: Resources Are Read-Only at Runtime

**Never mutate a Resource's properties at runtime.** Resources are shared references — writing to one affects every scene that references it. A `.tres` is a template, not instance state.

```gdscript
# WRONG — corrupts the shared .tres for all other crystals
crystal.crystal_data.mana_value_percent = percent

# RIGHT — store the override on the instance, not the resource
crystal.override_value_percent = percent
```

Exception: `@tool` scripts that generate or edit resources in the editor. Those run in editor context only — never in a running game.

If you need per-instance variation of a resource-backed value, add an instance property that shadows or overrides the resource field. The resource itself stays pristine.

**Singletons / Autoloads:** Use sparingly. Prefer Custom Resource files for shared data configuration. When a global coordinator is necessary, register it as an Autoload singleton in `project.godot` and expose a static `Instance` property.

**Composition over inheritance.** Keep nodes small and focused. Prefer adding child component nodes (e.g. `HealthComponent` (Node), `HitboxComponent` (Area2D)) under a root gameplay entity rather than building deep inheritance hierarchies.

**Decision logic / state machines:** See `technical/state-machines.md` for choosing between a plain conditional, a code FSM, and a Behavior Tree.

**Static classes** are for stateless utilities only (`MathUtils`, `LayerMasks`). Never for game state.

**Interfaces** for any cross-system contract (`IInteractable`, `IDamageable`). This keeps systems decoupled and testable.

---

## Godot Lifecycle Patterns

| Method | Use for | Do NOT use for |
|---|---|---|
| `_EnterTree()` | Early setup. Registering with Autoloads or global coordinators. | Fetching child node references (they are not ready yet). |
| `_Ready()` | Caching child node references, local initialization, connecting child signals. | Registering dynamic listeners that need to be re-bound when entering/exiting the tree. |
| `_Process(double delta)` | Frame-rate dependent updates (visual rotation, UI updates, camera smoothing). | Physics calculations, movement, direct physics queries, or expensive lookups. |
| `_PhysicsProcess(double delta)` | Fixed physics tick updates (velocity math, movement resolution, area tracking, timers). | Pure visual-only interpolation that should match rendering framerate. |
| `_ExitTree()` | Teardown logic. Unsubscribing from external/global signals and event buses. | Destructive tasks that assume child nodes are still fully active. |

### Implementation Guidelines:
* **Reference Caching**: Use `[Export]` when a reference should be swappable/experimentable via the Inspector, or when the target's path is indirect or hard to discern from script alone (refactor-safe). Use `GetNode<T>("Path")` or the `%UniqueName` shorthand in `_Ready()` when the scene structure is fixed and guaranteed — a purely internal implementation detail not meant for Inspector-level tweaking.
* **Empty Overrides**: Never define empty lifecycle overrides (like `_Process` or `_PhysicsProcess`) in C# scripts. They incur unnecessary marshalling overhead across the C++/C# engine boundary.
* **Tick Management**: Proactively call `SetProcess(false)` and `SetPhysicsProcess(false)` in `_Ready()` if a Node does not require constant frame ticking. Enable them only when active.
* **Casting Delta**: Always cast `delta` to a `float` when doing vector calculations: `Position += velocity * (float)delta;`.
* **Destruction via QueueFree**: Always use `QueueFree()` to destroy nodes. Never call `Free()`. Because `QueueFree()` triggers `_ExitTree()` at the end of the frame, place all cleanup and event unsubscriptions (`-=`) inside `_ExitTree()`.
* **Fast-Fail Architecture**: Do not write overly defensive code. Do not pepper scripts with `IsInstanceValid()` or null-checks unless a null or freed state is an expected, deliberate runtime state. Let missing references fail loudly and immediately to surface bugs.

---

## Scenes & Scene Organization

**Every runtime entity is a scene.** Reusable entities — characters, enemies, UI panels, projectiles, environmental objects — live as `.tscn` files. A node that only ever exists inside one specific parent scene and is never reused doesn't need its own file; everything else does.

**Use inherited scenes for variations.** Character skins, NPC variants, and enemy subtypes should inherit from a base scene (right-click → New Inherited Scene) rather than duplicating and editing separately. Changes to the base propagate to all inheritors.

**Scene hierarchy — use `Node` as named grouping containers:**
```
Scene Root (Node2D, CharacterBody2D, etc.)
  ── World ── (Node)
  ── Characters ── (Node)
  ── UI ── (Node)
  ── Audio ── (Node)
```
`Node` (base class) has no overhead. Don't use a typed node (`Node2D`, `Control`, etc.) as an organizer unless it genuinely needs spatial or UI properties.

**Persistent managers live as Autoloads, not in scenes.** All global systems are registered in `project.godot` and persist automatically across scene changes. Current Autoloads:

| Autoload | Role |
|---|---|
| `GlobalGameState` | Central runtime state — current player reference, actor registry, time-scale control (slow-mo, tween-time) |
| `GameWorldManager` | World lifecycle — spawns `GameWorld`, loads the LDTk act, registers actors/players per level, handles player switching and camera/UI setup |
| `GameApplicationManager` | Window management — positioning, canvas scale calculation for integer-scaled pixel art layers |
| `GlobalElementalDictionary` | Elemental data — matchup/multiplier/resistance lookups and the full spell chart for both protagonists by slot and element |
| `ItemDropSpawner` | Pooled item drop spawning with physics launch parameters |
| `FloatingTextManager` | Pooled floating combat text (damage numbers, parameter changes) |
| `SceneLoader` | Async scene loading coordination |
| `AppConfig` | Persistent application configuration (settings, preferences) |
| `ProjectMusicController` | Music playback and transitions (Maaacks plugin) |
| `ProjectUISoundController` | UI sound effects (Maaacks plugin) |
| `Constants` | Stateless game constants (`GRAVITY_PX`, `PX_PER_TILE`, etc.) |
| `LayerNames` | Named physics and render layer constants (addon) |
| `Globals_GD` | GDScript debug visibility flag and toggle signal |
| `DebugManager` | In-game debug overlay tooling |
| `LimboConsole` | In-game developer console (plugin) |
| `Dialogic` | Dialogue system (plugin) |

Before registering a new Autoload, read `technical/singleton-controllers.md`.

---

## 2D Physics, Rendering, & Camera

### Movement (Kinematic Bodies):
* All moving characters or actors must inherit from `CharacterBody2D`.
* Movement calculations must execute inside `_PhysicsProcess(double delta)`.
* Set the `Velocity` property and call `MoveAndSlide()` to resolve collisions and update built-in state checks (like `IsOnFloor()`).
* Do not set `Position` or `GlobalPosition` directly except for instant teleports, as this bypasses physics sweeps.

### Collisions & Queries:
* **Triggers**: Use `Area2D` with `BodyEntered`/`BodyExited` signals for trigger volume detection.
* **Direct Collisions**: Query `GetSlideCollisionCount()` and `GetSlideCollision(index)` on `CharacterBody2D` to react to obstacles or walls hit during movement.
* **Raycasts**: Use `RayCast2D` nodes for editor-placed directional sensors (e.g., ground-edge detectors for AI).

### Rendering & Layering:
* Manage render sorting layers using Godot's built-in Node Z-Index values or CanvasLayers. Standard layout:
  * Background: Z-index < 0
  * Gameplay (Player, Enemies, Environment Tiles): Z-index = 0
  * Foreground/Weather/Particles: Z-index > 0

### Camera Customization & Control:
* Use [PlayerCamera.gd](../../Scripts/Camera/PlayerCamera.gd) to customize and control camera tracking behaviors.
* Set camera limits (margins) to match the active level boundaries to prevent the camera from revealing empty void regions (use `set_camera_limits_from_level(level)`).
* Screen shake must be applied via camera `Offset` modification (a feature to be implemented) to prevent fighting with the drag-margin smoothing.

See `technical/collisions.md` for 2D physics-query correctness rules that expand on the rules above.

---

## Events & Messaging

**Three-tier model — pick the right tool:**

| Tier | Tool | Use when |
|---|---|---|
| 1 | Godot `[Signal]` | Node-to-node or node-to-autoload communication. Inspector-connectable. Cross-system but structurally related. |
| 2 | C# `EventBus` Autoload | [TBD] Fully decoupled cross-system broadcast with no direct node references. Evaluate when Tier 1 creates unacceptable coupling. |
| 3 | C# `event Action` | Same-class or tightly coupled pair. High-frequency callbacks where signal overhead matters. |

**Never use strings to identify anything** — signals, layers, tags, animation parameters. Use `SignalName` constants or enums.

**Unsubscribing is mandatory.** A subscriber that outlives its publisher will silently hold references and may fire on freed nodes. Always unsubscribe in `_ExitTree()`.

**Use `SafeSubscribe`/`SafeUnsubscribe` from `NodeExtensions.cs`** for Tier 1 connections made in code — prevents duplicate subscriptions. Use `Connect`/`+=` directly only where the extension doesn't apply.

See `technical/game-events.md` for the specific event architecture used in this project.

---

## Async & Timers

**Avoid `async` unless proven necessary.** Gameplay architecture handles most sequencing through signals, `AnimationPlayer` call frames, and Tween callbacks — none of which require `async`. Only reach for it when a method genuinely needs to suspend at a signal boundary.

**Default to `async void` for gameplay.** In signal-driven gameplay code, nothing awaits the result of a callback. `async void` is fire-and-forget and correct for this context:
```csharp
// Fine for gameplay — no caller is awaiting this
private async void OnCutsceneTriggered()
{
    await ToSignal(CutsceneTimer, Timer.SignalName.Timeout);
    EmitSignalCutsceneFinished();
}
```

**Use `async Task` only for infrastructure contexts** where the caller needs to track completion or propagate failure:
- **Scene loading** — loading a large map without freezing a loading spinner animation.
- **Save/load operations** — preventing micro-stutters during disk I/O.
- **Web requests** — leaderboards, announcements, patch notes, DLC/mod downloads.

```csharp
// async Task — caller needs to await completion and handle failure
public async Task LoadSceneAsync(string path)
{
    await ToSignal(GetTree().CreateTimer(0f), SceneTreeTimer.SignalName.Timeout); // defer one frame
    // ... resource loading logic
}
```

**Await signals with `ToSignal`.** The standard pattern for suspending on engine events:
```csharp
private async void PlayCutscene()
{
    CutsceneTimer.Start();
    await ToSignal(CutsceneTimer, Timer.SignalName.Timeout);

    Tween tween = CreateTween();
    tween.TweenProperty(myNode, "modulate:a", 1.0f, 0.5f);
    await ToSignal(tween, Tween.SignalName.Finished);

    EmitSignalCutsceneFinished();
}
```

**Timers: prefer exported `Timer` nodes over inline creation.** `GetTree().CreateTimer(...)` is hard-coded and Inspector-invisible. Prefer a `Timer` node in the scene with exported configuration so durations can be tuned without touching code. Reserve inline `CreateTimer` for truly one-off, infrequent delays where that control is overkill.

```csharp
// Preferred — Inspector-configurable, reusable
[Export] public Timer AbilityTimer { get; set; }

// Acceptable only for simple, infrequent, one-off delays
await ToSignal(GetTree().CreateTimer(2.0f), SceneTreeTimer.SignalName.Timeout);
```

**Tweens: cache when reused, create fresh when not.** `Tween` instances are designed to be created per-animation via `CreateTween()`. Cache a reference when you need to `.Kill()` a prior animation before starting a new one — otherwise create a new one each time.

```csharp
private Tween _fadeTween;

private void StartFade()
{
    _fadeTween?.Kill();
    _fadeTween = CreateTween();
    _fadeTween.TweenProperty(this, "modulate:a", 0f, 0.3f);
}
```

---

## Inspector & Editor Conventions

**Field exposure:** Use `[Export]` to expose properties to the Inspector. Always export **auto-properties**, not bare fields. Add a private backing field only when the setter needs to perform work (clamping, validation, triggering a side effect).

```csharp
// Wrong — bare field
[Export] private float _speed;

// Right — auto-property
[Export] public float Speed { get; set; }

// Also right — property with setter logic
private float _speed;
[Export] public float Speed
{
    get => _speed;
    set => _speed = Mathf.Clamp(value, 0f, MaxSpeed);
}
```

**Organization:** Use `[ExportGroup("Label")]` and `[ExportSubgroup("Label")]` to create collapsible inspector groups.

```csharp
[ExportGroup("Movement")]
[Export] public float Speed { get; set; }

[ExportGroup("References")]
[Export] public Marker2D SpawnPoint { get; set; }
```

**Range hints:** Use `[Export(PropertyHint.Range, "min,max")]` (or `"min,max,step"`) to constrain inspector sliders. These restrict what the inspector slider can set — they do not clamp the value at runtime.

```csharp
[Export(PropertyHint.Range, "0,100")] public float MaxHP { get; set; }
[Export(PropertyHint.Range, "0,20,0.5")] public float Speed { get; set; }
```

**Documentation comments:** Add `/// <summary>` XML doc comments to all exported properties, signals, and any method or class whose name alone doesn't fully convey its purpose. Every exported member gets one — they appear as inspector tooltips once Godot C# doc generation support lands (PRs #83505 / #118210, targeting 4.x). Write them now; they're valid C# regardless and will activate automatically.

```csharp
/// <summary>
/// Maximum HP for this unit. Does not clamp at runtime — use the setter for that.
/// </summary>
[Export(PropertyHint.Range, "1,999")] public float MaxHP { get; set; } = 100f;
```

**Node references:** Prefer `@onready` lookups and reserve `@export` for cases that genuinely need inspector wiring. Reference lookup hierarchy (cheapest → most expensive):

1. **Direct child** → `@onready var mesh := $BeamMesh`. No inspector wiring. Breaks only if the child is renamed/reparented.
2. **Unique-name node** → set *Unique Name* (`access as unique name`) on the target in the editor, then `@onready var wing := %Wing_Left`. Lets a distant node be fetched with `@onready` after a one-time editor setup — zero ongoing wiring, and refactor-safe against reparenting. Example: `PodController.gd` → `%Wing_Left` / `%Wing_Right`.
3. **Otherwise** → `@export` typed reference, wired in the inspector. Use only when the target is far away and non-trivial to locate, or genuinely swappable from the inspector.

Every unwired `@export` node reference is a silent null that makes code early-return. `@onready` / `%UniqueName` eliminate the wiring step entirely — whenever a node reference can be a direct child or a unique-named node, it must not be an `@export`. Only the third case creates a user action item (see **Editor Handoff** above).

```csharp
// Wrong — export for a direct child (silent null until wired)
[Export] public MeshInstance3D BeamMesh { get; set; }

// Right — direct child fetched in _Ready
private MeshInstance3D _beamMesh;
public override void _Ready() => _beamMesh = GetNode<MeshInstance3D>("BeamMesh");

// Right — distant node with Unique Name set in the editor, zero wiring
private Marker2D _spawnPoint;
public override void _Ready() => _spawnPoint = GetNode<Marker2D>("%SpawnPoint");
```

**Missing required references:** Godot has no `[RequireComponent]` equivalent. Assert required exports in `_Ready()` to fail loudly (fast-fail, per existing rules).

```csharp
public override void _Ready()
{
    Debug.Assert(SpawnPoint != null, $"{Name}: SpawnPoint export is not assigned.");
}
```

**Editor validation:** Use `[Tool]` scripts with `Engine.IsEditorHint()` guards. Property setters are the natural place for this.

```csharp
[Tool]
public partial class HealthBar : Node
{
    private float _maxHP;
    [Export] public float MaxHP
    {
        get => _maxHP;
        set
        {
            _maxHP = value;
            if (Engine.IsEditorHint()) UpdateBarDisplay();
        }
    }
}
```

**Inspector buttons:** Use `@export_tool_button("Label")` in GDScript or `[ExportToolButton("Label")]` in C# (Godot 4.5+). Never use a bool-with-setter hack.

```gdscript
# GDScript
@export_tool_button("Generate") var generate: Callable = _generate
```

```csharp
// C#
[ExportToolButton("Generate")]
public Callable Generate = Callable.From(Generate);
```

**Reacting to transform changes in `@tool` scripts:** To make an editor tool script respond to gizmo drags (node rotation/move in the 3D or 2D viewport), use `set_notify_transform(true)` in `_ready()` **guarded by `Engine.is_editor_hint()`**, then handle `NOTIFICATION_TRANSFORM_CHANGED` in `_notification()`. Do **not** poll the transform in `_process()` — it misses gizmo edits in the editor viewport. Use `is_equal_approx` (not `==`) when guarding against redundant re-writes to avoid float-drift false matches.

```gdscript
@tool
class_name Skybox extends Node3D

func _ready() -> void:
	if Engine.is_editor_hint():
		set_notify_transform(true)
	_update_sky_rotation()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_sky_rotation()

func _update_sky_rotation() -> void:
	# ... reads global_rotation, writes dependent properties
	if env.environment.sky_rotation.is_equal_approx(sky_rotation):
		return
	env.environment.sky_rotation = sky_rotation
```

Notes:
- `set_notify_transform(true)` must be editor-guarded so runtime does not pay for transform-change notifications.
- `_process()` polling is the wrong tool here: it works at runtime but does not reliably pick up editor gizmo transform edits, so an in-editor visual will appear stale.
- Setting exported values or dependent resources from a tool script does not repaint the viewport or refresh the Inspector on its own; the notification-driven write path above is what keeps the editor visuals in sync.

---

## Editor Handoff — User Action Items (MANDATORY)

**Any change that requires editor interface interaction creates user action items. The agent MUST explicitly surface them — never assume the user notices a change they didn't write.**

When a change adds or alters anything the user must touch in the Godot editor, the agent's final message MUST include a clearly marked `ACTION REQUIRED` callout listing every follow-up item, with the exact node path and what to set.

This applies to, but is not limited to:

- **New `@export` (or `[Export]`) variables** that need inspector wiring — especially typed node references / `NodePath` exports (`@export var wing_left: Node3D`). Any export with a non-safe default that the scene must override.
- **New scene nodes** the user may want to inspect, move, or verify.
- **Renamed / reparented nodes** — breaks existing inspector references.
- **New input actions, autoloads, project settings, layers/masks** — anything persisted to `project.godot`.
- **New signals / signal connections** that must be wired in the editor.

Rules:

1. **Exports default to safe, functional defaults when possible** so an unwired export fails softly. A node reference export that will be null if not wired must be explicitly called out as a required wiring step.
2. **Call out before the code lands, and after.** If exports were added in a previous turn, the current turn's report must still list them as outstanding action items until the user confirms they've done them.
3. **Do not say "done" when a change depends on editor work the user hasn't performed.** Say what the code does *and* what the user must still do.
4. **When exports are the difference between working and not working** (e.g. a null node reference makes a function early-return), say so in plain language — "the wings do nothing until you wire `wing_left`/`wing_right`."

Example callout format:

```
## ACTION REQUIRED (editor)
1. Select `/Arcwing` → Inspector → `wing_left` = `Visuals/Wing_Left`, `wing_right` = `Visuals/Wing_Right`.
2. Select `/Visuals/Rigs/Beam_Left` → Inspector → `beam_mesh` = `BeamMesh`.
   (Repeat for `Beam_Right`.)
```

---

## Comment & File Header Format

**Every file starts with this header:**
```csharp
// PlayerBody.cs
// Root CharacterBody2D for the player character. Handles movement, state delegation, and physics.
// Docs: game-design/gameplay/player-characters.md
//       technical/state-machines.md
```

**Inline comments:** Only write them when the *why* is non-obvious — a hidden constraint, a Godot quirk or engine-specific workaround, a deliberate non-obvious design choice. If removing the comment wouldn't confuse a future reader, don't write it.

**Never:**
- Comment what the code already says (`// increment counter`)
- Leave commented-out dead code — delete it, git has history
