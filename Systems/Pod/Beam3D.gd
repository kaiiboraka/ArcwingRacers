extends Node3D

@export var point_a: Node3D
@export var point_b: Node3D

@onready var beam_mesh: MeshInstance3D = $BeamMesh

func _ready() -> void:
	beam_mesh.set_identity();

func _physics_process(_delta):
	if not point_a or not point_b:
		return
	var a: Vector3 = point_a.global_position
	var b: Vector3 = point_b.global_position
	var mid: Vector3 = (a + b) * 0.5
	var span: Vector3 = b - a
	var length: float = span.length()
	if length <= 0.0001:
		return
	global_position = mid
	var beam_dir: Vector3 = span / length
	var facing: Vector3 = _facing(beam_dir, mid)
	var x: Vector3 = beam_dir
	var z: Vector3 = facing
	var y: Vector3 = z.cross(x)
	global_basis = Basis(x, y, z)
	var quad_size: Vector2 = Vector2.ONE
	if beam_mesh and beam_mesh.mesh is QuadMesh:
		quad_size = (beam_mesh.mesh as QuadMesh).size
	scale = Vector3(length / maxf(quad_size.x, 0.001), 1.0, 1.0)

func _facing(beam_dir: Vector3, mid: Vector3) -> Vector3:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam:
		var to_cam: Vector3 = (cam.global_position - mid).normalized()
		var n: Vector3 = to_cam - beam_dir * to_cam.dot(beam_dir)
		if n.length() > 0.001:
			return n.normalized()
	var up: Vector3 = Vector3.UP if abs(beam_dir.y) < 0.99 else Vector3.RIGHT
	return up.cross(beam_dir).normalized()
