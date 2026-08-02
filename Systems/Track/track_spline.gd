@tool
class_name TrackSpline
extends Path3D;

## Authoring node for a track. The inherited Path3D.curve holds the MAIN path's Spline resource;
## this node ensures it is a Spline (not a bare Curve3D) so per-point metadata arrays exist,
## and re-bakes geometry (future TrackMeshGenerator) when points or metadata change.

## Meters between baked samples. Drives sampling fidelity for banking and tunnels.[br]
## Intended purpose: set once at authoring time; stored in the TrackSplineData asset,
## not the scene (see `data`).
var bake_interval : float = 0.25;

## Alternate routes. Each is a standalone Spline (a single curve) with its own point_data.[br]
## Path index 0 is always the main curve (Path3D.curve); indices 1..N map to
## alternate_paths[i-1]. Branches (split/join) live in the branches array below.[br]
## Live authoring state — NOT scene-persisted. Persist via `data` (Save Track to Data).
var alternate_paths : Array[Spline] = [];

## Branch topology between paths. Each entry links a point on one path to a point on another:
## from_path_index/from_point_index -> to_path_index/to_point_index, flagged split or join.[br]
## Live authoring state — NOT scene-persisted. Persist via `data` (Save Track to Data).
var branches : Array[BranchConnection] = [];

## Emitted when alternate_paths or branches are mutated (add/remove) so editor tools
## (toolbar, gizmo) can refresh path lists and redraw. Fired by the add/remove methods below.
signal paths_changed;

@export_group("Track Data")
## Single serialized container for this track's full authoring state (main curve, alternate
## paths, branches, bake interval). The scene stores only this one reference — no inline
## Spline/BranchConnection sub-resources. Save Track to Data writes the current node state
## into it; Load Track from Data (and scene load) copies it back onto the node.
@export var data : TrackSplineData;
## Copy the node's current state (curve, alternates, branches, bake interval) into `data`.
@export_tool_button("Save Track to Data","Save") var save_to_data : Callable = _save_to_data
## Replace the node's state from `data`. Runs automatically at _ready when data is set.
@export_tool_button("Load Track from Data", "Load") var load_from_data : Callable = _load_from_data

@export_group("Editor")
## Regenerate all track geometry from this spline. Editor-only; the mesh generator bakes
## ROAD/TUNNEL spans into StaticBody3D + visuals (see ADR 0010).
@export_tool_button("Generate Track Geometry", "3D") var generate_geometry : Callable = _generate_track_geometry
## Source curve to import points from (plain Curve3D or Spline) via the Import Points button.[br]
## Intended purpose: copy an authored dummy path/curve's points into this spline when the
## editor copy-paste cannot cross resource types.[br]
## Leave empty to skip.
@export_subgroup("Import")
@export var source_curve : Curve3D;
## Copy all points from source_curve into this spline, replacing existing points. Editor-only;
## copies position/handles/tilt, plus metadata when the source is a Spline (see Spline.import_from).
@export_tool_button("Import Points from Curve", "Reload") var import_points : Callable = _import_points

## Copy all points from source_curve into this spline, replacing existing points. Editor-only;
## copies position/handles/tilt, plus metadata when the source is a Spline (see Spline.import_from).
func _import_points() -> void:
	if source_curve == null:
		push_warning("TrackSpline '%s': source_curve is not assigned." % name);
		return;
	var spline : Spline = get_spline();
	if spline == null:
		push_warning("TrackSpline '%s': no Spline assigned as curve." % name);
		return;
	spline.import_from(source_curve);

# --- Track data persistence ----------------------------------------------------------------
# The whole track definition lives in a TrackSplineData .tres so the scene only holds one
# resource reference. These two buttons move state between the node and the asset.

