@tool
class_name PathDataDock extends VBoxContainer

## Contextual editor dock (right side) for editing the selected point's SplinePointData
## live — width, tilt/banking, recipe, recipe param, and flags — instead of raw Inspector
## arrays. Wired by the track-editor plugin: hidden until a TrackSpline is selected, and
## shows a "click a point" hint until one is picked. All edits go through
## EditorUndoRedoManager so Ctrl+Z undoes them.
##
## Tilt is edited in degrees and stored in radians on SplinePointData.tilt (pushed through
## to Curve3D's native tilt by Spline._on_point_data_changed).

signal point_navigated(path_index : int, point_index : int);

const FLAG_NAMES := ["Start Finish", "Waypoint", "Respawn", "Path Entrance", "Path Exit"];
const FLAG_BITS := [1 << 0, 1 << 1, 1 << 2, 1 << 3, 1 << 4];
const RECIPE_NAMES := ["None", "Road", "Tunnel"];

var _track : TrackSpline;
var _spline : Spline;
var _path_index : int = -1;
var _point_index : int = -1;

var _path_selector : OptionButton;
var _point_label : Label;
var _prev_button : Button;
var _next_button : Button;
var _position_label : Label;
var _width_spin : SpinBox;
var _tilt_spin : SpinBox;
var _recipe_option : OptionButton;
var _tunnel_spin : SpinBox;
var _flag_checks : Array[CheckBox] = [];
var _branch_box : VBoxContainer;
var _defaults_label : Label;
var _empty_label : Label;
var _form : VBoxContainer;
var _path_name_edit : LineEdit;
var _delete_connections_button : Button;
var _delete_points_button : Button;
var _delete_path_button : Button;
var _save_button : Button;

## Set while refreshing the UI so control signals don't fire edits back into the spline.
var _updating := false;


func _init() -> void:
	_build_ui();


func _build_ui() -> void:
	_empty_label = Label.new();
	_empty_label.text = "Select a point to edit its track data.";
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;
	_empty_label.custom_minimum_size = Vector2(200, 0);
	add_child(_empty_label);

	_form = VBoxContainer.new();
	_form.add_theme_constant_override("separation", 6);
	add_child(_form);

	var header := HBoxContainer.new();
	_form.add_child(header);

	_prev_button = Button.new();
	_prev_button.text = "◀";
	_prev_button.tooltip_text = "Previous point";
	_prev_button.pressed.connect(_on_nav.bind(-1));
	header.add_child(_prev_button);

	_path_selector = OptionButton.new();
	_path_selector.tooltip_text = "Path the selected point is on";
	_path_selector.item_selected.connect(_on_path_selected);
	header.add_child(_path_selector);
	_path_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL;

	_next_button = Button.new();
	_next_button.text = "▶";
	_next_button.tooltip_text = "Next point";
	_next_button.pressed.connect(_on_nav.bind(1));
	header.add_child(_next_button);

	_save_button = Button.new();
	_save_button.text = "Save";
	_save_button.tooltip_text = "Save this track's state (curve, paths, branches) into its TrackSplineData asset — same as the 'Save Track to Data' button on the TrackSpline";
	_save_button.pressed.connect(_on_save_pressed);
	header.add_child(_save_button);

	var branch_label : Label = _make_section_label("Branches");
	_form.add_child(branch_label);
	_branch_box = VBoxContainer.new();
	_branch_box.add_theme_constant_override("separation", 2);
	_form.add_child(_branch_box);

	var path_label : Label = _make_section_label("Path Controls");
	_form.add_child(path_label);

	var name_row := HBoxContainer.new();
	_form.add_child(name_row);
	var name_label : Label = Label.new();
	name_label.text = "Name";
	name_row.add_child(name_label);
	_path_name_edit = LineEdit.new();
	_path_name_edit.placeholder_text = "Main / Alt N";
	_path_name_edit.tooltip_text = "Display name for this path (empty = positional default)";
	_path_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	_path_name_edit.text_submitted.connect(_on_path_name_submitted);
	_path_name_edit.focus_exited.connect(_on_path_name_focus_exited);
	name_row.add_child(_path_name_edit);

	_delete_connections_button = _make_delete_button("Delete Connections", "Remove every branch touching this path", _on_delete_connections_pressed);
	_delete_points_button = _make_delete_button("Delete Points", "Remove every point on this path (branches to them are removed too)", _on_delete_points_pressed);
	_delete_path_button = _make_delete_button("Delete Entire Path", "Delete this path, its points, and its branches (main path clears its points instead)", _on_delete_path_pressed);

	var point_row := HBoxContainer.new();
	_form.add_child(point_row);
	var label : Label = _make_section_label("Point");
	point_row.add_child(label);
	_point_label = Label.new();
	_point_label.text = "-";
	_point_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	point_row.add_child(_point_label);

	_position_label = Label.new();
	_position_label.text = "";
	_position_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;
	_position_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7));
	_form.add_child(_position_label);

	_width_spin = _make_spin("Width (m)", 0.1, 50.0, 0.1, _on_width_changed);
	_tilt_spin = _make_spin("Tilt (deg)", -89.0, 89.0, 1.0, _on_tilt_changed);
	_tunnel_spin = _make_spin("Tunnel height (m)", 1.0, 50.0, 0.5, _on_tunnel_changed);
	_tunnel_spin.editable = false;

	_recipe_option = OptionButton.new();
	_recipe_option.tooltip_text = "Recipe for the span after this point";
	for name in RECIPE_NAMES:
		_recipe_option.add_item(name);
	_recipe_option.item_selected.connect(_on_recipe_changed);
	_form.add_child(_recipe_option);

	var flag_label : Label = _make_section_label("Flags");
	_form.add_child(flag_label);
	for i in FLAG_NAMES.size():
		var check := CheckBox.new();
		check.text = FLAG_NAMES[i];
		check.toggled.connect(_on_flag_toggled.bind(i));
		_form.add_child(check);
		_flag_checks.append(check);

	_defaults_label = Label.new();
	_defaults_label.text = "";
	_defaults_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;
	_defaults_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6));
	_form.add_child(_defaults_label);

	_show_empty(true);


