@tool
class_name TreeDoodad extends Node3D

## Tree variant PackedScenes (.glb) to pick from when this node is instantiated.[br][br]
## Intended purpose: one scene stands in for several tree types — each placement randomly
## shows one variant as a child, so you scatter identical Tree nodes and get a mixed forest.[br][br]
## Add more entries to enlarge the pool; leave empty = nothing spawns (warns).
@export var models : Array[PackedScene] = []

@export var scale_range : Vector2 = Vector2(.8, 1.2);

@export_tool_button("Randomize","RandomNumberGenerator") 
var random_button : Callable = _randomize;

var my_tree : Node3D;

func _ready() -> void:
	_spawn_random()


func _spawn_random() -> void:
	if models.is_empty():
		push_warning("%s: Tree pool is empty — nothing spawned." % name)
		return
	var scene : PackedScene = models[randi_range(0, models.size() - 1)]
	if not scene:
		return
	my_tree = scene.instantiate() as Node3D;
	_randomize();
	add_child(my_tree);


func _randomize() -> void:
	my_tree.rotation_degrees.y = RandomNumberGenerator.new().randf_range(0,360);
	my_tree.scale_object_local(Vector3.ONE * RandomNumberGenerator.new().randf_range(scale_range.x, scale_range.y));
	