## Copy the node's current authoring state into `data` (deep copies, so later node edits
## don't leak into the saved asset until you Save again). Saves the .tres when `data` has a
## resource_path. Editor-only.
func _save_to_data() -> void:
	if data == null:
		push_warning("TrackSpline '%s': assign a TrackSplineData to `data` before saving." % name);
		return;
	data.main_curve = get_spline().duplicate(true) if get_spline() else null;
	_name_saved_spline(data.main_curve, 0);
	data.bake_interval = bake_interval;
	data.alternate_paths.clear();
	for i in alternate_paths.size():
		var saved : Spline = alternate_paths[i].duplicate(true) if alternate_paths[i] else null;
		_name_saved_spline(saved, i + 1);
		data.alternate_paths.append(saved);
	data.branches.clear();
	for branch in branches:
		data.branches.append(branch.duplicate(true) if branch else null);
	if data.resource_path != "":
		var err : int = ResourceSaver.save(data, data.resource_path);
		if err != OK:
			push_warning("TrackSpline '%s': failed to save TrackSplineData (%s)." % [name, error_string(err)]);


## Name a spline being persisted into `data` from its path display name ("Main_Spline",
## "Pit Lane_Spline") so the splines inside a saved TrackSplineData are identifiable in the
## inspector / asset browser. Same idea as the resource_namer addon's "Set Resource Name to
## Filename", but derived from Spline.path_name instead of the file path.
func _name_saved_spline(saved : Spline, path_index : int) -> void:
	if saved == null:
		return;
	saved.resource_name = get_path_display_name(path_index) + "_Spline";


## Replace the node's state from `data`: main curve, bake interval, alternates, branches.
## Emits paths_changed so editor tools refresh. Editor-only, but safe at runtime too.
func _load_from_data() -> void:
	if data == null:
		return;
	if data.main_curve:
		curve = data.main_curve.duplicate(true);
	bake_interval = data.bake_interval;
	alternate_paths.clear();
	for spline in data.alternate_paths:
		alternate_paths.append(spline.duplicate(true) if spline else null);
	branches.clear();
	for branch in data.branches:
		branches.append(branch.duplicate(true) if branch else null);
	_apply_bake_settings();
	_sync_path_watchers();
	notify_property_list_changed();
	paths_changed.emit();


# --- Path / branch authoring ----------------------------------------------------------------
# Editor-only helpers for the track editor addon. Called through EditorUndoRedoManager so every
# action is undoable; mutations emit paths_changed so the toolbar and gizmo stay in sync.

## Append a new alternate Spline (or a given one) and emit paths_changed. Returns the appended
## spline. Path index 1..N maps to alternate_paths[i-1], so this grows get_path_count() by one.
func add_alternate_path(spline : Spline = null) -> Spline:
	if spline == null:
		spline = Spline.new();
		# Alternate routes default to point-to-point (cyclic OFF); only the main circuit is a loop.
		spline.closed = false;
	spline.bake_interval = bake_interval;
	alternate_paths.append(spline);
	_sync_path_watchers();
	notify_property_list_changed();
	paths_changed.emit();
	return spline;


## Remove the alternate path at `index` (0-based into alternate_paths). Editor-only.
func remove_alternate_path(index : int) -> void:
	if index < 0 or index >= alternate_paths.size():
		return;
	alternate_paths.remove_at(index);
	_sync_path_watchers();
	notify_property_list_changed();
	paths_changed.emit();


## Append a BranchConnection and emit paths_changed. Editor-only. Returns the connection.
func add_branch(connection : BranchConnection) -> BranchConnection:
	if connection == null:
		connection = BranchConnection.new();
	branches.append(connection);
	notify_property_list_changed();
	paths_changed.emit();
	return connection;


## Remove the branch at `index` (0-based into branches). Editor-only.
func remove_branch(index : int) -> void:
	if index < 0 or index >= branches.size():
		return;
	branches.remove_at(index);
	notify_property_list_changed();
	paths_changed.emit();


# --- Path-level deletion ------------------------------------------------------------------
# Three severity levels, each one undo action via EditorUndoRedoManager (mirrors
# remove_point_with_branches): Delete Connections (branches only), Delete Points (points,
# which prunes their branches), Delete Entire Path (alternates: branches + points + the path
# itself; the main path cannot be removed, so it falls back to deleting its points).

