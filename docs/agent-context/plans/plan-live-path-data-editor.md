# Plan: Live Path-Data Editor Dock (Track Editor Phase 2 part 2)

Status: ✅ COMPLETE (2026-08). All steps landed and are working — the dock, Path Controls,
toolbar name sync, dock Save button, and saved-spline resource naming are in and verified.
The only remaining track-editor work is Phase 3 (mesh generation), tracked as a separate
follow-up. Commit trail: `8ac07fe` (dock scene), `ac4c07c` (gizmo selection + axis fix),
`ae43ed2` (addon semicolon/parse fixes), `c19f368` (path-name null fix), `73fd6ee` (Save
button + path names), `c7b8159` (spline resource names on save).
Roadmap home: `technical/tracks-and-splines.md` → Track Editor Roadmap.

## Goal

Replace raw Inspector-array editing of per-point track data with a contextual
editor dock that shows the currently-selected point's `SplinePointData`
(width, tilt/banking, recipe, recipe param, flags) and edits it with undo.

## UX decisions (confirmed with user)

- **Point selection:** left-click a point handle in the 3D viewport selects it
  (click without drag). Dock follows. Right-click still removes a point.
- **Selection highlight:** the selected point draws larger/brighter in the viewport.
- **Tilt units:** dock shows/edits banking in **degrees**; stored radians underneath.
- **Container:** right-side editor dock, visible only while a `TrackSpline` node
  is selected (contextual via `_make_visible`).
- **Dock layout (final):** top nav bar (◀ path ▶ + Save), then the **Branches** section
  (each connection row has its own Jump button), then **Path Controls** (Name + delete
  buttons), then **Point** fields, then **Flags**. Section headers render bold.
- **Save:** the nav-bar Save button mirrors the TrackSpline "Save Track to Data" export
  button (calls `_save_to_data`); saving names each persisted Spline `"{display name}_Spline"`.

## Scope decisions

- Selection state lives in the plugin/gizmo (NOT exposed on `TrackSpline` —
  user explicitly chose click-select over shared-state option).
- Dock path selector is independent of the toolbar's add-target selector.
- No tests in `tests/` for this — editor UI; assistant does parse + reload +
  log checks only, user verifies visually (per standing rule).

## Steps

### 1. ✅ Point selection in gizmo (`track_spline_gizmo_plugin.gd`)
- `selected_path_index` / `selected_point_index` + `set_selected_point()` on the gizmo plugin.
- Left-click a point handle in MODE_EDIT selects it (press-without-drag); the selected point
  draws as a bright on-top marker layered over its flag-colored handle and tracks during drag.
- **Landed in:** `addons/arcwing_track_editor/track_spline_gizmo_plugin.gd` (`ac4c07c`).

### 2. ✅ Dock UI (`path_data_dock.gd`, new Control in `addons/arcwing_track_editor/`)
- Registered via `add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock)`;
  `_make_visible` toggles it with selection; `_edit` wires it to the TrackSpline.
- Layout (VBox): nav header (◀ path ▶ + Save), Branches section (connection rows with Jump),
  Path Controls (Name LineEdit + 3 delete buttons), position readout, Width/Tilt/Tunnel spins,
  Recipe OptionButton, Flags CheckBoxes, defaults footer.
- **Landed in:** `addons/arcwing_track_editor/path_data_dock.gd` (`8ac07fe`).

### 3. ✅ Undo + live gizmo refresh
- Every field edit wraps `EditorUndoRedoManager.create_action` + `add_do/add_undo` calling the
  `Spline`/`SplinePointData` setters; `version_changed` refreshes dock fields + gizmos.
- **Landed in:** `path_data_dock.gd` `_commit_change` / `_apply_point_value`.

### 4. ✅ Selection sync & edge cases
- Dock nav ◀ ▶, path change, and viewport click sync selection both ways via signals;
  selection is cleared/clamped when a point or path no longer exists (deletes, load-from-data).
- **Landed in:** plugin `_on_dock_navigated`, dock `_clear_selection_if_invalid`, gizmo selection.

### 5. ✅ Verify
- Reload plugin, open `Test_Level.tscn`, select TrackSpline, click points: dock + highlight
  follow, edits are undoable, right-click still removes, branch Jump navigates.
- Zero editor errors from the addon; phantom_camera singleton noise is unrelated/pre-existing.

### 6. ✅ Path Controls (path-level editing; added on user request)
- **Names:** `Spline.path_name` (empty = positional fallback), copied by `Spline.import_from`;
  `TrackSpline.get_path_display_name(path_index)` returns `path_name` or "Main"/"Alt N".
- **Three delete levels** on `TrackSpline`, each one undo action:
  `delete_path_connections`, `delete_path_points`, `delete_path`.
- **Dock "Path Controls" section:** Name LineEdit (Enter/blur commits via undo) + Delete
  Connections / Delete Points / Delete Entire Path buttons.
- **Selectors** in the dock and the 3D toolbar show display names.
- **Landed in:** `Systems/Track/spline.gd`, `Systems/Track/track_spline.gd`,
  `path_data_dock.gd` (`c19f368`, `73fd6ee`).

### 7. ✅ Requested polish (added during verification)
- **Toolbar name sync:** the plugin watches every spline's `changed` signal and rebuilds the
  toolbar + dock path selectors only when a `path_name` actually changes — covers inspector
  renames that never fire an undo action (`plugin.gd` `_watch_spline_names`).
- **Save button:** nav-bar Save calls `_track._save_to_data()` (same as the export button).
- **Branches at the top + bold headers:** Branches section moved directly under the nav bar;
  each connection row keeps its Jump button; section headers render bold via the theme's
  `bold_font` (`_make_section_label`).
- **Resource names on save:** `_save_to_data` sets each persisted Spline's
  `resource_name = "{display name}_Spline"` (`_name_saved_spline`), so splines inside a saved
  `TrackSplineData` are identifiable (`c7b8159`).

## Files touched
- `addons/arcwing_track_editor/track_spline_gizmo_plugin.gd` — selection + highlight.
- `addons/arcwing_track_editor/plugin.gd` — dock registration, click-select input, toolbar
  path selector display names, spline-name watcher for selector sync.
- `addons/arcwing_track_editor/path_data_dock.gd` — NEW dock Control (nav + Save, Branches
  section up top, Path Controls, point fields, Flags) with bold section headers.
- `Systems/Track/spline.gd` — `path_name` export (null-coercing getter/setter) + import_from copy.
- `Systems/Track/track_spline.gd` — `get_path_display_name` + 3 path-level delete ops +
  `_name_saved_spline` resource naming in `_save_to_data`.
- `docs/technical/tracks-and-splines.md` — Track Editor Roadmap Phase 2 part 2 flipped to ✅.
