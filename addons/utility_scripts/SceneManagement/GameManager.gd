# GameManager.gd
# Generic master-scene manager: owns the three containers every gameplay scene is
# instantiated under and swaps their content. Registered as a SCRIPT autoload (name:
# `GameManager`) so it survives scene changes and stays reachable everywhere. The
# containers themselves live in the project's one-and-only main scene (ArcwingRacers.tscn)
# and are injected once by that scene's boot script via configure(). No class_name on
# purpose -- the autoload identifier doubles as the global access name.
# Docs: technical/singleton-controllers.md
#       decisions/adrs/0011-race-manager-lifecycle-and-ownership.md

extends Node;

## Root container all 3D gameplay scenes are instantiated under. Injected by
## ArcwingRacers.tscn's _Boot node at startup via configure().
var world_3d : Node3D;
## Root container all 2D gameplay scenes are instantiated under.
var world_2d : Node2D;
## Root container all GUI / overlay scenes are instantiated under.
var ui : CanvasLayer;

## True once configure() has stored the master-scene container refs.
var configured : bool = false;

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
var current_3d_scene : Node3D;
## The scene currently loaded under the 2D container, if any.
var current_2d_scene : Node2D;
## The scene currently loaded under the UI container, if any.
var current_gui_scene : Node;

## Overlay scenes stacked on the UI container above current_gui_scene (e.g. the race HUD and
## the pause layer). Unlike current_gui_scene they do not replace each other; they are all
## shown/freed together, and any UI swap or clear drops them as a group.
var gui_overlays : Array[Node] = [];


## Injects the master containers (called once by the main scene's boot script before any
## scene swap). Also sets up the initial UI host behind the current_gui_scene pointer.
func configure(p_world_3d : Node3D, p_world_2d : Node2D, p_ui : CanvasLayer) -> void:
	assert(p_world_3d != null and p_world_2d != null and p_ui != null, "GameManager.configure(): all three containers are required.")
	world_3d = p_world_3d;
	world_2d = p_world_2d;
	ui = p_ui;
	configured = true;


## Replaces the current 3D scene with `new_scene`, disposing of the previous one per `mode`.
func change_3D_scene(new_scene : String, mode : ChangeMode = ChangeMode.DELETE) -> Node3D:
	current_3d_scene = _swap_scene(world_3d, current_3d_scene, new_scene, mode);
	return current_3d_scene;


## Replaces the current 2D scene with `new_scene`, disposing of the previous one per `mode`.
func change_2D_scene(new_scene : String, mode : ChangeMode = ChangeMode.DELETE) -> Node2D:
	current_2d_scene = _swap_scene(world_2d, current_2d_scene, new_scene, mode);
	return current_2d_scene;


## Replaces the current GUI scene with `new_scene`, disposing of the previous one per `mode`.
## Returns the swapped-in node so the caller can configure it after the swap.
func change_gui_scene(new_scene : String, mode : ChangeMode = ChangeMode.DELETE) -> Node:
	current_gui_scene = _swap_scene(ui, current_gui_scene, new_scene, mode);
	return current_gui_scene;


## Async-friendly variant of change_3D_scene: the caller handles the threaded load (e.g.
## via Maaack's SceneLoader) and passes the finished PackedScene here. Keyed in the cache by
## the packed scene's own res:// path.
func change_3D_scene_packed(packed : PackedScene, mode : ChangeMode = ChangeMode.DELETE) -> Node3D:
	current_3d_scene = _swap_packed(world_3d, current_3d_scene, packed, mode);
	return current_3d_scene;


## Async-friendly variant of change_2D_scene. See change_3D_scene_packed.
func change_2D_scene_packed(packed : PackedScene, mode : ChangeMode = ChangeMode.DELETE) -> Node2D:
	current_2d_scene = _swap_packed(world_2d, current_2d_scene, packed, mode);
	return current_2d_scene;


