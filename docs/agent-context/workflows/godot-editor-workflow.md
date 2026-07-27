# Godot Editor Workflow

Agents cannot interact with the Godot editor GUI. This document describes how to deliver Godot implementation work so the user can integrate it without guesswork.

---

## The Constraint

Agents can write and edit files on disk. They cannot:
- Open the Godot editor or click inside it
- Create Nodes or Scenes through the editor UI
- Add components or children via the Scene panel
- Drag assets onto exported fields in the Inspector
- Set property values visually in the Inspector

Godot auto-reimports resources when they change on disk. Everything else requires explicit editor steps.

---

## Delivery Format

Every Godot implementation task lands as two things:

**1. Scripts / Resources / Scene files** — written to disk, picked up automatically by Godot.

**2. Integration steps** — explicit numbered instructions for anything requiring the editor. Use this template format exactly:

```
In Godot:
1. In the FileSystem panel, navigate to Scenes/Actors/
2. Right-click → New Scene. Name it "Kael.tscn"
3. Set the root node type to CharacterBody2D. Rename it "Kael"
4. Attach script: Scripts/Actors/Kael.cs
5. In the Inspector, set Max HP: 100
6. Add child node: CollisionShape2D. Set shape to CapsuleShape2D (12 x 28)
7. Add child node: Sprite2D. Assign texture: Assets/Art/Player/kael_idle.png
```

Be specific: exact node types, exact property names, exact asset paths, exact values. Never say "configure it appropriately."

ArcwingRacers uses GDScript (not C#). All script examples should use GDScript conventions.

---

## Resource Files

Godot `Resource` subclasses (`.tres`) can be created as text files on disk and will be recognized on reimport. Binary `Resource` files (`.res`) are managed by the engine.

For data-heavy resources (character stats, ability definitions, element tables), write them as `.tres` plain text format. Tell the user the exact path and any Inspector verification steps needed after reimport.

Add `[GlobalClass]` (potentially and `[Tool]`) attributes to C# Resource subclasses where appropriate so they appear in the Inspector's "Create New Resource" dialog.

---

## Scene Files

For complex scenes with many children and wired signals, prefer writing a `[Tool]` editor script that creates the scene programmatically, rather than listing 20+ manual steps. Place it under `Scripts/Tools/Editor/`, name it with a `Setup` prefix.

```gdscript
# SetupStartingLine.gd
# One-shot editor tool — creates the StartingLine scene programmatically.
# Safe to delete after running, or keep for re-running if the scene is lost.
@tool
extends EditorScript

func _run():
	# ... scene construction code
	print("StartingLine scene created at Content/Scenes/starting_line.tscn")
```

Always end with a `GD.Print` confirming what was created and where.

---

## Signals

When wiring signals that require editor connections (i.e., connecting via the Node panel rather than code), list them explicitly:

```
In Godot (Node panel → Signals):
1. Select node: Kael
2. Connect signal: hit_received → HUDManager.OnPlayerHit()
3. Connect signal: died → GameManager.OnPlayerDied()
```

Prefer code-based signal connections (`Connect()` or `+=` in `_Ready()`) over editor-wired connections wherever possible — code connections are version-controlled and visible to agents.

---

## Communicating Results

After the user completes integration steps:
- Tell them what they should see in the Scene tree or Inspector to confirm it worked.
- Describe the first play-mode test (e.g., "Enter Play Mode — Kael should appear at the origin and respond to arrow keys").
- List any known gotchas (e.g., "If the sprite is invisible, check the CanvasItem → Visibility layer").
