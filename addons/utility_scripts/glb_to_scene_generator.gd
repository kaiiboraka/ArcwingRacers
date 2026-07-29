@tool
extends Node

@export_category("Source")
@export var source: String = ""

@export_category("Array Mesh")
@export var generate_array_mesh: bool = true
@export var skip_existing_array_mesh: bool = false
@export_dir var mesh_output_folder: String = "res://Content/Models/Doodads"

@export_category("Terrain Scene")
@export var generate_terrain_scenes: bool = true
@export var skip_existing_terrain: bool = true
@export_dir var terrain_output_folder: String = "res://Content/Models/Doodads"

@export_category("StaticBody Scene")
@export var generate_static_body: bool = true
@export var skip_existing_static_body: bool = true
@export_dir var static_body_folder: String = "res://Content/Scenes/Doodads"

@export_category("Materials")
@export var save_materials: bool = true
@export_dir var materials_folder: String = "res://Content/Materials"

@export_tool_button("Generate") var _generate_button: Callable = _generate

var _generated: Array[String] = []
var _mat_new: int = 0
var _mat_skip: int = 0
var _mat_attempts: int = 0
var _mat_existed: Dictionary = {}

func _generate():
	if source.is_empty():
		push_error("Select a source .glb file or folder")
		return

	if not generate_static_body and not generate_array_mesh and not generate_terrain_scenes and not save_materials:
		Log.pr("Nothing to generate — enable at least one output type")
		return

	_generated.clear()
	_mat_new = 0; _mat_skip = 0; _mat_attempts = 0; _mat_existed.clear()
	var sb_new := 0; var sb_skip := 0
	var mesh_new := 0; var mesh_skip := 0
	var terrain_new := 0; var terrain_skip := 0

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
		var mesh_out := ""
		var tscn_out := ""
		if generate_array_mesh or generate_static_body:
			mesh_out = _mesh_output_path_for(glb_path)
		if generate_terrain_scenes or generate_static_body:
			tscn_out = _terrain_output_path_for(glb_path)

		if generate_array_mesh:
			var mesh_done = _build_array_mesh(glb_path, mesh_out)
			if skip_existing_array_mesh and FileAccess.file_exists(mesh_out):
				mesh_skip += 1
			elif mesh_done:
				mesh_new += 1

		if generate_terrain_scenes:
			if skip_existing_terrain and FileAccess.file_exists(tscn_out):
				terrain_skip += 1
			else:
				_build_terrain_scene(glb_path, tscn_out, mesh_out)
				terrain_new += 1

		if generate_static_body:
			var out = _output_path_for(glb_path)
			if skip_existing_static_body and FileAccess.file_exists(out):
				_generated.append(out)
				sb_skip += 1
			elif _process_one(glb_path, out, mesh_out, tscn_out):
				_generated.append(out)
				sb_new += 1

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

	Log.pr("Done:")
	if generate_static_body:
		Log.pr("  StaticBody: " + str(sb_new + sb_skip) + " total, " + str(sb_new) + " new, " + str(sb_skip) + " skipped")
	if generate_array_mesh:
		Log.pr("  ArrayMesh: " + str(mesh_new + mesh_skip) + " total, " + str(mesh_new) + " new, " + str(mesh_skip) + " skipped")
		if save_materials:
			Log.pr("  Materials: " + str(_mat_attempts) + " attempts, " + str(_mat_new) + " new, " + str(_mat_skip) + " skipped, " + str(_mat_existed.size()) + " existed")
	if generate_terrain_scenes:
		Log.pr("  Terrain:   " + str(terrain_new + terrain_skip) + " total, " + str(terrain_new) + " new, " + str(terrain_skip) + " skipped")

func _output_path_for(glb_path: String) -> String:
	var glb = load(glb_path) as PackedScene
	if not glb:
		return ""
	var basename = glb.resource_path.get_file().get_basename().trim_prefix("SM_").to_lower()
	if static_body_folder.is_empty():
		var dir = glb.resource_path.get_base_dir().replace("Models", "Scenes")
		return dir.path_join(basename + ".tscn")
	return static_body_folder.path_join(basename + ".tscn")

func _process_one(glb_path: String, out: String, mesh_path: String, tscn_path: String) -> bool:
	var glb = load(glb_path) as PackedScene
	if not glb:
		push_error("Failed to load: ", glb_path)
		return false

	var out_dir = out.get_base_dir()
	if not DirAccess.dir_exists_absolute(out_dir):
		DirAccess.make_dir_recursive_absolute(out_dir)

	var glb_basename = glb.resource_path.get_file().get_basename().trim_prefix("SM_")

	var static_body = StaticBody3D.new()
	static_body.name = glb_basename

	if not mesh_path.is_empty():
		var mesh = load(mesh_path) as ArrayMesh
		if mesh:
			var shape = mesh.create_trimesh_shape()
			if shape:
				var col = CollisionShape3D.new()
				col.shape = shape
				col.name = "Collision"
				static_body.add_child(col)
				col.owner = static_body

	if not tscn_path.is_empty():
		var terrain = load(tscn_path) as PackedScene
		if terrain:
			var inst = terrain.instantiate()
			if inst:
				inst.name = "Mesh"
				static_body.add_child(inst)
				inst.owner = static_body

	var packed = PackedScene.new()
	if packed.pack(static_body) != OK:
		push_error("Failed to pack: ", out)
		return false

	if ResourceSaver.save(packed, out) != OK:
		push_error("Failed to save: ", out)
		return false

	Log.pr("  ", out)
	return true

