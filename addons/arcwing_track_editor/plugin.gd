@tool
extends EditorPlugin

## Registers the TrackSpline gizmo plugin and adds a 3D-viewport toolbar for authoring paths:
##   + New Path   — append an empty alternate Spline (path index 1..N)
##   Wire Branch  — click a source point, then a target point to add a BranchConnection
## All actions are undoable via EditorUndoRedoManager.
##
## The built-in Path3D "Add Point (in empty space)" button always appends to Path3D.curve
## (the MAIN path) and forwards input before this plugin, so it can't be intercepted. This
## plugin watches the main spline's `changed` signal instead: when a point lands on main via
## a live built-in click while a DIFFERENT path is selected, it moves the point to that path;
## when a modifier key was held (the built-in drops points on alt+click on non-Maya/Modo
## nav schemes), it discards the accidental point.

const TrackSplineGizmoPluginScript = preload("res://addons/arcwing_track_editor/track_spline_gizmo_plugin.gd")
const PathDataDockScene = preload("res://addons/arcwing_track_editor/path_data_dock.tscn")

const MODE_EDIT := 0
const MODE_WIRE := 1

var _gizmo_plugin : EditorNode3DGizmoPlugin
var _dock : PathDataDock

var _toolbar : HBoxContainer
var _path_selector : OptionButton
var _new_path_button : Button
var _wire_button : Button

var _track : TrackSpline
var _mode : int = MODE_EDIT
var _active_path_index : int = 0
var _wire_from : Dictionary = {}

## Main-path point redirect for the built-in "Add Point (in empty space)" button. The
## built-in Path3D tool always appends to Path3D.curve (the MAIN path) and it forwards
## input before our plugin, so we can't intercept the click. Instead we watch the main
## spline's `changed` signal and, when a point lands on main while a DIFFERENT path is
## selected, move it to the selected path (or discard it if a modifier was held — the
## built-in drops points on alt+click on non-Maya/Modo nav schemes).
var _main_baseline_count : int = -1
var _main_snapshot : Array[Vector3] = []
var _handling_add : bool = false

## Spline resource currently watched for the main-path point redirect. Re-fetched every
## baseline sync in case TrackSpline.load_from_data swaps Path3D.curve.
var _main_spline_watching : Spline


func _enter_tree() -> void:
	_gizmo_plugin = TrackSplineGizmoPluginScript.new()
	add_node_3d_gizmo_plugin(_gizmo_plugin)
	_build_toolbar()
	_dock = PathDataDockScene.instantiate()
	_dock.name = "Track Point Data"
	_dock.point_navigated.connect(_on_dock_navigated)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, _dock)
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.version_changed.connect(_refresh_path_selector)
	ur.version_changed.connect(_update_gizmos)
	ur.version_changed.connect(_refresh_dock)


func _exit_tree() -> void:
	if _gizmo_plugin:
		remove_node_3d_gizmo_plugin(_gizmo_plugin)
		_gizmo_plugin = null
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	if _toolbar:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)
		_toolbar.queue_free()
		_toolbar = null


func _build_toolbar() -> void:
	_toolbar = HBoxContainer.new()
	_toolbar.add_theme_constant_override("separation", 4)

	_path_selector = OptionButton.new()
	_path_selector.tooltip_text = "Path that Add Point targets"
	_path_selector.item_selected.connect(_on_path_selected)
	_toolbar.add_child(_path_selector)

	_new_path_button = Button.new()
	_new_path_button.text = "+ New Path"
	_new_path_button.tooltip_text = "Add an empty alternate path (path index 1..N)"
	_new_path_button.pressed.connect(_on_new_path_pressed)
	_toolbar.add_child(_new_path_button)

	_wire_button = Button.new()
	_wire_button.text = "Wire Branch"
	_wire_button.toggle_mode = true
	_wire_button.tooltip_text = "Click a source point, then a target point to add a BranchConnection"
	_wire_button.toggled.connect(_on_mode_toggled.bind(MODE_WIRE))
	_toolbar.add_child(_wire_button)

	_toolbar.visible = false
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)


func _handles(object : Object) -> bool:
	return object is TrackSpline


func _edit(object : Object) -> void:
	if _track and _track.paths_changed.is_connected(_on_track_paths_changed):
		_track.paths_changed.disconnect(_on_track_paths_changed)
	_track = object as TrackSpline
	if _track:
		_track.paths_changed.connect(_on_track_paths_changed)
		_active_path_index = 0
		_clear_wire()
		_set_mode(MODE_EDIT)
		_refresh_path_selector()
		_watch_main_spline()
		_update_gizmos()
	if _dock:
		_dock.visible = _track != null
		_dock.set_track(_track)
		_dock.refresh(_gizmo_plugin.get_selected_point())


func _make_visible(p_visible : bool) -> void:
	if _toolbar:
		_toolbar.visible = p_visible
	if _dock:
		_dock.visible = p_visible
	if not p_visible:
		if _track and _track.paths_changed.is_connected(_on_track_paths_changed):
			_track.paths_changed.disconnect(_on_track_paths_changed)
		_track = null
		_unwatch_main_spline()
		_clear_wire()
		_clear_selection()
		if _dock:
			_dock.set_track(null)
			_dock.refresh({})


