extends Object

## Builds the single grass-blade base mesh: a triangle from the bottom-left bottom
## corner (-0.5, 0) up to the tip (0, 1) back to the bottom-right corner (0.5, 0).
## TEX_UV2.y carries a 0→1 height factor (bottom→tip) that the grass shader uses for
## the top/bottom color gradient and the wind-magnitude ramp. The custom_aabb must be
## non-degenerate so Godot doesn't cull the tiny blade triangles when instanced.
static func simple_grass() -> ArrayMesh:
	var verts : PackedVector3Array = PackedVector3Array()
	var uvs : PackedVector2Array = PackedVector2Array()

	verts.push_back(Vector3(-0.5, 0.0, 0.0))
	uvs.push_back(Vector2(0.0, 0.0))

	verts.push_back(Vector3(0.5, 0.0, 0.0))
	uvs.push_back(Vector2(0.0, 0.0))

	verts.push_back(Vector3(0.0, 1.0, 0.0))
	uvs.push_back(Vector2(1.0, 1.0))

	var arrays : Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV2] = uvs

	var mesh : ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 1.0, 1.0))

	return mesh