func _mesh_output_path_for(glb_path: String) -> String:
	var glb = load(glb_path) as PackedScene
	if not glb:
		return ""
	var basename = glb.resource_path.get_file().get_basename()
	if mesh_output_folder.is_empty():
		return glb.resource_path.get_base_dir().path_join(basename + "_mesh.res")
	return mesh_output_folder.path_join(basename + "_mesh.res")

func _SaveOrReplace(mat: Material, mat_path: String, mat_key: String = "") -> Material:
	_mat_attempts += 1
	if not FileAccess.file_exists(mat_path):
		var old = mat.resource_path
		mat.resource_path = ""
		ResourceSaver.save(mat, mat_path)
		mat.resource_path = old
		_mat_new += 1
		var loaded = ResourceLoader.load(mat_path)
		if loaded:
			return loaded
		return mat
	_mat_skip += 1
	if not mat_key.is_empty():
		_mat_existed[mat_key] = true
	var loaded = ResourceLoader.load(mat_path)
	if loaded:
		return loaded
	return mat

func _build_array_mesh(glb_path: String, mesh_path: String) -> bool:
	var glb = load(glb_path) as PackedScene
	if not glb:
		return false
	var instance = glb.instantiate()
	if not instance:
		return false

	var glb_basename = glb.resource_path.get_file().get_basename().trim_prefix("SM_")
	var meshes = _collect_mesh_instances(instance)
	var saved_mats := {}

	for m in meshes:
		var src = m.mesh
		if not src:
			continue
		for i in src.get_surface_count():
			var mat = src.surface_get_material(i)
			if save_materials and mat:
				var mat_key = mat.resource_name
				if mat_key.is_empty():
					mat_key = glb_basename + "_surface_" + str(i)
				mat_key = mat_key.replace(" ", "_").to_lower()
				if not saved_mats.has(mat_key):
					var mat_path = materials_folder.path_join(mat_key + ".tres")
					if not DirAccess.dir_exists_absolute(materials_folder):
						DirAccess.make_dir_recursive_absolute(materials_folder)
					var loaded = _SaveOrReplace(mat, mat_path, mat_key)
					saved_mats[mat_key] = loaded

	var mesh_exists = skip_existing_array_mesh and FileAccess.file_exists(mesh_path)
	if not mesh_exists:
		var array_mesh = ArrayMesh.new()
		for m in meshes:
			var src = m.mesh
			if not src:
				continue
			for i in src.get_surface_count():
				var arrays = src.surface_get_arrays(i)
				var orig_mat = src.surface_get_material(i)
				var mat = orig_mat
				if save_materials and orig_mat:
					var key = orig_mat.resource_name
					if key.is_empty():
						key = glb_basename + "_surface_" + str(i)
					key = key.replace(" ", "_").to_lower()
					if saved_mats.has(key):
						mat = saved_mats[key]
				var name = src.surface_get_name(i)
				var prim = src.surface_get_primitive_type(i)

				array_mesh.add_surface_from_arrays(prim, arrays)
				var si = array_mesh.get_surface_count() - 1
				if mat:
					array_mesh.surface_set_material(si, mat)
				if not name.is_empty():
					array_mesh.surface_set_name(si, name)

		var out_dir = mesh_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(out_dir):
			DirAccess.make_dir_recursive_absolute(out_dir)
		if ResourceSaver.save(array_mesh, mesh_path) == OK:
			Log.pr("  mesh: ", mesh_path)
			return true
	return false

func _terrain_output_path_for(glb_path: String) -> String:
	var glb = load(glb_path) as PackedScene
	if not glb:
		return ""
	var basename = glb.resource_path.get_file().get_basename()
	if terrain_output_folder.is_empty():
		return glb.resource_path.get_base_dir().path_join(basename + "_mesh.tscn")
	return terrain_output_folder.path_join(basename + "_mesh.tscn")

func _build_terrain_scene(glb_path: String, tscn_path: String, mesh_path: String) -> void:
	var mesh = load(mesh_path) as ArrayMesh
	if not mesh:
		return
	var mi = MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	var packed = PackedScene.new()
	if packed.pack(mi) != OK:
		return
	var dir = tscn_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	if ResourceSaver.save(packed, tscn_path, ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS) == OK:
		Log.pr("  terrain: ", tscn_path)

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
