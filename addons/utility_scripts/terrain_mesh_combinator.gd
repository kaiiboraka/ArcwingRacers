@tool
extends Node3D;

@export var source_glb : PackedScene:
	set(v):
		source_glb = v;
		if Engine.is_editor_hint():
			combine.call_deferred();

@export_tool_button("Combine") var combine : Callable = _combine

func _combine():
	if not source_glb:
		push_error("No source GLB set");
		return;

	var instance = source_glb.instantiate();
	if not instance:
		push_error("Failed to instantiate GLB");
		return;

	var meshes := _collect_mesh_instances(instance);
	if meshes.is_empty():
		push_error("No MeshInstance3D children found in GLB");
		instance.free();
		return;

	var combined = ArrayMesh.new();
	var total := 0;
	for mi in meshes:
		var src = mi.mesh;
		if not src:
			continue;
		for i in src.get_surface_count():
			var arrays = src.surface_get_arrays(i);
			var mat = src.surface_get_material(i);
			var name = src.surface_get_name(i);
			var prim = src.surface_get_primitive_type(i);
			combined.add_surface_from_arrays(prim, arrays);
			var si = combined.get_surface_count() - 1;
			if mat:
				combined.surface_set_material(si, mat);
			if not name.is_empty():
				combined.surface_set_name(si, name);
			total += 1;

	var mesh_node = get_node_or_null("Mesh") as MeshInstance3D;
	if not mesh_node:
		mesh_node = MeshInstance3D.new();
		mesh_node.name = "Mesh";
		add_child(mesh_node, true);
		if get_tree() and get_tree().edited_scene_root:
			mesh_node.owner = get_tree().edited_scene_root;

	mesh_node.mesh = combined;

	instance.free();

	Log.pr("Combined " + str(total) + " surfaces from " + str(meshes.size()) + " meshes");

func _collect_mesh_instances(node : Node) -> Array[MeshInstance3D]:
	var result : Array[MeshInstance3D] = [];
	var stack = [node];
	while stack:
		var current = stack.pop_back();
		if current is MeshInstance3D and current.mesh:
			result.append(current);
		for child in current.get_children():
			stack.append(child);
	return result;

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = [];
	if not source_glb:
		warnings.append("No source GLB set — set source_glb and click Combine");
	if not get_node_or_null("Mesh") is MeshInstance3D:
		warnings.append("Add a MeshInstance3D child named \"Mesh\" or one will be created");
	return warnings;
