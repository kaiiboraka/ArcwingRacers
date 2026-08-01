@tool
class_name Skybox extends Node3D

@export var sky_offset_degrees: Vector3 = Vector3.ZERO:
	set(value):
		sky_offset_degrees = value
		_update_sky_rotation()

## Read-only mirror of the child SkyPreviewer's current panorama name, exposed on the root so
## the active sky can be read without opening the child scene.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
var current_sky_name: String:
	get:
		var previewer: SkyPreviewer = _find_sky_previewer()
		return previewer.current_sky_name if previewer else ""

## Step to the next panorama in the child SkyPreviewer's list. Editor-only forwarder.
@export_tool_button("Next Sky", "Forward")
var next_sky_button: Callable = _next_sky

## Step to the previous panorama in the child SkyPreviewer's list. Editor-only forwarder.
@export_tool_button("Previous Sky", "Back")
var prev_sky_button: Callable = _prev_sky

func _ready() -> void:
	if Engine.is_editor_hint():
		set_notify_transform(true)
	_update_sky_rotation()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_sky_rotation()

func _next_sky() -> void:
	var previewer: SkyPreviewer = _find_sky_previewer()
	if previewer:
		previewer.current_index += 1
		if Engine.is_editor_hint():
			notify_property_list_changed()

func _prev_sky() -> void:
	var previewer: SkyPreviewer = _find_sky_previewer()
	if previewer:
		previewer.current_index -= 1
		if Engine.is_editor_hint():
			notify_property_list_changed()

func _find_sky_previewer() -> SkyPreviewer:
	for child: Node in get_children():
		var previewer := child as SkyPreviewer
		if previewer:
			return previewer
	return null

func _update_sky_rotation() -> void:
	var env: WorldEnvironment = _find_world_environment()
	if not env or not env.environment:
		return
		
	var offset_rad: Vector3 = Vector3(
		deg_to_rad(sky_offset_degrees.x),
		deg_to_rad(sky_offset_degrees.y),
		deg_to_rad(sky_offset_degrees.z)
	)
	
	var sky_rotation: Vector3 = offset_rad + global_rotation
	
	if env.environment.sky_rotation.is_equal_approx(sky_rotation):
		return
		
	env.environment.sky_rotation = sky_rotation

func _find_world_environment() -> WorldEnvironment:
	for child: Node in get_children():
		var env := child as WorldEnvironment
		if env:
			return env
	return null