func _make_spin(label_text : String, min_value : float, max_value : float, step : float, cb : Callable) -> SpinBox:
	var row := HBoxContainer.new();
	_form.add_child(row);
	var row_label : Label = Label.new();
	row_label.text = label_text;
	row.add_child(row_label);
	var spin := SpinBox.new();
	spin.min_value = min_value;
	spin.max_value = max_value;
	spin.step = step;
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	spin.value_changed.connect(cb);
	row.add_child(spin);
	return spin;


func _make_delete_button(label_text : String, tooltip : String, cb : Callable) -> Button:
	var button := Button.new();
	button.text = label_text;
	button.tooltip_text = tooltip;
	button.pressed.connect(cb);
	_form.add_child(button);
	return button;


## Section header label: bold so each dock section ("Branches", "Path Controls", "Point",
## "Flags") reads as a heading. Falls back to the regular font when the theme has no bold font.
func _make_section_label(text : String) -> Label:
	var label := Label.new();
	label.text = text;
	var bold_font : Font = get_theme_font("bold_font");
	if bold_font:
		label.add_theme_font_override("font", bold_font);
	return label;


# --- Public API (called by plugin.gd) ------------------------------------------------------

## Attach to the currently edited TrackSpline (or null when deselected).
func set_track(track : TrackSpline) -> void:
	_track = track;
	_path_index = -1;
	_point_index = -1;
	refresh({});


## Refresh the whole form from a selection dict {path_index, point_index}, or {} for none.
func refresh(selection : Dictionary) -> void:
	_updating = true;
	if _track == null:
		_show_empty(true);
		_updating = false;
		return;
	_path_index = selection.get("path_index", -1) if not selection.is_empty() else -1;
	_point_index = selection.get("point_index", -1) if not selection.is_empty() else -1;
	if _path_index < 0 or _point_index < 0:
		_show_empty(true);
		_updating = false;
		return;
	_spline = _track.get_spline_at(_path_index);
	if _spline == null or _point_index >= _spline.point_count:
		_path_index = -1;
		_point_index = -1;
		_spline = null;
		_show_empty(true);
		_updating = false;
		return;
	_show_empty(false);
	_populate_path_selector();
	_path_selector.select(clampi(_path_index, 0, _path_selector.item_count - 1));
	_path_name_edit.text = _spline.path_name if _spline.path_name != null else "";
	_delete_path_button.disabled = _path_index <= 0;
	_point_label.text = "%d / %d" % [_point_index, _spline.point_count - 1];
	_prev_button.disabled = _point_index <= 0;
	_next_button.disabled = _point_index >= _spline.point_count - 1;

	var world_pos : Vector3 = _track.to_global(_spline.get_point_position(_point_index));
	_position_label.text = "World: (%.2f, %.2f, %.2f)" % [world_pos.x, world_pos.y, world_pos.z];

	_width_spin.set_value_no_signal(_spline.get_point_width(_point_index));
	_tilt_spin.set_value_no_signal(rad_to_deg(_spline.get_point_data(_point_index).tilt));
	_recipe_option.select(int(_spline.get_point_recipe(_point_index)));
	_update_tunnel_enabled();
	_tunnel_spin.set_value_no_signal(_spline.get_point_recipe_param(_point_index));

	var flags : int = _spline.get_point_flags(_point_index);
	for i in _flag_checks.size():
		_flag_checks[i].set_pressed_no_signal(flags & FLAG_BITS[i] != 0);

	_refresh_branches();
	_refresh_defaults();
	_updating = false;


