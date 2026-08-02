@tool
extends EditorNode3DGizmoPlugin

## Color-coded 3D gizmo for TrackSpline. Renders EVERY path (main = white, alternates =
## distinct palette colors) with draggable point handles and in/out control handles.
## Undo goes through EditorUndoRedoManager; the move tool drags points via subgizmos.
##
## Handle ID layout (int):
##   kind     0-7 (ID_POINT / ID_IN / ID_OUT)
##   point    rest / 0x100000   (bits 3..23)
##   path     rest / 0x100000   (high bits)  -- combined below in _encode/_decode
## Subgizmo ids reuse the ID_POINT handle encoding so _set_handle and the move tool
## agree on which point is being edited.

const TrackSplineScript = preload("res://Systems/Track/track_spline.gd")

const ID_POINT := 0
const ID_IN := 1
const ID_OUT := 2

## Base added to every encoded handle/subgizmo id. The built-in Path3D gizmo (also on
## TrackSpline, since it extends Path3D) uses plain 0..point_count ids, and the viewport
## keeps ONE subgizmo map per selected node shared across gizmos. Offsetting our ids
## keeps the two namespaces disjoint so a mixed selection (main point via built-in +
## alt point via us) can't move the wrong point. Must stay above any real point count.
const ID_BASE := 0x100000

## Cast the cursor ray against scene colliders when dragging points (mirrors the
## built-in Path3D "Snap to Colliders" option, which defaults to on). Falls back
## to the camera-facing plane when nothing is under the cursor.
const SNAP_TO_SURFACE := true

## Distinct colors for alternate paths (path index 0 = main path, drawn white).
const ALTERNATE_COLORS := [
	Color(0.95, 0.5, 0.1, 0.95),
	Color(0.1, 0.8, 0.9, 0.95),
	Color(0.9, 0.2, 0.9, 0.95),
	Color(0.4, 0.9, 0.2, 0.95),
	Color(0.9, 0.9, 0.2, 0.95),
	Color(0.9, 0.3, 0.3, 0.95),
]

var _path_line_materials_created: Dictionary = {}

## Pending Wire Branch source point ({path_index, point_index}) drawn as a yellow cross while
## the plugin waits for the second click. Empty dict = nothing pending.
var wire_source: Dictionary = {}

## Point currently selected for the live path-data editor dock. -1 = nothing selected.
## Set via set_selected_point(); drawn as a bright on-top marker in _draw_selected_point.
var selected_path_index: int = -1
var selected_point_index: int = -1


func _init() -> void:
	create_material("line_main", Color(1, 1, 1, 0.9))
	create_material("control_lines", Color(0.6, 0.6, 0.6, 0.7))
	create_material("wire_source", Color(1.0, 0.85, 0.0, 1.0))
	create_handle_material("point_handles")
	create_handle_material("control_handles")
	_setup_flag_handle("handle_start_finish", Color(0.0, 0.9, 1.0, 1.0), 22.0, true)
	_setup_flag_handle("handle_branch_split", Color(0.2, 1.0, 0.3, 1.0), 14.0, false)
	_setup_flag_handle("handle_branch_join", Color(1.0, 0.3, 0.3, 1.0), 14.0, false)
	_setup_waypoint_handle()
	_setup_selected_point_handle()


func _get_gizmo_name() -> String:
	return "ArcwingTrack"


## Create a point-handle material with a solid tint and pixel size, one per flag group.
func _setup_flag_handle(name: String, color: Color, point_size: float, billboard: bool) -> void:
	create_handle_material(name, billboard)
	var mat := get_material(name) as StandardMaterial3D
	if mat:
		mat.albedo_color = color
		mat.point_size = point_size


## Waypoints draw as a billboarded editor icon marker (falls back to a gold point).
func _setup_waypoint_handle() -> void:
	var icon: Texture2D = null
	var theme: Theme = EditorInterface.get_editor_theme()
	if theme:
		icon = theme.get_icon(&"3d_handle_point", &"EditorIcons")
	if icon:
		create_handle_material("handle_waypoint", true, icon)
	else:
		_setup_flag_handle("handle_waypoint", Color(1.0, 0.8, 0.1, 1.0), 16.0, true)


func _get_priority() -> int:
	return 1


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is TrackSplineScript


# --- Handle id encode / decode --------------------------------------------------------------

func _encode(path_index: int, point_index: int, kind: int) -> int:
	return ID_BASE + path_index * 0x800000 + point_index * 8 + kind