## Remove every BranchConnection touching `path_index` in one undo action. Editor-only.
func delete_path_connections(path_index : int) -> void:
	if not Engine.is_editor_hint():
		return;
	if not has_path(path_index):
		return;
	var branch_backup : Array = _branch_state_backup();
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo();
	ur.create_action("Delete %s Connections" % get_path_display_name(path_index));
	ur.add_do_method(self, "_do_delete_path_connections", path_index);
	ur.add_undo_method(self, "_restore_branches", branch_backup);
	ur.commit_action();


func _do_delete_path_connections(path_index : int) -> void:
	var removed := false;
	for i in range(branches.size() - 1, -1, -1):
		var b : BranchConnection = branches[i];
		if b == null:
			continue;
		if b.from_path_index == path_index or b.to_path_index == path_index:
			branches.remove_at(i);
			removed = true;
	if removed:
		notify_property_list_changed();
		paths_changed.emit();


## Remove every point on `path_index` in one undo action. Branches whose endpoints lived on
## the path are pruned too (their anchors cease to exist). Editor-only.
func delete_path_points(path_index : int) -> void:
	if not Engine.is_editor_hint():
		return;
	var spline : Spline = get_spline_at(path_index);
	if spline == null or spline.point_count == 0:
		return;
	var backup : Dictionary = _spline_points_backup(spline);
	var branch_backup : Array = _branch_state_backup();
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo();
	ur.create_action("Delete %s Points" % get_path_display_name(path_index));
	ur.add_do_method(self, "_do_delete_path_points", path_index);
	ur.add_undo_method(self, "_undo_delete_path_points", path_index, backup, branch_backup);
	ur.commit_action();


func _do_delete_path_points(path_index : int) -> void:
	var spline : Spline = get_spline_at(path_index);
	if spline == null or spline.point_count == 0:
		return;
	_reconcile_suspended = true;
	spline.clear_points();
	_reconcile_suspended = false;
	_reconcile_branches_for_removal(path_index, spline, -1);
	_sync_path_watchers();
	notify_property_list_changed();
	paths_changed.emit();


func _undo_delete_path_points(path_index : int, backup : Dictionary, branch_backup : Array) -> void:
	var spline : Spline = get_spline_at(path_index);
	if spline == null:
		return;
	_restore_spline_points(spline, backup);
	_restore_branches(branch_backup);
	_sync_path_watchers();


## Delete `path_index` entirely — its branches, its points, and the alternate path itself.
## The main path (index 0) cannot be removed, so this clears its points instead. Editor-only.
func delete_path(path_index : int) -> void:
	if not Engine.is_editor_hint():
		return;
	if path_index <= 0:
		delete_path_points(path_index);
		return;
	if not has_path(path_index):
		return;
	var spline : Spline = get_spline_at(path_index);
	if spline == null:
		return;
	var backup : Dictionary = _spline_points_backup(spline);
	var branch_backup : Array = _branch_state_backup();
	var alternate_index : int = path_index - 1;
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo();
	ur.create_action("Delete Path %s" % get_path_display_name(path_index));
	ur.add_do_method(self, "_do_delete_path", path_index, alternate_index);
	ur.add_undo_method(self, "_undo_delete_path", path_index, alternate_index, backup, branch_backup);
	ur.commit_action();


func _do_delete_path(path_index : int, alternate_index : int) -> void:
	for i in range(branches.size() - 1, -1, -1):
		var b : BranchConnection = branches[i];
		if b == null:
			branches.remove_at(i);
			continue;
		if b.from_path_index == path_index or b.to_path_index == path_index:
			branches.remove_at(i);
		else:
			if b.from_path_index > path_index:
				b.from_path_index -= 1;
			if b.to_path_index > path_index:
				b.to_path_index -= 1;
	remove_alternate_path(alternate_index);


func _undo_delete_path(path_index : int, alternate_index : int, backup : Dictionary, branch_backup : Array) -> void:
	var spline : Spline = Spline.new();
	spline.bake_interval = bake_interval;
	_restore_spline_points(spline, backup);
	alternate_paths.insert(clampi(alternate_index, 0, alternate_paths.size()), spline);
	_restore_branches(branch_backup);
	_sync_path_watchers();
	notify_property_list_changed();
	paths_changed.emit();


