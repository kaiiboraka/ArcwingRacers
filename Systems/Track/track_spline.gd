@tool
class_name TrackSpline
extends Path3D

## Authoring node for a track. The inherited Path3D.curve holds the MAIN path's Spline resource;
## this node ensures it is a Spline (not a bare Curve3D) so per-point metadata arrays exist,
## and re-bakes geometry (future TrackMeshGenerator) when points or metadata change.

## Meters between baked samples. Drives sampling fidelity for banking and tunnels.[br]
## Intended purpose: set once at authoring time; stored in the TrackSplineData asset,
## not the scene (see `data`).
var bake_interval: float = 0.25

## Alternate routes. Each is a standalone Spline (a single curve) with its own point_data.[br]
## Path index 0 is always the main curve (Path3D.curve); indices 1..N map to
## alternate_paths[i-1]. Branches (split/join) live in the branches array below.[br]
## Live authoring state — NOT scene-persisted. Persist via `data` (Save Track to Data).
var alternate_paths: Array[Spline] = []

## Branch topology between paths. Each entry links a point on one path to a point on another:
## from_path_index/from_point_index -> to_path_index/to_point_index, flagged split or join.[br]
## Live authoring state — NOT scene-persisted. Persist via `data` (Save Track to Data).
var branches: Array[BranchConnection] = []

## Emitted when alternate_paths or branches are mutated (add/remove) so editor tools
## (toolbar, gizmo) can refresh path lists and redraw. Fired by the add/remove methods below.
signal paths_changed

@export_group("Track Data")
## Single serialized container for this track's full authoring state (main curve, alternate
## paths, branches, bake interval). The scene stores only this one reference — no inline
## Spline/BranchConnection sub-resources. Save Track to Data writes the current node state
## into it; Load Track from Data (and scene load) copies it back onto the node.
@export var data: TrackSplineData
## Copy the node's current state (curve, alternates, branches, bake interval) into `data`.
@export_tool_button("Save Track to Data","Save") var save_to_data: Callable = _save_to_data
## Replace the node's state from `data`. Runs automatically at _ready when data is set.
@export_tool_button("Load Track from Data", "Load") var load_from_data: Callable = _load_from_data

@export_group("Editor")
## Regenerate all track geometry from this spline. Editor-only; the mesh generator bakes
## ROAD/TUNNEL spans into StaticBody3D + visuals (see ADR 0010).
@export_tool_button("Generate Track Geometry", "3D") var generate_geometry: Callable = _generate_track_geometry
## Source curve to import points from (plain Curve3D or Spline) via the Import Points button.[br]
## Intended purpose: copy an authored dummy path/curve's points into this spline when the
## editor copy-paste cannot cross resource types.[br]
## Leave empty to skip.
@export_subgroup("Import")
@export var source_curve: Curve3D
## Copy all points from source_curve into this spline, replacing existing points. Editor-only;
## copies position/handles/tilt, plus metadata when the source is a Spline (see Spline.import_from).
@export_tool_button("Import Points from Curve", "Reload") var import_points: Callable = _import_points

## Copy all points from source_curve into this spline, replacing existing points. Editor-only;
## copies position/handles/tilt, plus metadata when the source is a Spline (see Spline.import_from).
func _import_points() -> void:
	if source_curve == null:
		push_warning("TrackSpline '%s': source_curve is not assigned." % name)
		return
	var spline: Spline = get_spline()
	if spline == null:
		push_warning("TrackSpline '%s': no Spline assigned as curve." % name)
		return
	spline.import_from(source_curve)

# --- Track data persistence ----------------------------------------------------------------
# The whole track definition lives in a TrackSplineData .tres so the scene only holds one
# resource reference. These two buttons move state between the node and the asset.

