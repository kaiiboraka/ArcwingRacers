@tool
class_name Skybox extends Node3D

@export var sky_offset_degrees: Vector3 = Vector3.ZERO:
	set(value):
		sky_offset_degrees = value
		_update_sky_rotation()

func _ready() -> void:
	if Engine.is_editor_hint():
		set_notify_transform(true)
	_update_sky_rotation()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_sky_rotation()

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