func _enter_tree() -> void:
	if curve == null:
		curve = Spline.new();
	elif not curve is Spline:
		push_warning("TrackSpline '%s': curve is a Curve3D, not a Spline — metadata arrays unavailable." % name);
		return;
	_apply_bake_settings();
	_sync_path_watchers();

func _ready() -> void:
	# Restore the track definition from its data asset in BOTH editor and runtime, so a
	# scene that references only `data` still shows/behaves fully.
	_load_from_data();
	if Engine.is_editor_hint():
		return;
	if curve is Spline:
		_apply_bake_settings();

func get_spline() -> Spline:
	return curve as Spline;

## Number of paths: 1 main + alternate_paths.size().
func get_path_count() -> int:
	return alternate_paths.size() + 1;

## Returns the Spline for a path index. Index 0 = main path (Path3D.curve); indices 1..N map
## to alternate_paths[i-1]. Returns null for out-of-range or when the main curve is not a Spline.
## Named get_spline_at (not get_path) to avoid shadowing Node.get_path() -> NodePath.
func get_spline_at(index : int) -> Spline:
	if index <= 0:
		return get_spline();
	var alternate_index : int = index - 1;
	if alternate_index < 0 or alternate_index >= alternate_paths.size():
		return null;
	return alternate_paths[alternate_index];

## Returns true when path `index` exists and its curve is usable.
func has_path(index : int) -> bool:
	return get_spline_at(index) != null;

## Human-readable name for a path: its Spline.path_name when set, else a positional fallback
## ("Main" for index 0, "Alt N" for alternates). Used by the dock and toolbar path selectors
## and by undo-action labels for the path-level delete operations.
func get_path_display_name(path_index : int) -> String:
	var spline : Spline = get_spline_at(path_index);
	if spline == null:
		return "Path %d" % path_index;
	if not spline.path_name.is_empty():
		return spline.path_name;
	return "Main" if path_index <= 0 else "Alt %d" % path_index;

## Apply bake_interval to every path's Spline. Runs at enter-tree and on geometry generation.
func _apply_bake_settings() -> void:
	for i in get_path_count():
		var spline : Spline = get_spline_at(i);
		if spline:
			spline.bake_interval = bake_interval;

# --- Branch reconciliation on point removal ----------------------------------------------
# Deleting a point (built-in Path3D gizmo DELETE key, our right-click remove, undo replay)
# removes it from the Spline and fires Curve3D.changed. Branches pin their endpoints by point
# index, so a removal must reconcile them: endpoints AT the removed index are deleted outright
# (their anchor point is gone), endpoints BEYOND it shift down by one. We watch every path's
# `changed` signal and keep a per-path position snapshot to find WHICH index was removed
# (positions before it match the snapshot; at/after it differ).

var _watched_splines : Array[Spline] = [];
var _watched_callables : Array[Callable] = [];
var _path_snapshots : Array[PackedVector3Array] = [];
var _path_counts : Array[int] = [];

## Set while a removal is being driven by remove_point_with_branches (which reconciles itself),
## so the watcher skips its own reconcile and avoids a double shift/delete.
var _reconcile_suspended : bool = false;


## (Re)connect the per-path `changed` watchers and snapshot each path. Call whenever the path
## list changes (add/remove alternate path, load from data) or the main curve is swapped.
func _sync_path_watchers() -> void:
	for i in _watched_splines.size():
		var spline : Spline = _watched_splines[i];
		if is_instance_valid(spline):
			var cb : Callable = _watched_callables[i];
			if spline.changed.is_connected(cb):
				spline.changed.disconnect(cb);
	_watched_splines.clear();
	_watched_callables.clear();
	_path_snapshots.clear();
	_path_counts.clear();
	for i in get_path_count():
		var spline : Spline = get_spline_at(i);
		if spline == null:
			continue;
		var cb := _on_path_changed.bind(i);
		spline.changed.connect(cb);
		_watched_splines.append(spline);
		_watched_callables.append(cb);
		_path_snapshots.append(_snapshot_positions(spline));
		_path_counts.append(spline.point_count);


func _snapshot_positions(spline : Spline) -> PackedVector3Array:
	var arr := PackedVector3Array();
	for i in spline.point_count:
		arr.append(spline.get_point_position(i));
	return arr;


