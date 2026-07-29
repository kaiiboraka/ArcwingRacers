@tool
extends Node

## Path to a .glb file or a folder of .glb files
@export var source: String = ""
## If empty, auto-derived per file: Models→Scenes in path
@export var output_folder: String = ""

@export var skip_existing: bool = true

@export_tool_button("Generate") var _generate_button: Callable = _generate

var _generated: Array[String] = []

func _generate():
	if source.is_empty():
		push_error("Select a source .glb file or folder")
		return

	_generated.clear()
	var new_count := 0
	var skip_count := 0

	var files: Array[String] = []
	if source.ends_with(".glb") or source.ends_with(".gltf"):
		files.append(source)
	else:
		var dir = DirAccess.open(source)
		if not dir:
			push_error("Cannot open: ", source)
			return
		dir.list_dir_begin()
		var file = dir.get_next()
		while file:
			if file.ends_with(".glb") or file.ends_with(".gltf"):
				files.append(source.path_join(file))
			file = dir.get_next()

	for glb_path in files:
		var out = _output_path_for(glb_path)
		if skip_existing and FileAccess.file_exists(out):
			print("  skip (exists): ", out)
			_generated.append(out)
			skip_count += 1
			continue
		if _process_one(glb_path, out):
			_generated.append(out)
			new_count += 1

	for child in get_children():
		child.free()

	var root = get_tree().edited_scene_root
	var offset := 0.0
	for file in _generated:
		var scene = load(file) as PackedScene
		if scene:
			var inst = scene.instantiate()
			add_child(inst)
			if root:
				inst.owner = root

			var aabb = _calc_aabb(inst)
			inst.position.x = offset - aabb.position.x
			offset += aabb.size.x + 1.0

	print("Done: ", _generated.size(), " loaded (", new_count, " new, ", skip_count, " skipped)")

func _output_path_for(glb_path: String) -> String:
	var glb = load(glb_path) as PackedScene
	if not glb:
		return ""
	var basename = glb.resource_path.get_file().get_basename().trim_prefix("SM_").to_lower()
	if output_folder.is_empty():
		var dir = glb.resource_path.get_base_dir().replace("Models", "Scenes")
		return dir.path_join(basename + ".tscn")
	return output_folder.path_join(basename + ".tscn")

func _process_one(glb_path: String, out: String) -> bool:
	var glb = load(glb_path) as PackedScene
	if not glb:
		push_error("Failed to load: ", glb_path)
		return false

	var instance = glb.instantiate()
	if not instance:
		push_error("Failed to instantiate: ", glb_path)
		return false

	var out_dir = out.get_base_dir()
	if not DirAccess.dir_exists_absolute(out_dir):
		DirAccess.make_dir_recursive_absolute(out_dir)

	var glb_basename = glb.resource_path.get_file().get_basename().trim_prefix("SM_")

	var static_body = StaticBody3D.new()
	static_body.name = glb_basename

	var meshes_container = Node3D.new()
	meshes_container.name = "Meshes"
	static_body.add_child(meshes_container)
	meshes_container.owner = static_body

	var meshes = _collect_mesh_instances(instance)
	for m in meshes:
		var parent = m.get_parent()
		if not parent:
			continue

		m.owner = null
		parent.remove_child(m)
		meshes_container.add_child(m)
		m.transform = Transform3D.IDENTITY
		m.owner = static_body

		if not m.mesh:
			continue

		var shape = m.mesh.create_trimesh_shape()
		if shape:
			var col = CollisionShape3D.new()
			col.shape = shape
			col.name = m.name + "_col"
			static_body.add_child(col)
			col.owner = static_body

	var packed = PackedScene.new()
	if packed.pack(static_body) != OK:
		push_error("Failed to pack: ", out)
		return false

	if ResourceSaver.save(packed, out) != OK:
		push_error("Failed to save: ", out)
		return false

	print("  ", out)
	return true

func _calc_aabb(node: Node) -> AABB:
	var bounds: AABB
	var first := true
	var stack = [node]
	while stack:
		var current = stack.pop_back()
		if current is MeshInstance3D and current.mesh:
			var mesh_aabb = current.mesh.get_aabb()
			if first:
				bounds = mesh_aabb
				first = false
			else:
				bounds = bounds.merge(mesh_aabb)
		for child in current.get_children():
			stack.append(child)
	return bounds

func _collect_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	var stack = [node]
	while stack:
		var current = stack.pop_back()
		if current is MeshInstance3D:
			result.append(current)
		for child in current.get_children():
			stack.append(child)
	return result