# --- Toolbar handlers ------------------------------------------------------------------------

func _on_path_selected(index : int) -> void:
	_active_path_index = index
	_update_gizmos()


func _on_new_path_pressed() -> void:
	if _track == null:
		return
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	var undo_index : int = _track.alternate_paths.size()
	ur.create_action("Add Alternate Path")
	ur.add_do_method(_track, "add_alternate_path")
	ur.add_undo_method(_track, "remove_alternate_path", undo_index)
	ur.commit_action()
	_active_path_index = undo_index + 1
	_refresh_path_selector()
	_update_gizmos()


func _on_mode_toggled(pressed : bool, mode : int) -> void:
	if pressed:
		_set_mode(mode)
	elif _mode == mode:
		_set_mode(MODE_EDIT)


func _set_mode(mode : int) -> void:
	_mode = mode
	if _wire_button:
		_wire_button.set_pressed_no_signal(mode == MODE_WIRE)
	if mode != MODE_WIRE:
		_clear_wire()
	_update_gizmos()


func _refresh_path_selector() -> void:
	if _path_selector == null or _track == null:
		return
	var count : int = _track.get_path_count()
	_path_selector.clear()
	_path_selector.add_item("Main (0)")
	for i in count - 1:
		_path_selector.add_item("Alt %d" % (i + 1))
	_active_path_index = clampi(_active_path_index, 0, count - 1)
	_path_selector.select(_active_path_index)


func _on_track_paths_changed() -> void:
	_refresh_path_selector()
	_watch_main_spline()
	_update_gizmos()


# --- Built-in "Add Point (in empty space)" redirect ----------------------------------------
## The built-in Path3D tool forwards clicks before this plugin and always targets
## Path3D.curve (main). We watch the main spline's `changed` signal: a live commit
## (is_committing_action) that grows the main spline by exactly one point is a built-in
## click. When a different path is selected we move the new point there; when a modifier
## key was held (the built-in drops points on alt+click outside Maya/Modo nav schemes) we
## discard it instead. Undo/redo replays are ignored because they don't commit an action.

func _watch_main_spline() -> void:
	if _main_spline_watching:
		if _main_spline_watching.changed.is_connected(_on_main_spline_changed):
			_main_spline_watching.changed.disconnect(_on_main_spline_changed)
		_main_spline_watching = null
	if _track == null:
		return
	var main : Spline = _track.get_spline()
	if main == null:
		return
	_main_spline_watching = main
	_main_spline_watching.changed.connect(_on_main_spline_changed)
	_sync_main_baseline()


func _unwatch_main_spline() -> void:
	if _main_spline_watching:
		if _main_spline_watching.changed.is_connected(_on_main_spline_changed):
			_main_spline_watching.changed.disconnect(_on_main_spline_changed)
		_main_spline_watching = null
	_main_baseline_count = -1
	_main_snapshot.clear()


func _sync_main_baseline() -> void:
	var main : Spline = _track.get_spline() if _track else null
	if main == null:
		_main_baseline_count = -1
		_main_snapshot.clear()
		return
	_main_baseline_count = main.point_count
	_main_snapshot.clear()
	for i in main.point_count:
		_main_snapshot.append(main.get_point_position(i))


func _on_main_spline_changed() -> void:
	if _handling_add or _track == null:
		return
	var main : Spline = _track.get_spline()
	if main == null:
		return
	var count : int = main.point_count
	if count - _main_baseline_count != 1:
		_sync_main_baseline()
		return
	if not EditorInterface.get_editor_undo_redo().is_committing_action():
		_sync_main_baseline()
		return
	var modifiers : bool = Input.is_key_pressed(KEY_ALT) or Input.is_key_pressed(KEY_SHIFT) \
			or Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)
	var added_index : int = _find_added_index(main)
	_sync_main_baseline()
	if added_index < 0:
		return
	call_deferred("_redirect_added_point", added_index, modifiers)


## Index of the single point the main spline gained since the last baseline snapshot.
func _find_added_index(main : Spline) -> int:
	for i in main.point_count:
		if i < _main_snapshot.size():
			if _main_snapshot[i] == main.get_point_position(i):
				continue
		return i
	return -1