## Copy the node's current authoring state into `data` (deep copies, so later node edits
## don't leak into the saved asset until you Save again). Saves the .tres when `data` has a
## resource_path. Editor-only.
func _save_to_data() -> void:
	if data == null:
		push_warning("TrackSpline '%s': assign a TrackSplineData to `data` before saving." % name)
		return
	data.main_curve = get_spline().duplicate(true) if get_spline() else null
	data.bake_interval = bake_interval
	data.alternate_paths.clear()
	for spline in alternate_paths:
		data.alternate_paths.append(spline.duplicate(true) if spline else null)
	data.branches.clear()
	for branch in branches:
		data.branches.append(branch.duplicate(true) if branch else null)
	if data.resource_path != "":
		var err: int = ResourceSaver.save(data, data.resource_path)
		if err != OK:
			push_warning("TrackSpline '%s': failed to save TrackSplineData (%s)." % [name, error_string(err)])


## Replace the node's state from `data`: main curve, bake interval, alternates, branches.
## Emits paths_changed so editor tools refresh. Editor-only, but safe at runtime too.
func _load_from_data() -> void:
	if data == null:
		return
	if data.main_curve:
		curve = data.main_curve.duplicate(true)
	bake_interval = data.bake_interval
	alternate_paths.clear()
	for spline in data.alternate_paths:
		alternate_paths.append(spline.duplicate(true) if spline else null)
	branches.clear()
	for branch in data.branches:
		branches.append(branch.duplicate(true) if branch else null)
	_apply_bake_settings()
	notify_property_list_changed()
	paths_changed.emit()


# --- Path / branch authoring ----------------------------------------------------------------
# Editor-only helpers for the track editor addon. Called through EditorUndoRedoManager so every
# action is undoable; mutations emit paths_changed so the toolbar and gizmo stay in sync.

## Append a new alternate Spline (or a given one) and emit paths_changed. Returns the appended
## spline. Path index 1..N maps to alternate_paths[i-1], so this grows get_path_count() by one.
func add_alternate_path(spline: Spline = null) -> Spline:
	if spline == null:
		spline = Spline.new()
		# Alternate routes default to point-to-point (cyclic OFF); only the main circuit is a loop.
		spline.closed = false
	spline.bake_interval = bake_interval
	alternate_paths.append(spline)
	notify_property_list_changed()
	paths_changed.emit()
	return spline


## Remove the alternate path at `index` (0-based into alternate_paths). Editor-only.
func remove_alternate_path(index: int) -> void:
	if index < 0 or index >= alternate_paths.size():
		return
	alternate_paths.remove_at(index)
	notify_property_list_changed()
	paths_changed.emit()


## Append a BranchConnection and emit paths_changed. Editor-only. Returns the connection.
func add_branch(connection: BranchConnection) -> BranchConnection:
	if connection == null:
		connection = BranchConnection.new()
	branches.append(connection)
	notify_property_list_changed()
	paths_changed.emit()
	return connection


## Remove the branch at `index` (0-based into branches). Editor-only.
func remove_branch(index: int) -> void:
	if index < 0 or index >= branches.size():
		return
	branches.remove_at(index)
	notify_property_list_changed()
	paths_changed.emit()


func _enter_tree() -> void:
	if curve == null:
		curve = Spline.new()
	elif not curve is Spline:
		push_warning("TrackSpline '%s': curve is a Curve3D, not a Spline — metadata arrays unavailable." % name)
		return
	_apply_bake_settings()

func _ready() -> void:
	# Restore the track definition from its data asset in BOTH editor and runtime, so a
	# scene that references only `data` still shows/behaves fully.
	_load_from_data()
	if Engine.is_editor_hint():
		return
	if curve is Spline:
		_apply_bake_settings()

func get_spline() -> Spline:
	return curve as Spline

## Number of paths: 1 main + alternate_paths.size().
func get_path_count() -> int:
	return alternate_paths.size() + 1

## Returns the Spline for a path index. Index 0 = main path (Path3D.curve); indices 1..N map
## to alternate_paths[i-1]. Returns null for out-of-range or when the main curve is not a Spline.
## Named get_spline_at (not get_path) to avoid shadowing Node.get_path() -> NodePath.
func get_spline_at(index: int) -> Spline:
	if index <= 0:
		return get_spline()
	var alternate_index: int = index - 1
	if alternate_index < 0 or alternate_index >= alternate_paths.size():
		return null
	return alternate_paths[alternate_index]

