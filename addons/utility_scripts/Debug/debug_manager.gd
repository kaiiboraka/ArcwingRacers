extends CanvasLayer

var debug_logger : DebugLogger

@export var enabled : bool = true
@export var property_entry_scene : PackedScene

signal property_changed(which : String, value : String)
signal visuals_active_changed(visuals_active : bool)

var _game_size : Vector2 = Vector2.ZERO

var _hud_properties : Dictionary = {}
var _entries : Array = []
var _property_list : VBoxContainer
var _debug_inputs : Node

var _visuals_active : bool = true
var visuals_active : bool:
	get:
		return _visuals_active
	set(value):
		_visuals_active = value and enabled
		visible = _visuals_active
		visuals_active_changed.emit(_visuals_active)


func _enter_tree() -> void:
	add_to_group("Debug")


func _exit_tree() -> void:
	remove_from_group("Debug")


func _ready() -> void:
	var base_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var base_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	_game_size = Vector2(base_width, base_height);
	_debug_inputs = get_node("DebugInputs")
	debug_logger = DebugLogger.new(self)

	if property_entry_scene == null:
		property_entry_scene = load("res://addons/utility_scripts/Debug/PropertyEntry.tscn")

	call_deferred("_late_ready")


func _late_ready() -> void:
	await get_tree().physics_frame
	update_hud_values()
	_fill_debug_hud()
	visuals_active = _visuals_active


func trace(message : String) -> void:
	debug_logger.trace(message)


func debug(message : String) -> void:
	debug_logger.debug(message)


func warning(message : String) -> void:
	debug_logger.warning(message)


func error(message : String) -> void:
	debug_logger.error(message)


func info(message : String) -> void:
	debug_logger.info(message)


func _fill_debug_hud() -> void:
	_hud_properties = _hud_properties

	_property_list = %PropertyList
	for child in _property_list.get_children():
		child.queue_free()

	_entries = []
	for key in _hud_properties:
		var property_entry : Node = property_entry_scene.instantiate()
		_property_list.add_child(property_entry)
		property_entry.owner = self
		property_entry.property_text = key
		property_entry.value_text = _hud_properties[key]
		property_changed.connect(property_entry.update_value_text)
		_entries.append(property_entry)


func toggle_visibility() -> void:
	visuals_active = not visuals_active


func _process(_delta : float) -> void:
	update_hud_values()


func update_property(which : String, value : Variant) -> void:
	if not visuals_active:
		return
	var property_value := str(value)
	_hud_properties[which] = property_value
	property_changed.emit(which, property_value)


func update_hud_values() -> void:
	if not visuals_active:
		return
	_update_property_game_info()
	#_update_property_movement()


#func _update_property_movement() -> void:
	#update_property("Current Speed", get_tree().root.get_camera_3d().)


func _update_property_game_info() -> void:
	update_property("~~_ Game _~~", "~~~~~~~~~~~~")
	update_property("Game Time", int(Time.get_ticks_msec() / 1000))
	update_property("Time Scale Steps", _debug_inputs.get("time_scale_steps"))
	update_property("Time Scale", Engine.time_scale)