func _redirect_added_point(added_index : int, modifiers : bool) -> void:
	if _handling_add or _track == null:
		return
	var main : Spline = _track.get_spline()
	if main == null or added_index < 0 or added_index >= main.point_count:
		return
	_handling_add = true
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	var pos : Vector3 = main.get_point_position(added_index)
	var in_ctl : Vector3 = main.get_point_in(added_index)
	var out_ctl : Vector3 = main.get_point_out(added_index)
	if modifiers:
		ur.create_action("Discard Accidental Track Point")
		ur.add_do_method(main, "remove_point", added_index)
		ur.add_undo_method(main, "add_point", pos, in_ctl, out_ctl, added_index)
		ur.commit_action()
		_handling_add = false
		_sync_main_baseline()
		_update_gizmos()
		return
	var target : Spline = _track.get_spline_at(_active_path_index)
	if target == null or target == main:
		_handling_add = false
		_sync_main_baseline()
		return
	ur.create_action("Add Track Point to Path %d" % _active_path_index)
	ur.add_do_method(main, "remove_point", added_index)
	ur.add_do_method(target, "add_point", pos, in_ctl, out_ctl, -1)
	ur.add_undo_method(target, "remove_point", target.point_count)
	ur.add_undo_method(main, "add_point", pos, in_ctl, out_ctl, added_index)
	ur.commit_action()
	_handling_add = false
	_sync_main_baseline()
	_update_gizmos()


# --- 3D viewport input -----------------------------------------------------------------------

func _forward_3d_gui_input(camera : Camera3D, event : InputEvent) -> int:
	if _track == null:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	# Never hijack a click while a modifier is held — alt+click orbits the camera,
	# ctrl/shift/meta drive selection and snapping. Let the viewport handle those.
	if mb.alt_pressed or mb.shift_pressed or mb.ctrl_pressed or mb.meta_pressed:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		return _remove_point_click(camera, mb.position)
	if _mode == MODE_EDIT:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_select_point_on_press(camera, mb.position)
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _mode == MODE_WIRE:
		return _wire_click(camera, mb.position)
	return EditorPlugin.AFTER_GUI_INPUT_PASS


## Left-click over a point in EDIT mode selects it for the live path-data dock. Selecting on
## press (not release) means the click that starts a drag also selects, and plain clicks work
## too. Returns AFTER_GUI_INPUT_PASS so the viewport's handle/subgizmo grab proceeds; the
## gizmo refresh is deferred so it can't cancel an in-flight drag grab.
func _select_point_on_press(camera : Camera3D, screen_pos : Vector2) -> void:
	if _track == null or _gizmo_plugin == null:
		return
	var hit : Dictionary = _gizmo_plugin.find_point_at_screen(_track, camera, screen_pos)
	if hit.is_empty():
		return
	_gizmo_plugin.set_selected_point(hit.path_index, hit.point_index)
	call_deferred("_update_gizmos")
	_refresh_dock()


func _remove_point_click(camera : Camera3D, screen_pos : Vector2) -> int:
	var hit : Dictionary = _gizmo_plugin.find_point_at_screen(_track, camera, screen_pos)
	if hit.is_empty():
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var spline : Spline = _track.get_spline_at(hit.path_index)
	if spline == null or hit.point_index >= spline.point_count:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _gizmo_plugin.wire_source == hit:
		_clear_wire()
	_track.remove_point_with_branches(hit.path_index, hit.point_index)
	_update_gizmos()
	return EditorPlugin.AFTER_GUI_INPUT_STOP


func _wire_click(camera : Camera3D, screen_pos : Vector2) -> int:
	var hit : Dictionary = _gizmo_plugin.find_point_at_screen(_track, camera, screen_pos)
	if hit.is_empty():
		if not _wire_from.is_empty():
			_clear_wire()
			_update_gizmos()
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _wire_from.is_empty():
		_wire_from = hit
		_gizmo_plugin.wire_source = hit
		_update_gizmos()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	var from : Dictionary = _wire_from
	_clear_wire()
	if from.path_index == hit.path_index and from.point_index == hit.point_index:
		_update_gizmos()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	_create_branch(from, hit)
	_update_gizmos()
	return EditorPlugin.AFTER_GUI_INPUT_STOP


func _create_branch(from : Dictionary, to : Dictionary) -> void:
	var connection := BranchConnection.new()
	connection.from_path_index = from.path_index
	connection.from_point_index = from.point_index
	connection.to_path_index = to.path_index
	connection.to_point_index = to.point_index
	connection.is_split = true
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("Add Branch Connection")
	ur.add_do_method(_track, "add_branch", connection)
	ur.add_undo_method(_track, "remove_branch", _track.branches.size())
	ur.commit_action()


# --- Helpers ---------------------------------------------------------------------------------

func _clear_wire() -> void:
	_wire_from = {}
	if _gizmo_plugin:
		_gizmo_plugin.wire_source = {}


## Clear the gizmo's selected point (dock hides / shows "no selection").
func _clear_selection() -> void:
	if _gizmo_plugin:
		_gizmo_plugin.set_selected_point(-1, -1)


## Dock ◀ ▶ / path / branch-jump navigation: retarget the gizmo selection and refresh.
func _on_dock_navigated(path_index : int, point_index : int) -> void:
	if _gizmo_plugin:
		_gizmo_plugin.set_selected_point(path_index, point_index)
		_update_gizmos()
		_refresh_dock()


func _refresh_dock() -> void:
	if _dock:
		_dock.refresh(_gizmo_plugin.get_selected_point() if _gizmo_plugin else {})


func _update_gizmos() -> void:
	if _track:
		_track.update_gizmos()
