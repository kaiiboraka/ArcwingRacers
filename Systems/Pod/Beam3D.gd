extends Node3D

@export var point_a: Node3D
@export var point_b: Node3D
@export var width: float = 0.25

func _physics_process(_delta):
	if not point_a or not point_b:
		return
	var a: Vector3 = point_a.global_position
	var b: Vector3 = point_b.global_position
	var span: Vector3 = b - a
	var length: float = span.length()
	if length <= 0.0001:
		return
	global_position = (a + b) * 0.5
	var up := Vector3.UP
	if abs(span.y) / length > 0.99:
		up = Vector3.RIGHT
	look_at(b, up)
	scale = Vector3(width, 1.0, length)
