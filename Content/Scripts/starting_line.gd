@tool
class_name StartingLine extends Node3D
## TODO: add some column offsets so next racers also move back a little bit as they move down the row.

const MAX_RACER_SLOTS : int = 16;
const GRID_COLS : int = 4;
const STARTING_POSITION : Texture = preload("uid://bahqbi23rxjjs");

@export_range(0, 100) var RACER_POSITION_WIDTH : float = 15.0:
	set(v):
		RACER_POSITION_WIDTH = v;
		_rebuild_grid.call_deferred();

@export_range(0, 100) var RACER_ROWS_SPACING : float = 25.0:
	set(v):
		RACER_ROWS_SPACING = v;
		_rebuild_grid.call_deferred();
		
@export_range(0, 10) var RACER_POSITION_MARKER_HEIGHT : float = .2:
	set(v):
		RACER_POSITION_MARKER_HEIGHT = v;
		_rebuild_grid.call_deferred();

@export_range(0, 16) var racer_count : int = 8:
	set(v):
		racer_count = v;
		_rebuild_grid.call_deferred();

@export var racers_to_load : Array[Node3D] = [];

var start_positions : Array[Marker3D] = [];

func _ready():
	if Engine.is_editor_hint():
		_rebuild_grid.call_deferred();

func _rebuild_grid():
	if not Engine.is_editor_hint():
		return;

	var tree : SceneTree = get_tree();
	if not tree:
		return;

	var root : Node = tree.edited_scene_root;
	if not root:
		return;

	var grid_entries : Dictionary = {}
	for child in get_children():
		var idx : int = _parse_index(child.name);
		if child is Marker3D and idx != -1:
			grid_entries[idx] = child;
		else:
			child.queue_free();

	start_positions.clear();
	for i in range(MAX_RACER_SLOTS):
		var marker : Marker3D = grid_entries.get(i, null) as Marker3D;
		if not marker:
			marker = Marker3D.new();
			add_child(marker, true);
			marker.owner = root;

		marker.name = "Position_%02d" % (i + 1);

		var col : int = i % GRID_COLS;
		var row : int = i / GRID_COLS;
		marker.position = Vector3(-col * RACER_POSITION_WIDTH, RACER_POSITION_MARKER_HEIGHT, row * RACER_ROWS_SPACING);

		_clean_child_mesh(marker);
		_set_marker_sprite(marker, i);
		start_positions.append(marker);

func _parse_index(node_name : String) -> int:
	if not node_name.begins_with("Position_"):
		return -1;
	var n : int = node_name.trim_prefix("Position_").to_int();
	if n >= 1 and n <= MAX_RACER_SLOTS:
		return n - 1;
	return -1;

func _clean_child_mesh(marker : Marker3D):
	for child in marker.get_children():
		marker.remove_child(child);
		child.free();

func _set_marker_sprite(marker : Marker3D, index : int):
	if index >= racer_count:
		return;

	var sprite : Sprite3D = Sprite3D.new();
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS;
	sprite.name = "GroundMarker";
	marker.add_child(sprite, true);
	var tree : SceneTree = get_tree();
	if tree:
		var root : Node = tree.edited_scene_root;
		if root:
			sprite.owner = root;

	sprite.texture = STARTING_POSITION;
	var size : float = RACER_POSITION_WIDTH * 0.6;
	sprite.pixel_size = size / 512.0;
	sprite.rotation.x = PI / 2;

func get_start_positions() -> Array[Marker3D]:
	return start_positions.duplicate();

@export_tool_button("Load Racers") var load_racers_btn : Callable : 
	get : return func(): place_racers(racers_to_load);

func place_racers(racers : Array[Node3D]) -> void:
	var count : int = mini(racers.size(), start_positions.size());
	for i in range(count):
		racers[i].global_position = start_positions[i].global_position;