# --- UI state helpers -----------------------------------------------------------------------

func _show_empty(empty : bool) -> void:
	_empty_label.visible = empty;
	_form.visible = not empty;


func _populate_path_selector() -> void:
	var prev_select := _path_selector.selected if _path_selector.item_count > 0 else -1;
	_path_selector.clear();
	if _track == null:
		return;
	for i in _track.get_path_count():
		_path_selector.add_item(_track.get_path_display_name(i));
	if prev_select >= 0:
		_path_selector.select(prev_select);


func _update_tunnel_enabled() -> void:
	var recipe_enabled : bool = _spline != null and int(_spline.get_point_recipe(_point_index)) == 2;
	_tunnel_spin.editable = recipe_enabled;
	_tunnel_spin.modulate = Color.WHITE if recipe_enabled else Color(0.6, 0.6, 0.6);


func _refresh_branches() -> void:
	for child in _branch_box.get_children():
		child.queue_free();
	if _track == null or _track.branches.is_empty():
		var none_label : Label = Label.new();
		none_label.text = "None";
		_branch_box.add_child(none_label);
		return;
	var found := false;
	for i in _track.branches.size():
		var b : BranchConnection = _track.branches[i];
		if b == null:
			continue;
		var connects : bool = (b.from_path_index == _path_index and b.from_point_index == _point_index) \
				or (b.to_path_index == _path_index and b.to_point_index == _point_index);
		if not connects:
			continue;
		found = true;
		var row := HBoxContainer.new();
		var is_from : bool = b.from_path_index == _path_index and b.from_point_index == _point_index;
		var desc : String = "Split → P%d; #%d" if is_from else "Join ← P%d #%d"
		var other_path : int = b.to_path_index if is_from else b.from_path_index;
		var other_point : int = b.to_point_index if is_from else b.from_point_index;
		var label := Label.new();
		label.text = desc % [other_path, other_point];
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
		row.add_child(label);
		var jump := Button.new();
		jump.text = "Jump";
		jump.tooltip_text = "Select the other endpoint";
		jump.pressed.connect(_on_jump.bind(other_path, other_point));
		row.add_child(jump);
		_branch_box.add_child(row);
	if not found:
		var none_label : Label = Label.new();
		none_label.text = "None";
		_branch_box.add_child(none_label);


func _refresh_defaults() -> void:
	if _spline == null:
		_defaults_label.text = "";
		return;
	_defaults_label.text = "Defaults: width %.1f, recipe %s, tunnel %.1f, flags %s" % [
		_spline.default_width,
		RECIPE_NAMES[int(_spline.default_recipe)],
		_spline.default_recipe_param,
		_format_flags(_spline.default_flags),
	]


func _format_flags(flags : int) -> String:
	var parts : Array[String] = [];
	for i in FLAG_NAMES.size():
		if flags & FLAG_BITS[i] != 0:
			parts.append(FLAG_NAMES[i]);
	return "none" if parts.is_empty() else ", ".join(parts);


# --- Edit commits (undoable) ----------------------------------------------------------------

func _commit_change(property : String, old_value : Variant, new_value : Variant) -> void:
	if _spline == null or _updating:
		return;
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo();
	var path_index : int = _path_index;
	var point_index : int = _point_index;
	ur.create_action("Set Track Point %s" % property.capitalize());
	ur.add_do_method(self, "_apply_point_value", path_index, point_index, property, new_value);
	ur.add_undo_method(self, "_apply_point_value", path_index, point_index, property, old_value);
	ur.commit_action();


func _apply_point_value(path_index : int, point_index : int, property : String, value : Variant) -> void:
	if _track == null or not _track.has_path(path_index):
		return;
	var spline : Spline = _track.get_spline_at(path_index);
	if spline == null or point_index < 0 or point_index >= spline.point_count:
		return;
	var pd : SplinePointData = spline.get_point_data(point_index);
	if pd == null:
		return;
	match property:
		"width":
			spline.set_point_width(point_index, value);
		"tilt":
			pd.tilt = deg_to_rad(value);
		"recipe":
			spline.set_point_recipe(point_index, value);
		"recipe_param":
			spline.set_point_recipe_param(point_index, value);
		"flags":
			spline.set_point_flags(point_index, value);
	pd.emit_changed();