func _on_path_changed(path_index : int) -> void:
	var spline : Spline = get_spline_at(path_index);
	if spline == null or path_index >= _path_snapshots.size():
		return;
	var old_count : int = _path_counts[path_index];
	var new_count : int = spline.point_count;
	if new_count < old_count and not _reconcile_suspended:
		var removed_index : int = -1;
		if new_count == old_count - 1:
			removed_index = _detect_removed_index(_path_snapshots[path_index], spline);
		_reconcile_branches_for_removal(path_index, spline, removed_index);
	_path_counts[path_index] = new_count;
	_path_snapshots[path_index] = _snapshot_positions(spline);


## Reconcile branches after a point was removed from `path_index`. Pass the removed point index
## when known (plugin-driven removal), or -1 when it could not be determined (bulk shrink) —
## in that case endpoints that fell out of range are pruned instead of guessing an index.
func _reconcile_branches_for_removal(path_index : int, spline : Spline, removed_index : int) -> void:
	if branches.is_empty():
		return;
	var to_delete := {}
	var shifted := false;
	if removed_index >= 0:
		for i in branches.size():
			var b : BranchConnection = branches[i];
			if b == null:
				continue;
			var doomed := false;
			if b.from_path_index == path_index:
				if b.from_point_index == removed_index:
					doomed = true;
				elif b.from_point_index > removed_index:
					b.from_point_index -= 1;
					shifted = true;
			if not doomed and b.to_path_index == path_index:
				if b.to_point_index == removed_index:
					doomed = true;
				elif b.to_point_index > removed_index:
					b.to_point_index -= 1;
					shifted = true;
			if doomed:
				to_delete[i] = true;
	else:
		# Bulk shrink (clear_points, multi-remove): prune endpoints now out of range instead
		# of guessing which single index vanished.
		for i in branches.size():
			var b : BranchConnection = branches[i];
			if b == null:
				continue;
			if (b.from_path_index == path_index and b.from_point_index >= spline.point_count) \
					or (b.to_path_index == path_index and b.to_point_index >= spline.point_count):
				to_delete[i] = true;
	if to_delete.size() > 0:
		var keys : Array = to_delete.keys();
		keys.sort();
		for i in range(keys.size() - 1, -1, -1):
			branches.remove_at(keys[i]);
	if shifted or to_delete.size() > 0:
		notify_property_list_changed();
		paths_changed.emit();


## Remove a point and reconcile branch connections in ONE undo action (point removal and
## branch shift/delete undo together). Editor-only. The plugin's right-click remove uses this;
## the built-in Path3D gizmo DELETE key is covered by the changed-signal watcher instead.
func remove_point_with_branches(path_index : int, point_index : int) -> void:
	if not Engine.is_editor_hint():
		return;
	var spline : Spline = get_spline_at(path_index);
	if spline == null or point_index < 0 or point_index >= spline.point_count:
		return;
	var pos : Vector3 = spline.get_point_position(point_index);
	var in_ctl : Vector3 = spline.get_point_in(point_index);
	var out_ctl : Vector3 = spline.get_point_out(point_index);
	var branch_backup : Array = _branch_state_backup();
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo();
	ur.create_action("Remove Track Point");
	ur.add_do_method(self, "_do_remove_point", path_index, point_index);
	ur.add_undo_method(self, "_undo_remove_point", path_index, point_index, pos, in_ctl, out_ctl, branch_backup);
	ur.commit_action();


func _do_remove_point(path_index : int, point_index : int) -> void:
	var spline : Spline = get_spline_at(path_index);
	if spline == null or point_index < 0 or point_index >= spline.point_count:
		return;
	_reconcile_suspended = true;
	spline.remove_point(point_index);
	_reconcile_suspended = false;
	_reconcile_branches_for_removal(path_index, spline, point_index);


func _undo_remove_point(path_index : int, point_index : int, pos : Vector3, in_ctl : Vector3, out_ctl : Vector3, branch_backup : Array) -> void:
	var spline : Spline = get_spline_at(path_index);
	if spline == null:
		return;
	spline.add_point(pos, in_ctl, out_ctl, point_index);
	_restore_branches(branch_backup);


