@tool
extends EditorScenePostImport

func _post_import(scene : Node) -> Object:
	var meshes = _find_all_meshes(scene)
	if meshes.is_empty(): 
		return scene
	
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
		collision_shape.shape = mesh.mesh.create_convex_shape()
		
		# Separate the hierarchy: Meshes go in folder, colliders stay on root
		meshes_folder.add_child(mesh)
		new_root.add_child(collision_shape)
		
		mesh.transform = original_global_transform
		collision_shape.transform = original_global_transform
		
		mesh.owner = new_root
		collision_shape.owner = new_root
		
	scene.queue_free()
	return new_root

func _find_all_meshes(node : Node) -> Array:
	var meshes = []
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		meshes.append_array(_find_all_meshes(child))
	return meshes
