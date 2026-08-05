@tool
class_name Grass_Generator extends Node3D

## Authoring tool for BotW-style grass CHUNKS. This script exists only to bake single grass
## chunks of a chosen size and save them out as named scenes (e.g. grass_chunk_40.tscn).
##
## Workflow:
## 1. Tweak the numbers (blade_width/height, sway, density, chunk_size), then press
##    "Rebuild Grass Chunk" — builds a chunk_size × chunk_size PlaneMesh (M_invisible),
##    scatters blades over it (GrassFactory), wraps them in one MultiMesh, and saves the chunk
##    as grass_chunk_<chunk_size>.tscn under export_dir.
## 2. That saved chunk is consumed by a Grass_Grid (grass_grid.gd) for level building — it
##    reads the chunk size straight off the filename and tiles the chunk across a live-editable
##    grid. This generator never builds grids itself.
##
## Generation is fully manual — no auto-regeneration in the editor.

const MeshFactory = preload("./mesh_factory.gd")
const GrassFactory = preload("./grass_factory.gd")

@export var sway_yaw : Vector2 = Vector2(0.0, 10.0)
@export var sway_pitch : Vector2 = Vector2(0.04, 0.08)
@export var blade_width : Vector2 = Vector2(0.1, 0.2)
@export var blade_height : Vector2 = Vector2(1, 3)
## Blades per square meter. On a 40 m chunk a density of 1.0 gives ~1600 blades per chunk.
@export var density : float = 2.0:
	set(new_value):
		density = maxf(new_value, 0.0)

## Side length in meters of the chunk to bake. Becomes part of the output filename
## (grass_chunk_40.tscn for a 40 m chunk), which is how Grass_Grid knows how to space it.
@export var chunk_size : float = 40.0:
	set(new_value):
		chunk_size = maxf(new_value, 0.0)

## Material applied to every blade MultiMesh (wind shader / tint).
@export var grass_material : Material = preload("res://Content/Materials/M_grass.tres")

## Material for the invisible ground plane baked into each chunk (never renders).
@export var invisible_material : Material = preload("res://Content/Materials/M_invisible.tres")

## Directory the chunk PackedScene is written to. Filename is always grass_chunk_<size>.tscn.
@export var export_dir : String = "res://Content/Models/Grass"

@export_tool_button("Rebuild Grass Chunk", "BuildCSharp") var rebuild_button : Callable = rebuild

func chunk_export_path() -> String:
	return "%s/grass_chunk_%s.tscn" % [export_dir.trim_suffix("/"), _size_label()]

## Whole numbers keep the clean "grass_chunk_40" form; decimals become "grass_chunk_12_5".
func _size_label() -> String:
	var whole : int = int(chunk_size)
	if is_equal_approx(chunk_size, float(whole)):
		return str(whole)
	return str(chunk_size).replace(".", "_")

## Bake ONE chunk: build a chunk_size PlaneMesh (M_invisible), scatter blades on it, wrap them
## in one MultiMesh, save as a PackedScene at chunk_export_path(). Every child that must
## survive the pack needs owner == chunk_root, or PackedScene.pack() silently drops it — that's
## why the saved scene looked empty.
func rebuild() -> void:
	var ground : PlaneMesh = PlaneMesh.new()
	ground.size = Vector2(chunk_size, chunk_size)
	ground.material = invisible_material
	var spawns : Array = GrassFactory.generate(
		ground,
		density,
		blade_width,
		blade_height,
		sway_pitch,
		sway_yaw
	)
	if spawns.is_empty():
		push_warning("No grass spawns for a %.1f m chunk at density %.2f." % [chunk_size, density])
		return
	var mm : MultiMesh = MultiMesh.new()
	mm.mesh = MeshFactory.simple_grass()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.use_colors = false
	mm.instance_count = spawns.size()
	for i in spawns.size():
		var spawn : Array = spawns[i]
		mm.set_instance_transform(i, spawn[0])
		mm.set_instance_custom_data(i, spawn[1])
	var chunk_root : Node3D = Node3D.new()
	chunk_root.name = "GrassChunk"
	var ground_node : MeshInstance3D = MeshInstance3D.new()
	ground_node.name = "Ground"
	ground_node.mesh = ground
	chunk_root.add_child(ground_node)
	ground_node.owner = chunk_root
	var blades : MultiMeshInstance3D = MultiMeshInstance3D.new()
	blades.name = "Blades"
	blades.multimesh = mm
	blades.material_override = grass_material
	chunk_root.add_child(blades)
	blades.owner = chunk_root
	var packed : PackedScene = PackedScene.new()
	var err : Error = packed.pack(chunk_root)
	var path : String = chunk_export_path()
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("Failed to save grass chunk to %s (error %s)." % [path, err])
		return
	print("Saved grass chunk (%d blades) to %s" % [spawns.size(), path])