func _decode(id: int) -> Dictionary:
	var shifted: int = id - ID_BASE
	if shifted < 0:
		# Foreign id (e.g. a built-in Path3D subgizmo id from a mixed selection).
		return {"kind": 0, "point_index": -1, "path_index": -1, "valid": false}
	return {
		"kind": shifted & 0x7,
		"point_index": (shifted >> 3) & 0xFFFFF,
		"path_index": shifted >> 23,
		"valid": true,
	}


# --- Rendering ------------------------------------------------------------------------------

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var track: TrackSpline = gizmo.get_node_3d() as TrackSpline
	if track == null:
		return

	for path_index in track.get_path_count():
		var spline: Spline = track.get_spline_at(path_index)
		if spline == null:
			continue
		_draw_path(gizmo, path_index, spline)

	_draw_branches(gizmo, track)
	_draw_wire_source(gizmo, track)


func _draw_path(gizmo: EditorNode3DGizmo, path_index: int, spline: Spline) -> void:
	var track := gizmo.get_node_3d() as TrackSpline
	var path_material: StandardMaterial3D = get_material("line_main", gizmo)
	if path_index > 0:
		var name := "line_path_%d" % path_index
		if not _path_line_materials_created.has(name):
			create_material(name, _path_color(track, path_index))
			_path_line_materials_created[name] = true
		path_material = get_material(name, gizmo)

	# The built-in Path3D gizmo already draws the MAIN path's curve itself, so only
	# alternate paths need our sampled line here. `line_main` / _path_color(0) stays
	# white as the reference color alt-path colors and branch midpoints derive from.
	var samples := PackedVector3Array()
	if path_index > 0:
		var total_length: float = spline.get_baked_length()
		if total_length > 0.001:
			var step := 0.25
			var count := int(total_length / step) + 2
			for i in count:
				samples.append(spline.sample_baked(minf(i * step, total_length)))

	var line_points := PackedVector3Array()
	for i in samples.size() - 1:
		line_points.append(samples[i])
		line_points.append(samples[i + 1])
	if spline.closed and samples.size() > 1:
		line_points.append(samples[samples.size() - 1])
		line_points.append(samples[0])
	if line_points.size() > 0:
		gizmo.add_lines(line_points, path_material, false)

	# Pickable collision segments (local space, like the built-in Path3D gizmo) so a
	# click anywhere on ANY path's curve selects the TrackSpline node in the viewport.
	if line_points.size() > 0:
		gizmo.add_collision_segments(line_points)

	# Point handles + control handles. Point handles split by flag so Start/Finish (cyan,
	# large), Branch Split (green), Branch Join (red), and Waypoints (icon) are distinct.
	# Flag priority when a point carries several: Start/Finish > Split > Join > Waypoint.
	var point_handles := PackedVector3Array()
	var point_ids := PackedInt32Array()
	var start_finish_handles := PackedVector3Array()
	var start_finish_ids := PackedInt32Array()
	var split_handles := PackedVector3Array()
	var split_ids := PackedInt32Array()
	var join_handles := PackedVector3Array()
	var join_ids := PackedInt32Array()
	var waypoint_handles := PackedVector3Array()
	var waypoint_ids := PackedInt32Array()
	var control_handles := PackedVector3Array()
	var control_ids := PackedInt32Array()
	var control_lines := PackedVector3Array()

	var point_count: int = spline.point_count
	for idx in point_count:
		var pos: Vector3 = spline.get_point_position(idx)

		var flags: int = spline.get_point_flags(idx)
		if flags & Spline.SplinePointFlags.START_FINISH:
			start_finish_handles.append(pos)
			start_finish_ids.append(_encode(path_index, idx, ID_POINT))
		elif flags & Spline.SplinePointFlags.BRANCH_SPLIT:
			split_handles.append(pos)
			split_ids.append(_encode(path_index, idx, ID_POINT))
		elif flags & Spline.SplinePointFlags.BRANCH_JOIN:
			join_handles.append(pos)
			join_ids.append(_encode(path_index, idx, ID_POINT))
		elif flags & Spline.SplinePointFlags.WAYPOINT:
			waypoint_handles.append(pos)
			waypoint_ids.append(_encode(path_index, idx, ID_POINT))
		else:
			point_handles.append(pos)
			point_ids.append(_encode(path_index, idx, ID_POINT))

		# In-control handle (skip first point).
		if idx > 0:
			var in_vec: Vector3 = spline.get_point_in(idx)
			control_lines.append(pos)
			control_lines.append(pos + in_vec)
			control_handles.append(pos + in_vec)
			control_ids.append(_encode(path_index, idx, ID_IN))

		# Out-control handle (skip last point).
		if idx < point_count - 1:
			var out_vec: Vector3 = spline.get_point_out(idx)
			control_lines.append(pos)
			control_lines.append(pos + out_vec)
			control_handles.append(pos + out_vec)
			control_ids.append(_encode(path_index, idx, ID_OUT))

	if control_lines.size() > 0:
		gizmo.add_lines(control_lines, get_material("control_lines", gizmo), false)
	if point_handles.size() > 0:
		gizmo.add_handles(point_handles, get_material("point_handles", gizmo), point_ids, false, false)
	if split_handles.size() > 0:
		gizmo.add_handles(split_handles, get_material("handle_branch_split", gizmo), split_ids, false, false)
	if join_handles.size() > 0:
		gizmo.add_handles(join_handles, get_material("handle_branch_join", gizmo), join_ids, false, false)
	if waypoint_handles.size() > 0:
		gizmo.add_handles(waypoint_handles, get_material("handle_waypoint", gizmo), waypoint_ids, true, false)
	if start_finish_handles.size() > 0:
		gizmo.add_handles(start_finish_handles, get_material("handle_start_finish", gizmo), start_finish_ids, true, false)
	if control_handles.size() > 0:
		gizmo.add_handles(control_handles, get_material("control_handles", gizmo), control_ids, false, true)


