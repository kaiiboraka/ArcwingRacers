@tool
class_name Grass_Grid extends Node3D

## Level-building tool for BotW-style grass. Takes a baked grass chunk scene (made by
## Grass_Generator, e.g. grass_chunk_40.tscn) and tiles it across a grid you can script and
## tweak entirely from the editor.
##
## The chunk size is read straight off the chunk scene's FILENAME (grass_chunk_40.tscn → 40 m).
## grid_width and grid_height are counts of chunks; changing them (or the chunk itself) rebuilds
## the grid instantly in the editor — no re-baking the chunk, no relayout.
##
## Assign chunk_scene in the inspector and the grid spawns immediately as child instances.

const _SIZE_PATTERN := "^(.*[\\/])?grass_chunk_([0-9]+(?:_[0-9]+)?)\\.tscn$"

## The baked single-chunk scene to tile (e.g. res://Content/Models/Grass/grass_chunk_40.tscn).
## Its filename supplies the spacing: grass_chunk_40 == 40 m per cell.
@export var chunk_scene : PackedScene = null:
	set(value):
		chunk_scene = value
		_rebuild_dirty()

## How many chunk-copies across the X axis.
@export var grid_width : int = 4:
	set(value):
		grid_width = maxi(value, 1)
		_rebuild_dirty()

## How many chunk-copies across the Z axis.
@export var grid_height : int = 4:
	set(value):
		grid_height = maxi(value, 1)
		_rebuild_dirty()

## Rotate each tiled chunk by a random 90° multiple so the repeated patch doesn't read as one
## obvious copy. Safe to mix freely: a 90° rotation keeps the square footprint flush.
@export var randomize_chunks : bool = true:
	set(value):
		randomize_chunks = value
		_rebuild_dirty()

## Side of one chunk in meters, parsed from chunk_scene's filename. Used as grid spacing; you
## normally never touch this. Falls back to chunk_size_fallback when the filename can't be read.
@export var chunk_size : float = 0.0:
	set(value):
		chunk_size = value
		_rebuild_dirty()

## Used when the chunk filename has no parseable size (e.g. a hand-made chunk scene).
@export var chunk_size_fallback : float = 40.0

func _ready() -> void:
	_rebuild()

## Setters can fire while the node is still being deserialized (not yet in the tree), where
## free()/add_child() would error. Those early writes are covered by the _ready() rebuild.
func _rebuild_dirty() -> void:
	if is_inside_tree():
		_rebuild()

## Remove any previously spawned grid children, then re-tile from chunk_scene.
func _rebuild() -> void:
	for child in get_children():
		child.free()
	if not chunk_scene:
		return
	var size : float = _resolved_chunk_size()
	if size <= 0.0:
		return
	var half : Vector3 = Vector3(
		(float(grid_width) - 1.0) * 0.5 * size,
		0.0,
		(float(grid_height) - 1.0) * 0.5 * size
	)
	for iz in grid_height:
		for ix in grid_width:
			var inst : Node3D = chunk_scene.instantiate() as Node3D
			inst.name = "GrassChunk_%d_%d" % [ix, iz]
			add_child(inst)
			if owner:
				inst.owner = owner
			inst.position = Vector3(ix * size, 0.0, iz * size) - half
			if randomize_chunks:
				inst.rotation_degrees.y = float(randi_range(0, 3) * 90)

## Prefer the size read from the filename; fall back to chunk_size_fallback.
func _resolved_chunk_size() -> float:
	if chunk_size > 0.0:
		return chunk_size
	if not chunk_scene:
		return chunk_size_fallback
	var re := RegEx.new()
	re.compile(_SIZE_PATTERN)
	var match : RegExMatch = re.search(chunk_scene.resource_path)
	if match:
		return float(match.get_string(2).replace("_", "."))
	return chunk_size_fallback