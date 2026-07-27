# Tilemaps

Level geometry is authored in LDtk (`.ldtk` project files under `Assets/Levels/`) and imported into Godot via the `ldtk-importer` addon (`addons/ldtk-importer/`). LDtk is the source of truth — reimporting always overwrites values with what's in the `.ldtk` file, discarding manual edits to imported nodes.

## Import Structure

Each imported Level becomes a scene:
- Root `Node2D`, named for the level.
- `Layers` child `Node2D` — one `TileMapLayer` node per LDtk layer (Godot 4 uses `TileMapLayer`, not a single multi-layer `TileMap`).
- `Entities` child `Node2D` — entity placeholder nodes, or real scenes if an entity's `_Scene` field points at an existing `.tscn`.

TileSet resources (`tilesets/tileset<N>x<N>.res`) are generated per unique tile grid size and shared across levels using that tileset — editing one shared TileSet's Physics Layers or Render Layers affects every level using it.

## Collision Setup

LDtk has no per-tile collision authoring UI. Physics collision is added manually, once, on the generated TileSet resource:
1. Open the tileset (`tilesets/tileset<N>x<N>.res`).
2. Add a Physics Layer in the TileSet pane.
3. Paint collision shapes per tile (or select multiple tiles + `F` for the default full-tile shape).

This survives reimport — the importer preserves manual TileSet edits (Physics Layers, Render Layers) even though it treats the rest of the `.ldtk` file as authoritative.

## Reimport Gotchas

- **Tiles removed in LDtk can leave stale tiles behind in Godot.** The importer updates rather than fully clears existing `TileMapLayer` nodes on reimport — if a level looks wrong after editing in LDtk, check for leftover tiles before assuming a logic bug.
- **Entity import is the least reliable part of the pipeline.** Verify entity placement and field values after any LDtk-side entity change; don't assume a clean reimport.
- **`Pack Levels`** (an import option) bundles each level as its own scene file instead of a single World scene — decide this once, early; switching later re-shuffles file structure.

## Entities → Scenes

An LDtk entity field named `_Scene` can point at an existing `.tscn` path or scene name — the importer instantiates that scene directly in place of a placeholder node, and best-effort maps matching entity fields onto matching exported properties on the instanced scene's root. Use this to place enemies, spawn points, and triggers directly in LDtk rather than hand-wiring them after import.

## Custom Data & Post-Import Scripts

Per-tile custom data (defined in LDtk) imports as a Custom Data Layer on the TileSet, stored as a string per tile — parse further custom formats (JSON, enums) in a `@tool` post-import script rather than at runtime. Post-import scripts hook in at four points (Entity / Level / World / Tileset) and can modify the generated scene or resource before it's saved. Place these under `Scripts/Tools/Editor/` per `agent-context/workflows/godot-editor-workflow.md`.

## Rendering & Layering

No chunk/individual rendering mode split exists — `TileMapLayer` batches automatically. Apply the project's standard Z-index rules from `technical/code-standards.md` per `TileMapLayer` node (background/gameplay/foreground) rather than any tilemap-specific sorting setting.

---

This doc does not cover runtime procedural tilemap generation — Fantasy X levels are hand-authored in LDtk, not generated at runtime. [TBD — confirm which fork/version of the ldtk-importer addon is in use if the above doesn't match what you see in-editor; import behavior has shifted across plugin releases.]
