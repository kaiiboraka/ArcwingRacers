# Plan: Live Path-Data Editor Dock (Track Editor Phase 2 part 2)

Status: agreed 2026-08, pending execution. Check off items as they land.
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

## Scope decisions

- Selection state lives in the plugin/gizmo (NOT exposed on `TrackSpline` —
  user explicitly chose click-select over shared-state option).
- Dock path selector is independent of the toolbar's add-target selector.
- No tests in `tests/` for this — editor UI; assistant does parse + reload +
  log checks only, user verifies visually (per standing rule).

## Steps

### 1. Point selection in gizmo (`track_spline_gizmo_plugin.gd`)
- Add `selected_path_index: int = -1`, `selected_point_index: int = -1` and
  `set_selected_point(path_index, point_index)` to the gizmo plugin.
- Detect a left-click on a point handle **without a drag** in `_forward_3d_gui_input`
  (plugin.gd, MODE_EDIT): distinguish press-without-move from drag so clicking a
  handle selects instead of nudge-dragging. On select, tell gizmo + dock.
- Highlight: draw the selected point as an extra on-top handle (bright marker,
  e.g. yellow ring / larger billboarded point) layered over its flag-colored handle.
  Refresh on drag so the highlight tracks the moving point.
- `_commit_subgizmos`/`_commit_handle` drags keep the selection on that point.

### 2. Dock UI (`path_data_dock.gd`, new Control in `addons/arcwing_track_editor/`)
- Registered via `add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock)`;
  `_make_visible` toggles it with selection; `_edit` wires it to the TrackSpline.
- Layout (VBox):
  - Header row: path OptionButton (Main 0 / Alt N) + point index label +
    ◀ ▶ nav buttons.
  - Position readout (world coords, read-only Label).
  - Width SpinBox (m, ~0.1–50).
  - Tilt SpinBox (degrees; convert to/from `tilt` radians).
  - Recipe OptionButton (None / Road / Tunnel).
  - Tunnel height SpinBox (enabled only when recipe == TUNNEL).
  - Flags: 5 CheckBoxes (Start/Finish, Waypoint, Respawn, Path Entrance, Path Exit).
  - Branch endpoint readout: list BranchConnections touching this point, with a
    "Jump to other end" button (updates selection).
  - Defaults footer: spline `default_width/recipe/recipe_param/flags`, so an
    unchanged point reads as "using default".

### 3. Undo + live gizmo refresh
- Every field edit wraps `EditorUndoRedoManager.create_action` +
  `add_do/add_undo` calling the `Spline` setters
  (`set_point_width`, `set_point_recipe`, `set_point_recipe_param`,
  `set_point_flags`, plus `set_point_tilt` if missing — check `spline.gd`).
- After any commit and on `version_changed`: refresh dock fields + `update_gizmos()`.

### 4. Selection sync & edge cases
- Dock nav ◀ ▶ and path changes update selection; plugin signals dock on
  viewport selection change; dock signals plugin on nav.
- Selection cleared/clamped when the point no longer exists (removal,
  path count change, load-from-data swap). Reuse `remove_point_with_branches`
  already handling removal.
- Guard all reads against stale indices (point removed mid-edit).

### 5. Verify
- Reload plugin; open `Test_Level.tscn`; select TrackSpline node.
- Click a point → dock shows it, highlight visible; edit width/tilt/recipe/flags;
  undo/redo works; right-click still removes; ◀ ▶ navigates; branch jump works.
- Zero editor errors; `diagnostics: []` on all new .gd files.

## Files touched
- `addons/arcwing_track_editor/track_spline_gizmo_plugin.gd` — selection + highlight.
- `addons/arcwing_track_editor/plugin.gd` — dock registration, click-select input.
- `addons/arcwing_track_editor/path_data_dock.gd` — NEW dock Control.
- `Systems/Track/spline.gd` — only if `set_point_tilt`/`get_point_tilt` missing.
- `docs/technical/tracks-and-splines.md` — flip Phase 2 part 2 to ✅ on completion.