## Snapshot of the branches array as plain data (no object references) for undo. Stored by
## value because EditorUndoRedoManager deep-copies action arguments, which would break any
## BranchConnection references threaded through add_undo_method. The gizmo re-reads the
## branches array every redraw and wire-source uses path/point dicts, so value restore is
## safe — undo rebuilds equivalent BranchConnection instances.
func _branch_state_backup() -> Array:
	var backup : Array = [];
	for b in branches:
		backup.append({
			"from_path": b.from_path_index if b else 0,
			"from_point": b.from_point_index if b else 0,
			"to_path": b.to_path_index if b else 0,
			"to_point": b.to_point_index if b else 0,
			"is_split": b.is_split if b else true,
		})
	return backup;


func _restore_branches(branch_backup : Array) -> void:
	branches.clear();
	for entry in branch_backup:
		var b := BranchConnection.new();
		b.from_path_index = entry.get("from_path", 0);
		b.from_point_index = entry.get("from_point", 0);
		b.to_path_index = entry.get("to_path", 0);
		b.to_point_index = entry.get("to_point", 0);
		b.is_split = entry.get("is_split", true);
		branches.append(b);
	notify_property_list_changed();
	paths_changed.emit();


## Snapshot a spline's points as plain data for undo — positions, in/out handles, tilts,
## per-point metadata, closed/up-vector flags, and path name. Value types only, so the
## snapshot is safe through EditorUndoRedoManager's deep-copied action arguments.
func _spline_points_backup(spline : Spline) -> Dictionary:
	var positions := PackedVector3Array();
	var ins := PackedVector3Array();
	var outs := PackedVector3Array();
	var tilts := PackedFloat64Array();
	var widths := PackedFloat64Array();
	var recipes := PackedInt32Array();
	var recipe_params := PackedFloat64Array();
	var flags := PackedInt32Array();
	for i in spline.point_count:
		positions.append(spline.get_point_position(i));
		ins.append(spline.get_point_in(i));
		outs.append(spline.get_point_out(i));
		tilts.append(spline.get_point_tilt(i));
		widths.append(spline.get_point_width(i));
		recipes.append(int(spline.get_point_recipe(i)));
		recipe_params.append(spline.get_point_recipe_param(i));
		flags.append(spline.get_point_flags(i));
	return {
		"positions": positions,
		"ins": ins,
		"outs": outs,
		"tilts": tilts,
		"widths": widths,
		"recipes": recipes,
		"recipe_params": recipe_params,
		"flags": flags,
		"closed": spline.closed,
		"up_vector_enabled": spline.up_vector_enabled,
		"path_name": spline.path_name,
	}


## Rebuild a spline's points and metadata from a `_spline_points_backup` snapshot. Clears
## existing points first. Used by the undo paths for Delete Points / Delete Path.
func _restore_spline_points(spline : Spline, backup : Dictionary) -> void:
	var positions : PackedVector3Array = backup["positions"];
	var ins : PackedVector3Array = backup["ins"];
	var outs : PackedVector3Array = backup["outs"];
	var tilts : PackedFloat64Array = backup["tilts"];
	var widths : PackedFloat64Array = backup["widths"];
	var recipes : PackedInt32Array = backup["recipes"];
	var recipe_params : PackedFloat64Array = backup["recipe_params"];
	var flags : PackedInt32Array = backup["flags"];
	spline.clear_points();
	for i in positions.size():
		spline.add_point(positions[i], ins[i], outs[i], -1);
		spline.set_point_tilt(i, tilts[i]);
		var pd : SplinePointData = spline.get_point_data(i);
		if pd:
			pd.width = widths[i];
			pd.recipe = recipes[i];
			pd.recipe_param = recipe_params[i];
			pd.flags = flags[i];
			pd.tilt = tilts[i];
	spline.closed = backup.get("closed", true);
	spline.up_vector_enabled = backup.get("up_vector_enabled", false);
	spline.path_name = backup.get("path_name", "");