## Returns true when path `index` exists and its curve is usable.
func has_path(index: int) -> bool:
	return get_spline_at(index) != null

## Apply bake_interval to every path's Spline. Runs at enter-tree and on geometry generation.
func _apply_bake_settings() -> void:
	for i in get_path_count():
		var spline: Spline = get_spline_at(i)
		if spline:
			spline.bake_interval = bake_interval

# --- World-space wrappers ---------------------------------------------------------------
# Curve3D's baked sampling and closest-point queries are local to the curve (relative to this
# Path3D origin). Gameplay uses world positions, so translate here. Single-path variants
# operate on the main path; *_path variants take a path index.

## World-space position at a baked offset on the main path.
func sample_world(offset: float, cubic: bool = true) -> Vector3:
	var spline: Spline = get_spline()
	if spline == null:
		return Vector3.ZERO
	return to_global(spline.sample_baked(offset, cubic))

## World-space position at a baked offset on a specific path.
func sample_world_path(path_index: int, offset: float, cubic: bool = true) -> Vector3:
	var spline: Spline = get_spline_at(path_index)
	if spline == null:
		return Vector3.ZERO
	return to_global(spline.sample_baked(offset, cubic))

## World-space forward (tangent) direction at a baked offset on the main path.
func sample_forward_world(offset: float, delta: float = 0.01) -> Vector3:
	var spline: Spline = get_spline()
	if spline == null:
		return Vector3.ZERO
	return global_transform.basis * spline.sample_forward(offset, delta)

## World-space forward (tangent) direction at a baked offset on a specific path.
func sample_forward_world_path(path_index: int, offset: float, delta: float = 0.01) -> Vector3:
	var spline: Spline = get_spline_at(path_index)
	if spline == null:
		return Vector3.ZERO
	return global_transform.basis * spline.sample_forward(offset, delta)

## World-space surface normal at a baked offset on the main path.
func sample_normal_world(offset: float) -> Vector3:
	var spline: Spline = get_spline()
	if spline == null:
		return Vector3.UP
	var local_normal: Vector3 = spline.sample_normal(offset)
	return global_transform.basis * local_normal

## World-space surface normal at a baked offset on a specific path.
func sample_normal_world_path(path_index: int, offset: float) -> Vector3:
	var spline: Spline = get_spline_at(path_index)
	if spline == null:
		return Vector3.UP
	var local_normal: Vector3 = spline.sample_normal(offset)
	return global_transform.basis * local_normal

## Nearest offset in meters along the main path to a world-space point.
func project_world(point: Vector3) -> float:
	var spline: Spline = get_spline()
	if spline == null:
		return 0.0
	return spline.get_closest_offset(to_local(point))

## Nearest offset in meters along a specific path to a world-space point.
func project_world_path(path_index: int, point: Vector3) -> float:
	var spline: Spline = get_spline_at(path_index)
	if spline == null:
		return 0.0
	return spline.get_closest_offset(to_local(point))

## Nearest offset across ALL paths to a world point. Returns {path_index, offset, distance}
## for the closest path, or an empty dict when no path is usable.
func project_world_any(point: Vector3) -> Dictionary:
	var local_point: Vector3 = to_local(point)
	var best_index: int = -1
	var best_offset: float = 0.0
	var best_distance: float = INF
	for i in get_path_count():
		var spline: Spline = get_spline_at(i)
		if spline == null:
			continue
		var offset: float = spline.get_closest_offset(local_point)
		var distance: float = local_point.distance_to(spline.sample_baked(offset))
		if distance < best_distance:
			best_distance = distance
			best_index = i
			best_offset = offset
	if best_index == -1:
		return {}
	return {"path_index": best_index, "offset": best_offset, "distance": best_distance}

func _generate_track_geometry() -> void:
	# Placeholder: mesh generator lands in the next pass (ADR 0010). For now, emit the bake
	# parameters so the editor stays functional without generator code.
	if not is_inside_tree():
		return
	var spline: Spline = get_spline()
	if spline == null:
		return
	_apply_bake_settings()
	print("[TrackSpline] %s: bake_interval=%.2f points=%d — generator pending." % [name, bake_interval, spline.point_count])
