## v3
@tool
extends EditorScenePostImport

func _post_import(scene: Node) -> Object:
	var meshes = _find_all_meshes(scene)
	if meshes.is_empty(): 
		return scene
	
	# Create ONE unified StaticBody3D root for the entire model
	var new_root = StaticBody3D.new()
	new_root.name = scene.name
	
	# Create the dedicated single folder node for the visual meshes
	var meshes_folder = Node3D.new()
	meshes_folder.name = "Meshes"
	new_root.add_child(meshes_folder)
	meshes_folder.owner = new_root
	
	for mesh in meshes:
		var original_global_transform = mesh.global_transform
		
		mesh.owner = null
		mesh.get_parent().remove_child(mesh)
		
		var collision_shape = CollisionShape3D.new()
		collision_shape.name = mesh.name + "_Collider"
		collision_shape.shape = mesh.mesh.create_trimesh_shape()
		
		# Separate the hierarchy: Meshes go in folder, colliders stay on root
		meshes_folder.add_child(mesh)
		new_root.add_child(collision_shape)
		
		mesh.transform = original_global_transform
		collision_shape.transform = original_global_transform
		
		mesh.owner = new_root
		collision_shape.owner = new_root
		
	scene.queue_free()
	return new_root

func _find_all_meshes(node: Node) -> Array:
	var meshes = []
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		meshes.append_array(_find_all_meshes(child))
	return meshes



## V2

#@tool
#extends EditorScenePostImport
#
#func _post_import(scene: Node) -> Object:
	## 1. We will find every MeshInstance3D in your imported file
	#var meshes = _find_all_meshes(scene)
	#
	#for mesh in meshes:
		## Skip if it's already a child of a physics body
		#if mesh.get_parent() is StaticBody3D:
			#continue
			#
		## 2. Create the clean StaticBody3D that should be the parent
		#var static_body = StaticBody3D.new()
		#static_body.name = mesh.name + "_PhysicsRoot"
		#
		## 3. Create the clean Collision Shape
		#var collision_shape = CollisionShape3D.new()
		#collision_shape.name = mesh.name + "_Collider"
		#
		## Choose your shape type:
		## For racing walls/tracks, we use Trimesh (ConcavePolygonShape3D)
		## For props, change this to mesh.mesh.create_convex_shape()
		#collision_shape.shape = mesh.mesh.create_trimesh_shape()
		#
		## 4. Get the mesh's original parent and its transform
		#var original_parent = mesh.get_parent()
		#static_body.transform = mesh.transform
		#
		## 5. Restructure the nodes so the StaticBody is the parent root
		#original_parent.add_child(static_body)
		#static_body.owner = scene
		#
		## Move the mesh to be a child of the new physics root
		#mesh.reparent(static_body)
		#mesh.transform = Transform3D.IDENTITY # Reset local transform since parent has it
		#mesh.owner = scene
		#
		## Add the collider as a sibling right next to the mesh
		#static_body.add_child(collision_shape)
		#collision_shape.owner = scene
		#
	#return scene
#
#func _find_all_meshes(node: Node) -> Array:
	#var meshes = []
	#if node is MeshInstance3D:
		#meshes.append(node)
	#for child in node.get_children():
		#meshes.append_array(_find_all_meshes(child))
	#return meshes


## V1

#@tool
#extends EditorScenePostImport
#
#func _post_import(scene: Node) -> Node:
	#var meshes := _collect_mesh_instances(scene)
	#if meshes.is_empty():
		#return scene
#
	#var name = scene.name.trim_prefix("SM_")
	#var glb_path = scene.scene_file_path
	#var out = glb_path.get_base_dir().replace("Models", "Scenes").path_join(name + ".tscn")
#
	#var shape_data: Array[Dictionary] = []
	#var sub_idx := 1
	#for mi in meshes:
		#if not mi.mesh:
			#continue
		#var shape = mi.mesh.create_trimesh_shape()
		#if not shape:
			#continue
		#var col_name = mi.name.replace(":", "_").replace("/", "_")
		#if col_name.is_empty():
			#col_name = "Collision_" + str(sub_idx)
		#var shape_text = _resource_to_text(shape, "shape_" + str(sub_idx))
		#shape_data.append({text = shape_text, name = col_name, idx = sub_idx})
		#sub_idx += 1
#
	#if shape_data.is_empty():
		#return scene
#
	#var glb_id = "1_" + glb_path.md5_text().left(5)
#
	#var lines := PackedStringArray()
	#lines.append("[gd_scene format=3]")
	#lines.append("")
	#lines.append("[ext_resource type=\"PackedScene\" path=\"" + glb_path + "\" id=\"" + glb_id + "\"]")
	#lines.append("")
#
	#for s in shape_data:
		#for line in s.text.split("\n"):
			#lines.append(line)
#
	#lines.append("")
	#lines.append("[node name=\"" + name + "\" type=\"StaticBody3D\"]")
	#lines.append("")
	#for s in shape_data:
		#lines.append("[node name=\"" + s.name + "\" type=\"CollisionShape3D\" parent=\".\"]")
		#lines.append("shape = SubResource(\"shape_" + str(s.idx) + "\")")
		#lines.append("")
#
	#lines.append("[node name=\"Mesh\" parent=\".\" instance=ExtResource(\"" + glb_id + "\")]")
#
	#var text_content = "\n".join(lines)
	## Defer write to avoid recursive reimport during import
	#if Engine.get_main_loop() is SceneTree:
		#call_deferred("_write_file", out, text_content)
#
		##Engine.get_main_loop().call_deferred(_write_file.bind(out, text_content))
#
	#return scene
#
#
#func _write_file(path: String, content: String):
	#var dir = path.get_base_dir()
	#if not DirAccess.dir_exists_absolute(dir):
		#DirAccess.make_dir_recursive_absolute(dir)
	#var f = FileAccess.open(path, FileAccess.WRITE)
	#if f:
		#f.store_string(content)
		#f.close()
#
#
#func _resource_to_text(res: Resource, label: String) -> String:
	#var tmp = "res://.godot/temp_" + label + ".tres"
	#var d = tmp.get_base_dir()
	#if not DirAccess.dir_exists_absolute(d):
		#DirAccess.make_dir_recursive_absolute(d)
	#ResourceSaver.save(res, tmp)
	#var text = FileAccess.get_file_as_string(tmp)
	#DirAccess.remove_absolute(tmp)
#
	#var type_line = ""
	#var data_lines := PackedStringArray()
	#for line in text.split("\n"):
		#if line.begins_with("[resource]"):
			#continue
		#if line.begins_with("[gd_resource"):
			#type_line = line
		#else:
			#data_lines.append(line)
#
	#var type_match = ""
	#var parts = type_line.split(" ")
	#for part in parts:
		#if part.begins_with("type="):
			#type_match = part.trim_prefix("type=").trim_prefix("\"").trim_suffix("\"")
			#break
#
	#var result = "[sub_resource type=\"" + type_match + "\" id=\"" + label + "\"]\n"
	#for line in data_lines:
		#if not line.is_empty():
			#result += line + "\n"
	#return result.strip_edges()
#
#
#func _collect_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	#var result: Array[MeshInstance3D] = []
	#var stack = [node]
	#while stack:
		#var current = stack.pop_back()
		#if current is MeshInstance3D:
			#result.append(current)
		#for child in current.get_children():
			#stack.append(child)
	#return result