## First index where the current positions diverge from the pre-removal snapshot. For a
## single-point removal at N, positions 0..N-1 are identical and N onwards differ, so this is N.
func _detect_removed_index(old_positions : PackedVector3Array, spline : Spline) -> int:
	for i in old_positions.size():
		if i >= spline.point_count:
			return i;
		if not old_positions[i].is_equal_approx(spline.get_point_position(i)):
			return i;
	return -1;


# --- World-space wrappers ---------------------------------------------------------------
# Curve3D's baked sampling and closest-point queries are local to the curve (relative to this
# Path3D origin). Gameplay uses world positions, so translate here. Single-path variants
# operate on the main path; *_path variants take a path index.

## World-space position at a baked offset on the main path.
func sample_world(offset : float, cubic : bool = true) -> Vector3:
	var spline : Spline = get_spline();
	if spline == null:
		return Vector3.ZERO;
	return to_global(spline.sample_baked(offset, cubic));

## World-space position at a baked offset on a specific path.
func sample_world_path(path_index : int, offset : float, cubic : bool = true) -> Vector3:
	var spline : Spline = get_spline_at(path_index);
	if spline == null:
		return Vector3.ZERO;
	return to_global(spline.sample_baked(offset, cubic));

## World-space forward (tangent) direction at a baked offset on the main path.
func sample_forward_world(offset : float, delta : float = 0.01) -> Vector3:
	var spline : Spline = get_spline();
	if spline == null:
		return Vector3.ZERO;
	return global_transform.basis * spline.sample_forward(offset, delta);

## World-space forward (tangent) direction at a baked offset on a specific path.
func sample_forward_world_path(path_index : int, offset : float, delta : float = 0.01) -> Vector3:
	var spline : Spline = get_spline_at(path_index);
	if spline == null:
		return Vector3.ZERO;
	return global_transform.basis * spline.sample_forward(offset, delta);

## World-space surface normal at a baked offset on the main path.
func sample_normal_world(offset : float) -> Vector3:
	var spline : Spline = get_spline();
	if spline == null:
		return Vector3.UP;
	var local_normal : Vector3 = spline.sample_normal(offset);
	return global_transform.basis * local_normal;

## World-space surface normal at a baked offset on a specific path.
func sample_normal_world_path(path_index : int, offset : float) -> Vector3:
	var spline : Spline = get_spline_at(path_index);
	if spline == null:
		return Vector3.UP;
	var local_normal : Vector3 = spline.sample_normal(offset);
	return global_transform.basis * local_normal;

## Nearest offset in meters along the main path to a world-space point.
func project_world(point : Vector3) -> float:
	var spline : Spline = get_spline();
	if spline == null:
		return 0.0;
	return spline.get_closest_offset(to_local(point));

## Nearest offset in meters along a specific path to a world-space point.
func project_world_path(path_index : int, point : Vector3) -> float:
	var spline : Spline = get_spline_at(path_index);
	if spline == null:
		return 0.0;
	return spline.get_closest_offset(to_local(point));

## Nearest offset across ALL paths to a world point. Returns {path_index, offset, distance}
## for the closest path, or an empty dict when no path is usable.
func project_world_any(point : Vector3) -> Dictionary:
	var local_point : Vector3 = to_local(point);
	var best_index : int = -1;
	var best_offset : float = 0.0;
	var best_distance : float = INF;
	for i in get_path_count():
		var spline : Spline = get_spline_at(i);
		if spline == null:
			continue;
		var offset : float = spline.get_closest_offset(local_point);
		var distance : float = local_point.distance_to(spline.sample_baked(offset));
		if distance < best_distance:
			best_distance = distance;
			best_index = i;
			best_offset = offset;
	if best_index == -1:
		return {}
	return {"path_index": best_index, "offset": best_offset, "distance": best_distance}

func _generate_track_geometry() -> void:
	# Placeholder: mesh generator lands in the next pass (ADR 0010). For now, emit the bake
	# parameters so the editor stays functional without generator code.
	if not is_inside_tree():
		return;
	var spline : Spline = get_spline();
	if spline == null:
		return;
	_apply_bake_settings();
	print("[TrackSpline] %s: bake_interval=%.2f points=%d — generator pending." % [name, bake_interval, spline.point_count]);
