# ProjectLoader.gd
# Project flow controller (ADR 0011 composition hub). Registered as a SCRIPT autoload
# (name: `ProjectLoader`) so it survives scene changes. Owns every project scene path and
# chains the async scene load through Maaack's SceneLoader autoload into the GameManager
# containers. No get_tree().change_scene_* is ever used -- the master scene
# (ArcwingRacers.tscn) is loaded once and everything else instances inside its World3D /
# World2D / UI containers, which the boot script injects via GameManager.configure().
#
# Docs: docs/agent-context/plans/plan-game-flow-and-scene-management.md
#       decisions/adrs/0011-race-manager-lifecycle-and-ownership.md

extends Node;

## Maaack's clean base MainMenu scene (no GameState/win-lose dependency). Instantiated at
## runtime with project exports set directly -- it never falls back to AppConfig.
const MAIN_MENU_SCENE : String = "res://addons/maaacks_game_template/base/nodes/menus/main_menu/main_menu.tscn";

## Options / credits windows the menu opens (from the installed template copy).
const OPTIONS_WINDOW_SCENE : String = "res://UI/Example_Scenes/scenes/windows/main_menu_options_window.tscn";
const CREDITS_WINDOW_SCENE : String = "res://UI/Example_Scenes/scenes/windows/main_menu_credits_window.tscn";

## Loading overlay shown while a scene loads (lives inside the UI container).
const LOADING_SCREEN_SCENE : String = "res://UI/Example_Scenes/scenes/loading_screen/loading_screen.tscn";

## Race HUD (RaceHUD + Spedometer). Mounted as a UI-container overlay once a track lands, so
## it appears only while a race is active and never on a menu.
const HUD_SCENE : String = "res://UI/HUD.tscn";

## Pause layer rebuilt every time it is opened (race slice).
const PAUSE_SCENE : String = "res://UI/Example_Scenes/scenes/windows/pause_menu_layer.tscn";

## Default gameplay track for the menu's New Game: Level_Grassy. Test_Level is the same rig
## with less dressing.
const DEFAULT_TRACK_SCENE : String = "res://Content/Scenes/Levels/Level_Grassy.tscn";

var _loading_track : bool = false;
var _menu : Node;
## Instance of the pause layer while a race is active; null otherwise. Toggled on ui_cancel.
var _pause_layer : Node;
## The res:// path of the race currently running (used by restart_race). Defaults to the
## menu's New Game track.
var _current_track_path : String = DEFAULT_TRACK_SCENE;


## Entry point, called from the master scene's boot script after it assigns the containers
## to GameManager. Instantiates the main menu with project exports and places it in the UI
## container, then hooks its flow signal.
func bootstrap() -> void:
	var menu : Node = GameManager.change_gui_scene(MAIN_MENU_SCENE);
	if menu == null:
		push_error("ProjectLoader: failed to load main menu %s" % MAIN_MENU_SCENE)
		return
	_menu = menu;
	menu.game_scene_path = DEFAULT_TRACK_SCENE;
	menu.signal_game_start = true;
	menu.options_packed_scene = load(OPTIONS_WINDOW_SCENE);
	menu.credits_packed_scene = load(CREDITS_WINDOW_SCENE);
	if menu.has_signal("game_started"):
		menu.game_started.connect(_on_game_started_from_menu);


## Handles the main menu's `game_started` signal. The menu has already started the
## background load of its `game_scene_path` export (signal_game_start); ProjectLoader shows
## the loading screen, waits for the load, then swaps the track into World3D.
func _on_game_started_from_menu() -> void:
	await _consume_ready_load_into_world3d();


## Public starter for a race. track_path: scene to instantiate under World3D. Starts the
## background load itself. The race-flow composition (spawn RaceManager, call begin_race)
## is added here when the race slice (ADR 0011) lands.
func start_race(track_path : String) -> void:
	await _load_track_into_world3d(track_path);


## Initiates a fresh background load of track_path and runs the container swap chain.
func _load_track_into_world3d(track_path : String) -> void:
	if _loading_track:
		return
	_loading_track = true;
	_current_track_path = track_path;
	GameManager.change_gui_scene(LOADING_SCREEN_SCENE);
	SceneLoader.load_scene(track_path, true);
	await _finish_swap();
	_loading_track = false;


## Same swap chain, no new load -- the load is already in flight (menu's signal_game_start).
func _consume_ready_load_into_world3d() -> void:
	if _loading_track:
		return
	_loading_track = true;
	_current_track_path = _menu.game_scene_path;
	GameManager.change_gui_scene(LOADING_SCREEN_SCENE);
	await _finish_swap();
	_loading_track = false;


## Shared tail: wait for the threaded load to report LOADED, then place the packed scene in
## World3D, drop the loading overlay, and mount the race UI (HUD + pause layer).
func _finish_swap() -> void:
	if SceneLoader.get_status() != ResourceLoader.THREAD_LOAD_LOADED:
		await SceneLoader.scene_loaded
	var packed : PackedScene = SceneLoader.get_resource();
	if packed == null:
		push_error("ProjectLoader: SceneLoader returned null; returning to menu.")
		_loading_track = false;
		bootstrap();
		return
	GameManager.change_3D_scene_packed(packed, GameManager.ChangeMode.DELETE);
	GameManager.clear_gui_scene();
	_mount_race_ui();


## Mounts the HUD and the hidden pause layer onto the UI container. Called once the track is
## in World3D. The pause layer starts hidden and is toggled on ui_cancel while a race is up.
func _mount_race_ui() -> void:
	GameManager.show_gui_overlay(HUD_SCENE);
	_pause_layer = GameManager.show_gui_overlay(PAUSE_SCENE, false);


## Toggles the pause layer while a race is active (ui_cancel in-game). Only ever opens it:
## while the game is paused the OverlayWindow owns ui_cancel and hides the layer on close.
func _unhandled_input(_event : InputEvent) -> void:
	if _pause_layer == null or not is_instance_valid(_pause_layer):
		return
	if _event.is_action_pressed("ui_cancel") and not _pause_layer.visible:
		_pause_layer.visible = true


## Returns to the main menu from an active race: clears the 3D container and every GUI
## overlay, then re-boots the menu into the UI container
func return_to_menu() -> void:
	get_tree().paused = false;
	_loading_track = false;
	_pause_layer = null;
	GameManager.clear_3d_scene();
	GameManager.clear_gui_scene();
	bootstrap();


## Re-runs the current race from the pause menu's Restart. Unpauses, drops overlays and the
## 3D scene, then reloads the same track through the normal loading chain.
func restart_race() -> void:
	get_tree().paused = false;
	_loading_track = false;
	_pause_layer = null;
	GameManager.clear_3d_scene();
	await _load_track_into_world3d(_current_track_path);
