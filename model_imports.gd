#@tool
#extends EditorScenePostImport

#func _post_import(scene: Node) -> Object:
	#_modify_node(scene);
	#return scene;

#func _modify_node(node: Node) -> void:
	#if node is MeshInstance3D:
		#node.
