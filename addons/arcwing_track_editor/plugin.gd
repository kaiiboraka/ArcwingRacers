@tool
extends EditorPlugin

## Registers the TrackSpline gizmo plugin and adds a 3D-viewport toolbar for authoring paths:
##   + New Path   — append an empty alternate Spline (path index 1..N)
##   Add Point    — click in the viewport to append a point to the selected path (surface-snapped)
##   Wire Branch  — click a source point, then a target point to add a BranchConnection
## All actions are undoable via EditorUndoRedoManager.

const TrackSplineGizmoPluginScript = preload("res://addons/arcwing_track_editor/track_spline_gizmo_plugin.gd")

const MODE_EDIT := 0
const MODE_WIRE := 1

var _gizmo_plugin: EditorNode3DGizmoPlugin

var _toolbar: HBoxContainer
var _path_selector: OptionButton
var _new_path_button: Button
var _wire_button: Button

var _track: TrackSpline
var _mode: int = MODE_EDIT
var _active_path_index: int = 0
var _wire_from: Dictionary = {}


func _enter_tree() -> void:
	_gizmo_plugin = TrackSplineGizmoPluginScript.new()
	add_node_3d_gizmo_plugin(_gizmo_plugin)
	_build_toolbar()
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.version_changed.connect(_refresh_path_selector)
	ur.version_changed.connect(_update_gizmos)


func _exit_tree() -> void:
	if _gizmo_plugin:
		remove_node_3d_gizmo_plugin(_gizmo_plugin)
		_gizmo_plugin = null
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


func _handles(object: Object) -> bool:
	return object is TrackSpline


func _edit(object: Object) -> void:
	if _track and _track.paths_changed.is_connected(_on_track_paths_changed):
		_track.paths_changed.disconnect(_on_track_paths_changed)
	_track = object as TrackSpline
	if _track:
		_track.paths_changed.connect(_on_track_paths_changed)
		_active_path_index = 0
		_clear_wire()
		_set_mode(MODE_EDIT)
		_refresh_path_selector()
		_update_gizmos()


func _make_visible(p_visible: bool) -> void:
	if _toolbar:
		_toolbar.visible = p_visible
	if not p_visible:
		if _track and _track.paths_changed.is_connected(_on_track_paths_changed):
			_track.paths_changed.disconnect(_on_track_paths_changed)
		_track = null
		_clear_wire()


# --- Toolbar handlers ------------------------------------------------------------------------

func _on_path_selected(index: int) -> void:
	_active_path_index = index
	_update_gizmos()


func _on_new_path_pressed() -> void:
	if _track == null:
		return
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	var undo_index: int = _track.alternate_paths.size()
	ur.create_action("Add Alternate Path")
	ur.add_do_method(_track, "add_alternate_path")
	ur.add_undo_method(_track, "remove_alternate_path", undo_index)
	ur.commit_action()
	_active_path_index = undo_index + 1
	_refresh_path_selector()
	_update_gizmos()


func _on_mode_toggled(pressed: bool, mode: int) -> void:
	if pressed:
		_set_mode(mode)
	elif _mode == mode:
		_set_mode(MODE_EDIT)


func _set_mode(mode: int) -> void:
	_mode = mode
	if _wire_button:
		_wire_button.set_pressed_no_signal(mode == MODE_WIRE)
	if mode != MODE_WIRE:
		_clear_wire()
	_update_gizmos()


func _refresh_path_selector() -> void:
	if _path_selector == null or _track == null:
		return
	var count: int = _track.get_path_count()
	_path_selector.clear()
	_path_selector.add_item("Main (0)")
	for i in count - 1:
		_path_selector.add_item("Alt %d" % (i + 1))
	_active_path_index = clampi(_active_path_index, 0, count - 1)
	_path_selector.select(_active_path_index)


func _on_track_paths_changed() -> void:
	_refresh_path_selector()
	_update_gizmos()


# --- 3D viewport input -----------------------------------------------------------------------

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
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
	if _mode == MODE_EDIT or mb.button_index != MOUSE_BUTTON_LEFT:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _mode == MODE_WIRE:
		return _wire_click(camera, mb.position)
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _remove_point_click(camera: Camera3D, screen_pos: Vector2) -> int:
	var hit: Dictionary = _gizmo_plugin.find_point_at_screen(_track, camera, screen_pos)
	if hit.is_empty():
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var spline: Spline = _track.get_spline_at(hit.path_index)
	if spline == null or hit.point_index >= spline.point_count:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var pos: Vector3 = spline.get_point_position(hit.point_index)
	var in_ctl: Vector3 = spline.get_point_in(hit.point_index)
	var out_ctl: Vector3 = spline.get_point_out(hit.point_index)
	if _gizmo_plugin.wire_source == hit:
		_clear_wire()
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("Remove Track Point")
	ur.add_do_method(spline, "remove_point", hit.point_index)
	ur.add_undo_method(spline, "add_point", pos, in_ctl, out_ctl, hit.point_index)
	ur.commit_action()
	_update_gizmos()
	return EditorPlugin.AFTER_GUI_INPUT_STOP


func _wire_click(camera: Camera3D, screen_pos: Vector2) -> int:
	var hit: Dictionary = _gizmo_plugin.find_point_at_screen(_track, camera, screen_pos)
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
	var from: Dictionary = _wire_from
	_clear_wire()
	if from.path_index == hit.path_index and from.point_index == hit.point_index:
		_update_gizmos()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	_create_branch(from, hit)
	_update_gizmos()
	return EditorPlugin.AFTER_GUI_INPUT_STOP


func _create_branch(from: Dictionary, to: Dictionary) -> void:
	var connection := BranchConnection.new()
	connection.from_path_index = from.path_index
	connection.from_point_index = from.point_index
	connection.to_path_index = to.path_index
	connection.to_point_index = to.point_index
	connection.is_split = true
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("Add Branch Connection")
	ur.add_do_method(_track, "add_branch", connection)
	ur.add_undo_method(_track, "remove_branch", _track.branches.size())
	ur.commit_action()


# --- Helpers ---------------------------------------------------------------------------------

func _clear_wire() -> void:
	_wire_from = {}
	if _gizmo_plugin:
		_gizmo_plugin.wire_source = {}


func _update_gizmos() -> void:
	if _track:
		_track.update_gizmos()