# --- Path Controls handlers ------------------------------------------------------------------

func _on_path_name_submitted(text : String) -> void:
	_commit_path_name(text);


func _on_path_name_focus_exited() -> void:
	_commit_path_name(_path_name_edit.text);


## Undoable write of Spline.path_name for the current path. No-op when the value is
## unchanged (e.g. focus exits without typing, or Enter then blur double-fires).
func _commit_path_name(new_name : String) -> void:
	if _updating or _track == null or _spline == null:
		return;
	if new_name == _spline.path_name:
		return;
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo();
	var path_index : int = _path_index;
	ur.create_action("Set Path Name");
	ur.add_do_method(self, "_apply_path_name", path_index, new_name);
	ur.add_undo_method(self, "_apply_path_name", path_index, _spline.path_name);
	ur.commit_action();


func _apply_path_name(path_index : int, value : String) -> void:
	if _track == null or not _track.has_path(path_index):
		return;
	var spline : Spline = _track.get_spline_at(path_index);
	if spline == null:
		return;
	spline.path_name = value;
	spline.emit_changed();


func _on_delete_connections_pressed() -> void:
	if _track == null or _path_index < 0:
		return;
	_track.delete_path_connections(_path_index);


func _on_delete_points_pressed() -> void:
	if _track == null or _path_index < 0:
		return;
	_track.delete_path_points(_path_index);
	_clear_selection_if_invalid();


func _on_delete_path_pressed() -> void:
	if _track == null or _path_index < 0:
		return;
	var deleted_path : int = _path_index;
	_track.delete_path(deleted_path);
	# An alternate path removal can shift later paths onto the selected index, so the
	# selection must be cleared outright; the main-path fallback only clears when the
	# selected point actually ceased to exist.
	if deleted_path > 0:
		point_navigated.emit(-1, -1);
	else:
		_clear_selection_if_invalid();


## Emit point_navigated(-1, -1) to clear the gizmo selection when the current path/point no
## longer exists after a delete.
func _clear_selection_if_invalid() -> void:
	if _track == null or _path_index < 0:
		return;
	var spline : Spline = _track.get_spline_at(_path_index);
	if spline == null or _point_index < 0 or _point_index >= spline.point_count:
		point_navigated.emit(-1, -1);


# --- Control handlers -----------------------------------------------------------------------

func _on_width_changed(value : float) -> void:
	if _updating:
		return;
	_commit_change("width", _spline.get_point_width(_point_index), value);


func _on_tilt_changed(value : float) -> void:
	if _updating:
		return;
	var pd : SplinePointData = _spline.get_point_data(_point_index);
	if pd == null:
		return;
	_commit_change("tilt", rad_to_deg(pd.tilt), value);


func _on_recipe_changed(index : int) -> void:
	if _updating:
		return;
	_commit_change("recipe", int(_spline.get_point_recipe(_point_index)), index);
	_update_tunnel_enabled();


func _on_tunnel_changed(value : float) -> void:
	if _updating:
		return;
	_commit_change("recipe_param", _spline.get_point_recipe_param(_point_index), value);


func _on_flag_toggled(pressed : bool, bit_index : int) -> void:
	if _updating:
		return;
	var flags : int = _spline.get_point_flags(_point_index);
	var new_flags : int = flags | FLAG_BITS[bit_index] if pressed else flags & ~FLAG_BITS[bit_index];
	_commit_change("flags", flags, new_flags);


func _on_path_selected(index : int) -> void:
	if _updating or _track == null:
		return;
	var new_path : int = index;
	if new_path == _path_index:
		return;
	var count : int = _track.get_spline_at(new_path).point_count if _track.get_spline_at(new_path) else 0;
	var new_point : int = clampi(_point_index, 0, maxi(0, count - 1));
	point_navigated.emit(new_path, new_point);


func _on_nav(delta : int) -> void:
	if _spline == null:
		return;
	point_navigated.emit(_path_index, clampi(_point_index + delta, 0, _spline.point_count - 1));


## Persist the track's current state (main curve, alternate paths, branches, bake interval)
## into its TrackSplineData asset — the dock twin of the TrackSpline "Save Track to Data"
## export button.
func _on_save_pressed() -> void:
	if _track:
		_track._save_to_data();


func _on_jump(path_index : int, point_index : int) -> void:
	point_navigated.emit(path_index, point_index);
