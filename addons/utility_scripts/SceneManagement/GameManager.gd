# GameManager.gd
# Generic master scene for the game: owns the three containers every gameplay scene is
# instantiated under and swaps their content. Registered as the project autoload (name:
# `GameManager`) so it survives scene changes and stays reachable everywhere. No class_name
# on purpose -- matches the EventBus / ScreenEffects autoload pattern, and the autoload
# identifier doubles as the global access name.
# Docs: technical/singleton-controllers.md
#       decisions/adrs/0011-race-manager-lifecycle-and-ownership.md

extends Node;

## Root container all 3D gameplay scenes are instantiated under.
@export var world_3D : Node3D;
## Root container all 2D gameplay scenes are instantiated under.
@export var world_2D : Node2D;
## Root container all GUI / overlay scenes are instantiated under.
@export var ui : CanvasLayer;

## How the previously-loaded scene in a container is disposed of when a new one loads.
enum ChangeMode {
	## Remove the scene entirely. The node is freed and its cached instance is dropped, so
	## any state it held is lost.
	DELETE,
	## Keep the scene in the tree and running, but invisible. UI / world keep processing and
	## can be re-shown without re-instantiating.
	HIDE,
	## Keep the scene cached and remove it from the tree. It stops processing while detached,
	## but the same instance is re-added later.
	REMOVE,
}

## Every scene shown via change_*_scene(), keyed by its res:// path.
var scene_cache : Dictionary[StringName, Node] = {};

## The scene currently loaded under the 3D container, if any.
var current_3D_scene : Node3D;
## The scene currently loaded under the 2D container, if any.
var current_2D_scene : Node2D;
## The scene currently loaded under the UI container, if any.
var current_gui_scene : Node;


## Replaces the current 3D scene with `new_scene`, disposing of the previous one per `mode`.
func change_3D_scene(new_scene : String, mode : ChangeMode = ChangeMode.DELETE) -> void:
	current_3D_scene = _swap_scene(world_3D, current_3D_scene, new_scene, mode);


## Replaces the current 2D scene with `new_scene`, disposing of the previous one per `mode`.
## Cached scenes are re-shown without reloading; uncached paths are loaded and cached.
func change_2D_scene(new_scene : String, mode : ChangeMode = ChangeMode.DELETE) -> void:
	current_2D_scene = _swap_scene(world_2D, current_2D_scene, new_scene, mode);


## Replaces the current GUI scene with `new_scene`, disposing of the previous one per `mode`.
## Cached scenes are re-shown without reloading; uncached paths are loaded and cached.
func change_gui_scene(new_scene : String, mode : ChangeMode = ChangeMode.DELETE) -> void:
	current_gui_scene = _swap_scene(ui, current_gui_scene, new_scene, mode);


## Swaps the active scene in `container` from `current` to the one at `new_scene`. The
## outgoing scene is disposed of per `mode`. The new scene is loaded-and-cached (or restored
## from the cache) and returned for the caller to assign as its new current scene.
func _swap_scene(container : Node, current : Node, new_scene : String, mode : ChangeMode) -> Node:
	if current != null:
		match mode:
			ChangeMode.DELETE:
				var scene_path : StringName = StringName(current.scene_file_path);
				scene_cache.erase(scene_path);
				current.queue_free();
			ChangeMode.HIDE:
				current.visible = false;
			ChangeMode.REMOVE:
				container.remove_child(current);
	var key : StringName = StringName(new_scene);
	var node : Node;
	if scene_cache.has(key):
		node = scene_cache[key];
		if node.get_parent() == null:
			container.add_child(node);
		node.visible = true;
	else:
		node = load(new_scene).instantiate();
		scene_cache[key] = node;
		container.add_child(node);
	return node;
