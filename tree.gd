extends Node3D

## Tree variant PackedScenes (.glb) to pick from when this node is instantiated.[br][br]
## Intended purpose: one scene stands in for several tree types — each placement randomly
## shows one variant as a child, so you scatter identical Tree nodes and get a mixed forest.[br][br]
## Add more entries to enlarge the pool; leave empty = nothing spawns (warns).
@export var models : Array[PackedScene] = []

func _ready() -> void:
	_spawn_random()

func _spawn_random() -> void:
	if models.is_empty():
		push_warning("%s: Tree pool is empty — nothing spawned." % name)
		return
	var scene : PackedScene = models[randi_range(0, models.size() - 1)]
	if not scene:
		return
	add_child(scene.instantiate())
