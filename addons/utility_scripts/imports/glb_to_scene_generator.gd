@tool
extends Node

@export_category("Source")
@export var source: String = ""

@export_category("StaticBody Scene")
@export var generate: bool = true
@export var skip_existing: bool = true
@export_dir var output_folder: String = "res://Content/Scenes/Doodads"

@export_tool_button("Generate") var _generate_button: Callable = _generate

func _generate():
	if source.is_empty():
		push_error("Select a source .glb file or folder")
		return

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

	var new_count := 0
	var skip_count := 0

	for glb_path in files:
		var out = _output_path_for(glb_path)
		if out.is_empty():
			continue
		if skip_existing and FileAccess.file_exists(out):
			skip_count += 1
		elif _build_static_body(glb_path, out):
			new_count += 1

	for child in get_children():
		child.free()

	var root = get_tree().edited_scene_root
	var offset := 0.0
	for file in files:
		var out = _output_path_for(file)
		if out.is_empty():
			continue
		var scene = load(out) as PackedScene
		if not scene:
			continue
		var inst = scene.instantiate()
		add_child(inst)
		if root:
			inst.owner = root
		var aabb = _calc_aabb(inst)
		inst.position.x = offset - aabb.position.x
		offset += aabb.size.x + 1.0

	Log.pr("Done: " + str(new_count + skip_count) + " total, " + str(new_count) + " new, " + str(skip_count) + " skipped")

func _output_path_for(glb_path: String) -> String:
	var glb = load(glb_path) as PackedScene
	if not glb:
		return ""
	var basename = glb.resource_path.get_file().get_basename().trim_prefix("SM_").to_lower()
	if output_folder.is_empty():
		var dir = glb.resource_path.get_base_dir().replace("Models", "Scenes")
		return dir.path_join(basename + ".tscn")
	return output_folder.path_join(basename + ".tscn")

func _build_static_body(glb_path: String, out: String) -> bool:
	var glb = load(glb_path) as PackedScene
	if not glb:
		push_error("Failed to load: ", glb_path)
		return false

	var glb_basename = glb.resource_path.get_file().get_basename().trim_prefix("SM_")

	var instance = glb.instantiate()
	var meshes = _collect_mesh_instances(instance)

	var shapes: Array[Dictionary] = []
	var sub_idx := 1
	for mi in meshes:
		if not mi.mesh:
			continue
		var col_name = mi.name.replace(":", "_").replace("/", "_")
		if col_name.is_empty():
			col_name = "Collision_" + str(sub_idx)
		var shape = mi.mesh.create_trimesh_shape()
		if shape:
			shapes.append({name = col_name, shape = shape, idx = sub_idx})
		sub_idx += 1

	var lines := PackedStringArray()
	lines.append("[gd_scene format=3]")
	lines.append("")

	var glb_id = "1_" + glb_path.md5_text().left(5)
	lines.append("[ext_resource type=\"PackedScene\" path=\"" + glb_path + "\" id=\"" + glb_id + "\"]")
	lines.append("")

	for s in shapes:
		var shape_text = _resource_to_text(s.shape, "shape_" + str(s.idx))
		for line in shape_text.split("\n"):
			lines.append(line)

	lines.append("")
	lines.append("[node name=\"" + glb_basename + "\" type=\"StaticBody3D\"]")
	for s in shapes:
		var col_name = s.name
		lines.append("[node name=\"" + col_name + "\" type=\"CollisionShape3D\" parent=\".\"]")
		lines.append("shape = SubResource(\"shape_" + str(s.idx) + "\")")

	lines.append("[node name=\"Mesh\" parent=\".\" instance=ExtResource(\"" + glb_id + "\")]")
	lines.append("")

	var dir = out.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	var f = FileAccess.open(out, FileAccess.WRITE)
	if not f:
		push_error("Failed to write: ", out)
		return false
	for line in lines:
		f.store_line(line)
	f.close()

	instance.free()

	Log.pr("  ", out)
	return true

func _resource_to_text(res: Resource, label: String) -> String:
	var tmp = "res://.godot/temp_" + label + ".tres"
	var d = tmp.get_base_dir()
	if not DirAccess.dir_exists_absolute(d):
		DirAccess.make_dir_recursive_absolute(d)
	ResourceSaver.save(res, tmp)
	var f = FileAccess.open(tmp, FileAccess.READ)
	var text = f.get_as_text()
	f.close()
	DirAccess.remove_absolute(tmp)

	var type_line = ""
	var data_lines := PackedStringArray()
	for line in text.split("\n"):
		if line.begins_with("[resource]"):
			continue
		if line.begins_with("[gd_resource"):
			type_line = line
		else:
			data_lines.append(line)

	var result = ""
	var type_match = ""
	for line in type_line.split(" "):
		if line.begins_with("type="):
			type_match = line.trim_prefix("type=").trim_prefix("\"").trim_suffix("\"")
			break

	var sub = "[sub_resource type=\"" + type_match + "\" id=\"" + label + "\"]"
	result += sub + "\n"
	for line in data_lines:
		if not line.is_empty():
			result += line + "\n"

	return result.strip_edges()

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
