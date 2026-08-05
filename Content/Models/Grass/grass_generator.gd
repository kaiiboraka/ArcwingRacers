@tool
class_name Grass_Generator extends Node3D

## Grass field that bakes ONE grass chunk (a chunk_size × chunk_size patch) and tiles it
## across a grid of chunk copies, so the renderer frustum-culls each chunk independently.
##
## Workflow:
## 1. Press "Rebuild Grass" — builds a chunk_size × chunk_size PlaneMesh (with M_invisible so
##    it never renders), scatters blades over it (GrassFactory), wraps them in one MultiMesh,
##    and saves the chunk as a PackedScene at chunk_export_path. The chunk is remembered as
##    chunk_scene.
## 2. Press "Build Grid" (or just run) — instantiates chunk_scene grid_dimensions.x ×
##    grid_dimensions.y times as children, centered on this node and growing outward.
## 3. Press "Save Grass to File" to export the whole tiled field as one static PackedScene at
##    export_path, then instance that in the level instead of this generator.
##
## Generation is fully manual — no auto-regeneration in the editor.

const MeshFactory = preload("./mesh_factory.gd")
const GrassFactory = preload("./grass_factory.gd")

@export var blade_width : Vector2 = Vector2(0.01, 0.02)
@export var blade_height : Vector2 = Vector2(0.04, 0.08)
@export var sway_yaw : Vector2 = Vector2(0.0, 10.0)
@export var sway_pitch : Vector2 = Vector2(0.04, 0.08)
## Blades per square meter. On a 40 m chunk a density of 1.0 gives ~1600 blades per chunk.
@export var density : float = 1.0:
	set(new_value):
		density = maxf(new_value, 0.0)

## Side length in meters of one chunk patch (also the grid cell size). Each chunk is a
## PlaneMesh of this size with its own MultiMesh, so this controls culling granularity:
## smaller = tighter culling + more draw calls, larger = fewer draw calls + more waste.
@export var chunk_size : float = 40.0

## How many chunks wide (x) and deep (z). e.g. 4 × 8 at chunk_size 40 = 160 × 320 m field.
## The grid is centered on this node's position and grows outward evenly on both sides.
@export var grid_dimensions : Vector2i = Vector2i(4, 8)

## Rotate each tiled chunk by a random 90° multiple so the repeated patch doesn't read as one
## obvious copy. Safe to mix freely: a 90° rotation keeps the square footprint flush.
@export var randomize_chunks : bool = true

## Material applied to every blade MultiMesh (wind shader / tint).
@export var grass_material : Material = preload("res://Content/Materials/M_grass.tres"):
	set(new_value):
		grass_material = new_value
		_reapply_material()

## Material for the invisible ground plane baked into each chunk (never renders).
@export var invisible_material : Material = preload("res://Content/Materials/M_invisible.tres")

## The baked single-chunk scene used by "Build Grid". Populated automatically after baking.
@export var chunk_scene : PackedScene = null

## Where "Rebuild Grass" writes the single-chunk PackedScene.
@export var chunk_export_path : String = "res://Content/Models/Grass/grass_chunk.tscn"

## Where "Save Grass to File" writes the whole tiled field as a static PackedScene.
@export var export_path : String = "res://Content/Models/Grass/grass_field.tscn"

@export_tool_button("Rebuild Grass Patch Scene", "BuildCSharp") var rebuild_button : Callable = rebuild
@export_tool_button("Build GrassGrid", "Play") var build_button : Callable = build_grid
@export_tool_button("Clear GrassGrid", "Eraser") var clear_button : Callable = clear_grid
@export_tool_button("Save GrassGrid to File", "Save") var save_button : Callable = save_to_file

func _ready() -> void:
	_reapply_material()
	if not Engine.is_editor_hint():
		build_grid()

func _reapply_material() -> void:
	#material_override = grass_material
	for child in get_children():
		if child is MultiMeshInstance3D:
			child.material_override = grass_material
		elif child is Node3D:
			var blades : MultiMeshInstance3D = child.get_node_or_null("Blades") as MultiMeshInstance3D
			if blades:
				blades.material_override = grass_material

func _clear_chunks() -> void:
	for child in get_children():
		if child.name.begins_with("GrassChunk"):
			child.free()

## Bake ONE chunk: build a chunk_size PlaneMesh (M_invisible), scatter blades on it, wrap them
## in one MultiMesh, save as a PackedScene, then re-tile the grid with the fresh chunk.
func rebuild() -> void:
	_clear_chunks()
	#multimesh = null
	#material_override = grass_material
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
	var blades : MultiMeshInstance3D = MultiMeshInstance3D.new()
	blades.name = "Blades"
	blades.multimesh = mm
	blades.material_override = grass_material
	chunk_root.add_child(blades)
	var packed : PackedScene = PackedScene.new()
	var err : Error = packed.pack(chunk_root)
	if err == OK:
		err = ResourceSaver.save(packed, chunk_export_path)
	if err != OK:
		push_error("Failed to save grass chunk to %s (error %s)." % [chunk_export_path, err])
		return
	chunk_scene = load(chunk_export_path)
	print("Saved grass chunk (%d blades) to %s" % [spawns.size(), chunk_export_path])
	build_grid()

## Tile chunk_scene across grid_dimensions, centered on this node and growing outward.
func build_grid() -> void:
	_clear_chunks()
	if not chunk_scene:
		push_warning("No chunk_scene assigned — press 'Rebuild Grass' first, or assign one.")
		return
	var half : Vector2 = Vector2(
		(float(grid_dimensions.x) - 1.0) * 0.5,
		(float(grid_dimensions.y) - 1.0) * 0.5
	)
	for iz in grid_dimensions.y:
		for ix in grid_dimensions.x:
			var inst : Node3D = chunk_scene.instantiate() as Node3D
			inst.name = "GrassChunk_%d_%d" % [ix, iz]
			add_child(inst)
			inst.owner = owner
			inst.position = Vector3(
				(float(ix) - half.x) * chunk_size,
				0.0,
				(float(iz) - half.y) * chunk_size
			)
			if randomize_chunks:
				inst.rotation_degrees.y = float(randi_range(0, 3) * 90)
			var blades : MultiMeshInstance3D = inst.get_node_or_null("Blades") as MultiMeshInstance3D
			if blades:
				blades.material_override = grass_material

func clear_grid() -> void:
	_clear_chunks()

## Save the currently tiled chunks as a static PackedScene at export_path. Instantiate that
## scene in the level instead of the generator — no script, no generation, and each chunk node
## culls independently just like in the editor.
func save_to_file() -> void:
	var chunks : Array = []
	for child in get_children():
		if child.name.begins_with("GrassChunk"):
			chunks.append(child)
	if chunks.is_empty():
		push_warning("No baked grass chunks to save — press 'Rebuild Grass' first.")
		return
	var root : Node3D = Node3D.new()
	root.name = "GrassField"
	for chunk in chunks:
		root.add_child(chunk.duplicate())
	var scene : PackedScene = PackedScene.new()
	var err : Error = scene.pack(root)
	if err == OK:
		err = ResourceSaver.save(scene, export_path)
	if err != OK:
		push_error("Failed to save grass field to %s (error %s)." % [export_path, err])
	else:
		print("Saved grass field (%d chunks) to %s" % [chunks.size(), export_path])