# --- Branch / wire-source overlay -----------------------------------------------------------

func _draw_branches(gizmo: EditorNode3DGizmo, track: TrackSpline) -> void:
	var materials_created: Dictionary = {}
	for connection: BranchConnection in track.branches:
		if connection == null:
			continue
		var from_spline: Spline = track.get_spline_at(connection.from_path_index)
		var to_spline: Spline = track.get_spline_at(connection.to_path_index)
		if from_spline == null or to_spline == null:
			continue
		if connection.from_point_index < 0 or connection.from_point_index >= from_spline.point_count:
			continue
		if connection.to_point_index < 0 or connection.to_point_index >= to_spline.point_count:
			continue
		var a: Vector3 = from_spline.get_point_position(connection.from_point_index)
		var b: Vector3 = to_spline.get_point_position(connection.to_point_index)

		# Per-branch material keyed by the endpoint pair so removing/re-adding a branch
		# reuses its color instead of leaking a fresh material per branch index.
		var key := "%d:%d-%d:%d" % [connection.from_path_index, connection.from_point_index,
				connection.to_path_index, connection.to_point_index]
		if not materials_created.has(key):
			var midpoint: Color = _path_color(track, connection.from_path_index).lerp(
					_path_color(track, connection.to_path_index), 0.5)
			create_material("branch_%s" % key, midpoint)
			materials_created[key] = true
		var mat := get_material("branch_%s" % key, gizmo)
		gizmo.add_lines(PackedVector3Array([a, b]), mat, false)


## The color a path draws in. Main path reads the node's Debug Shape > Custom color
## (pure black 0000 = "use default", falls back to white). Alternates use ALTERNATE_COLORS.
func _path_color(track: Node3D, path_index: int) -> Color:
	if path_index <= 0:
		var debug_color: Color = track.debug_custom_color
		if debug_color.r == 0.0 and debug_color.g == 0.0 and debug_color.b == 0.0:
			return Color(1, 1, 1, 0.9)
		return debug_color
	return ALTERNATE_COLORS[path_index % ALTERNATE_COLORS.size()]


func _draw_wire_source(gizmo: EditorNode3DGizmo, track: TrackSpline) -> void:
	if wire_source.is_empty():
		return
	var path_index: int = wire_source.get("path_index", -1)
	var point_index: int = wire_source.get("point_index", -1)
	var spline: Spline = track.get_spline_at(path_index)
	if spline == null or point_index < 0 or point_index >= spline.point_count:
		return
	var pos: Vector3 = spline.get_point_position(point_index)
	var s := 0.6
	var cross := PackedVector3Array([
		pos + Vector3(-s, 0, 0), pos + Vector3(s, 0, 0),
		pos + Vector3(0, -s, 0), pos + Vector3(0, s, 0),
		pos + Vector3(0, 0, -s), pos + Vector3(0, 0, s),
	])
	gizmo.add_lines(cross, get_material("wire_source", gizmo), false)


# --- Handle interaction ---------------------------------------------------------------------