## Async-friendly variant of change_gui_scene. See change_3D_scene_packed.
func change_gui_scene_packed(packed : PackedScene, mode : ChangeMode = ChangeMode.DELETE) -> Node:
	current_gui_scene = _swap_packed(ui, current_gui_scene, packed, mode);
	return current_gui_scene;


## Empties the UI container entirely (frees whatever is currently loaded there). Used by
## the flow controller to drop the loading screen once a scene lands in World3D/World2D.
func clear_gui_scene() -> void:
	_dispose_current(ui, current_gui_scene, ChangeMode.DELETE);
	current_gui_scene = null;
	clear_gui_overlays();


## Instances `scene_scene` as an overlay on the UI container without replacing anything
## currently there. Used for layered GUI that coexists with the active scene (race HUD, pause
## layer). Pass `p_gui_visible=false` for overlays that must start hidden (the pause layer's
## window pauses the tree on enter_tree, so it is hidden before add_child). Returns the
## instanced node so the caller can configure it.
func show_gui_overlay(scene_scene : String, p_gui_visible : bool = true) -> Node:
	var node : Node = load(scene_scene).instantiate();
	node.visible = p_gui_visible;
	ui.add_child(node);
	gui_overlays.append(node);
	return node;


## Frees every overlay on the UI container. Called by any UI swap/clear, and by the flow
## controller when a race ends so no HUD/pause survives back into a menu.
func clear_gui_overlays() -> void:
	for node in gui_overlays:
		if is_instance_valid(node):
			node.queue_free();
	gui_overlays = [];


## Frees whatever is loaded in the 3D container. Used to leave a race back to the menu.
func clear_3d_scene() -> void:
	_dispose_current(world_3d, current_3d_scene, ChangeMode.DELETE);
	current_3d_scene = null;


## Frees whatever is loaded in the 2D container. Symmetry with clear_3d_scene.
func clear_2d_scene() -> void:
	_dispose_current(world_2d, current_2d_scene, ChangeMode.DELETE);
	current_2d_scene = null;


## Swaps the active scene in `container` from `current` to the one at `new_scene`. The
## outgoing scene is disposed of per `mode`. The new scene is loaded-and-cached (or restored
## from the cache) and returned for the caller to assign as its new current scene.
func _swap_scene(container : Node, current : Node, new_scene : String, mode : ChangeMode) -> Node:
	if container == ui:
		clear_gui_overlays();
	_dispose_current(container, current, mode);
	var key : StringName = StringName(new_scene);
	var node : Node;
	if scene_cache.has(key):
		node = scene_cache[key];
		node.visible = true;
		if node.get_parent() == null:
			container.add_child(node);
	else:
		node = load(new_scene).instantiate();
		scene_cache[key] = node;
		container.add_child(node);
	return node;


## Swaps `container`'s active scene for `packed` (already loaded by the caller — async path).
## Cache key is the PackedScene's own res:// path.
func _swap_packed(container : Node, current : Node, packed : PackedScene, mode : ChangeMode) -> Node:
	if container == ui:
		clear_gui_overlays();
	_dispose_current(container, current, mode);
	var key : StringName = StringName(packed.resource_path);
	var node : Node;
	if scene_cache.has(key):
		node = scene_cache[key];
		node.visible = true;
		if node.get_parent() == null:
			container.add_child(node);
	else:
		node = packed.instantiate();
		node.scene_file_path = packed.resource_path;
		scene_cache[key] = node;
		container.add_child(node);
	return node;


## Applies `mode` to the outgoing scene. Internal so both the string-path and packed swaps
## share one dispose path.
func _dispose_current(container : Node, current : Node, mode : ChangeMode) -> void:
	if current == null:
		return;
	match mode:
		ChangeMode.DELETE:
			scene_cache.erase(StringName(current.scene_file_path));
			current.queue_free();
		ChangeMode.HIDE:
			current.visible = false;
		ChangeMode.REMOVE:
			container.remove_child(current);