func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	var d := _decode(handle_id)
	if not d.valid:
		return "Track"
	var suffix := "Path %d Point #%d" % [d.path_index, d.point_index]
	if d.kind == ID_IN:
		return "In Control #%d (%s)" % [d.point_index, suffix]
	if d.kind == ID_OUT:
		return "Out Control #%d (%s)" % [d.point_index, suffix]
	return suffix


func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	var track := gizmo.get_node_3d() as TrackSpline
	var spline := _spline_for_handle(track, handle_id)
	if spline == null:
		return null
	var d := _decode(handle_id)
	if d.kind == ID_IN:
		return spline.get_point_in(d.point_index)
	if d.kind == ID_OUT:
		return spline.get_point_out(d.point_index)
	return spline.get_point_position(d.point_index)


func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var track := gizmo.get_node_3d() as TrackSpline
	if track == null:
		return
	var d := _decode(handle_id)
	var spline := _spline_for_handle(track, handle_id)
	if spline == null:
		return

	var gt: Transform3D = track.global_transform
	var gi: Transform3D = gt.affine_inverse()
	var ray_from: Vector3 = camera.project_ray_origin(screen_pos)
	var ray_dir: Vector3 = camera.project_ray_normal(screen_pos)

	if d.kind == ID_POINT:
		var world_pos: Vector3 = gt * spline.get_point_position(d.point_index)
		var inters: Variant = null
		if SNAP_TO_SURFACE:
			inters = _raycast_to_surface(track, camera, ray_from, ray_dir)
		if inters == null:
			var plane := Plane(camera.global_transform.basis.z, world_pos)
			inters = plane.intersects_ray(ray_from, ray_dir)
		if inters != null:
			var local := _snap(gi * (inters as Vector3))
			spline.set_point_position(d.point_index, local)
		return

	# In / Out control handle: plane through the anchor point, offset from it.
	var base: Vector3 = gt * spline.get_point_position(d.point_index)
	var plane := Plane(camera.global_transform.basis.z, base)
	var inters: Variant = plane.intersects_ray(ray_from, ray_dir)
	if inters != null:
		var local := _snap(gi * (inters as Vector3) - spline.get_point_position(d.point_index))
		if d.kind == ID_IN:
			spline.set_point_in(d.point_index, local)
		else:
			spline.set_point_out(d.point_index, local)


func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	var track := gizmo.get_node_3d() as TrackSpline
	if track == null:
		return
	var d := _decode(handle_id)
	var spline := _spline_for_handle(track, handle_id)
	if spline == null:
		return

	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()

	if d.kind == ID_POINT:
		if cancel:
			spline.set_point_position(d.point_index, restore)
			return
		ur.create_action("Set Track Point Position")
		ur.add_do_method(spline, "set_point_position", d.point_index, spline.get_point_position(d.point_index))
		ur.add_undo_method(spline, "set_point_position", d.point_index, restore)
		ur.commit_action()
		return

	var is_in: bool = d.kind == ID_IN
	var getter := "get_point_in" if is_in else "get_point_out"
	var setter := "set_point_in" if is_in else "set_point_out"
	if cancel:
		spline.call(setter, d.point_index, restore)
		return
	ur.create_action("Set Track Control Point")
	ur.add_do_method(spline, setter, d.point_index, spline.call(getter, d.point_index))
	ur.add_undo_method(spline, setter, d.point_index, restore)
	ur.commit_action()


# --- Subgizmos (move-tool point drag) -------------------------------------------------------

func _subgizmos_intersect_ray(gizmo: EditorNode3DGizmo, camera: Camera3D, screen_pos: Vector2) -> int:
	var track := gizmo.get_node_3d() as TrackSpline
	if track == null:
		return -1
	var best_id := -1
	var best_dist := 12.0
	for path_index in track.get_path_count():
		var spline: Spline = track.get_spline_at(path_index)
		if spline == null:
			continue
		for idx in spline.point_count:
			var world_pos: Vector3 = track.to_global(spline.get_point_position(idx))
			var d: float = camera.unproject_position(world_pos).distance_to(screen_pos)
			if d < best_dist:
				best_dist = d
				best_id = _encode(path_index, idx, ID_POINT)
	return best_id


func _subgizmos_intersect_frustum(gizmo: EditorNode3DGizmo, camera: Camera3D, frustum_planes: Array) -> PackedInt32Array:
	var result := PackedInt32Array()
	var track := gizmo.get_node_3d() as TrackSpline
	if track == null:
		return result
	for path_index in track.get_path_count():
		var spline: Spline = track.get_spline_at(path_index)
		if spline == null:
			continue
		for idx in spline.point_count:
			var world_pos: Vector3 = track.to_global(spline.get_point_position(idx))
			var inside := true
			for plane: Plane in frustum_planes:
				if plane.distance_to(world_pos) < 0.0:
					inside = false
					break
			if inside:
				result.append(_encode(path_index, idx, ID_POINT))
	return result


func _get_subgizmo_transform(gizmo: EditorNode3DGizmo, subgizmo_id: int) -> Transform3D:
	var track := gizmo.get_node_3d() as TrackSpline
	var spline := _spline_for_handle(track, subgizmo_id)
	if spline == null:
		return Transform3D()
	var d := _decode(subgizmo_id)
	if not _valid_point(d, spline):
		return Transform3D()
	return Transform3D(Basis(), spline.get_point_position(d.point_index))


func _set_subgizmo_transform(gizmo: EditorNode3DGizmo, subgizmo_id: int, transform: Transform3D) -> void:
	var track := gizmo.get_node_3d() as TrackSpline
	var spline := _spline_for_handle(track, subgizmo_id)
	if spline == null:
		return
	var d := _decode(subgizmo_id)
	if not _valid_point(d, spline):
		return
	spline.set_point_position(d.point_index, transform.origin)
	if track and track.is_inside_tree():
		track.update_gizmos()


func _commit_subgizmos(gizmo: EditorNode3DGizmo, ids: PackedInt32Array, restores: Array, cancel: bool) -> void:
	var track := gizmo.get_node_3d() as TrackSpline
	if track == null:
		return
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	if cancel:
		for i in ids.size():
			var d := _decode(ids[i])
			if not d.valid:
				continue
			var spline: Spline = track.get_spline_at(d.path_index)
			if spline and _valid_point(d, spline):
				spline.set_point_position(d.point_index, (restores[i] as Transform3D).origin)
		if track.is_inside_tree():
			track.update_gizmos()
		return
	ur.create_action("Move Track Points")
	for i in ids.size():
		var d := _decode(ids[i])
		if not d.valid:
			continue
		var spline: Spline = track.get_spline_at(d.path_index)
		if spline == null or not _valid_point(d, spline):
			continue
		var idx: int = d.point_index
		ur.add_do_method(spline, "set_point_position", idx, spline.get_point_position(idx))
		ur.add_undo_method(spline, "set_point_position", idx, (restores[i] as Transform3D).origin)
	ur.commit_action()


# --- Helpers --------------------------------------------------------------------------------

func _spline_for_handle(track: TrackSpline, handle_id: int) -> Spline:
	if track == null:
		return null
	var d := _decode(handle_id)
	if not d.valid:
		return null
	return track.get_spline_at(d.path_index)


## True when a decoded id addresses a real point on `spline` (kind POINT, index in
## bounds). Foreign ids and empty-path decodes fail here so mixed selections degrade
## gracefully instead of moving the wrong point.
func _valid_point(d: Dictionary, spline: Spline) -> bool:
	return d.valid and d.kind == ID_POINT and spline != null \
			and d.point_index >= 0 and d.point_index < spline.point_count


## Nearest point under the cursor across every path, or {} when nothing is within max_dist
## screen pixels. Used by the plugin's Wire Branch tool (and point-add collision guard).
func find_point_at_screen(track: TrackSpline, camera: Camera3D, screen_pos: Vector2, max_dist: float = 12.0) -> Dictionary:
	var best := {}
	var best_dist := max_dist
	for path_index in track.get_path_count():
		var spline: Spline = track.get_spline_at(path_index)
		if spline == null:
			continue
		for idx in spline.point_count:
			var world_pos: Vector3 = track.to_global(spline.get_point_position(idx))
			var d: float = camera.unproject_position(world_pos).distance_to(screen_pos)
			if d <= best_dist:
				best_dist = d
				best = {"path_index": path_index, "point_index": idx}
	return best


func _snap(v: Vector3) -> Vector3:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	if settings.get_setting("editors/3d/use_snap"):
		var snap: float = settings.get_setting("editors/3d/translate_snap")
		if snap > 0.0:
			v = (v / snap).round() * snap
	return v


func _raycast_to_surface(track: Node3D, camera: Camera3D, ray_from: Vector3, ray_dir: Vector3) -> Variant:
	var world := track.get_world_3d()
	if world == null:
		return null
	var space := world.direct_space_state
	if space == null:
		return null
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_from + ray_dir * camera.far)
	var result := space.intersect_ray(query)
	if result.is_empty():
		return null
	return result.get("position", null)
