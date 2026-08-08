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

## The project's own main menu (copied from Maaack's template): extends the base MainMenu
## script and adds Continue/Level-Select/New-Game wiring plus the project options/credits
## windows. Instantiated at runtime with the project exports set directly.
const MAIN_MENU_SCENE : String = "uid://ctcm8li40gf7s";

## Opening splash (logo fade-in/out). Own copy of the template opening that animates off to this
## ProjectLoader instead of calling SceneLoader.change_scene_*.
const OPENING_SCENE : String = "uid://cgsjsem6im78i";

## Options / credits windows the menu opens.
const OPTIONS_WINDOW_SCENE : String = "uid://dvk85b4ev5pw6";
const CREDITS_WINDOW_SCENE : String = "uid://ch3o8f2hxf46b";

## Loading overlay shown while a scene loads (lives inside the UI container).
const LOADING_SCREEN_SCENE : String = "uid://dog8vbjbymv3o";

## Race HUD (RaceHUD + Spedometer). Mounted as a UI-container overlay once a track lands, so
## it appears only while a race is active and never on a menu.
const HUD_SCENE_UID : String = "uid://c1gnx5bseg8ac";

## Pause layer rebuilt every time it is opened (race slice).
const PAUSE_SCENE : String = "uid://bg2ufb71g5oyl";

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
## to GameManager. Instantiates the opening splash into the UI container. The opening's
## script background-loads its next_scene_path (the project main menu) and calls back here
## (`opening_finished` / `opening_show_loading_screen`) when the sequence ends or the load
## needs a loading overlay.
func bootstrap() -> void:
	var opening : Node = GameManager.change_gui_scene(OPENING_SCENE);
	if opening == null:
		push_error("ProjectLoader: failed to load opening %s" % OPENING_SCENE)
		return
	opening.next_scene_path = _path_from_uid(MAIN_MENU_SCENE)


## Resolves a `uid://...` reference to its current res:// path. Keeps the feature consts
## uid-based (source of truth survives moves) while giving engine APIs that only accept a
## real path (load_threaded, @export_file) a concrete location.
func _path_from_uid(scene_uid : String) -> String:
	var packed := ResourceLoader.load(scene_uid);
	if packed == null:
		push_error("ProjectLoader: could not resolve uid %s" % scene_uid)
		return scene_uid
	return packed.resource_path


## Handoff point reached by the opening when its final image has faded out (or the player
## skipped) and the background load of the main scene has finished. Swaps the loaded menu
## scene into the UI container and wires its exports / flow signal.
func opening_finished() -> void:
	var packed : PackedScene = SceneLoader.get_resource();
	if packed == null:
		push_error("ProjectLoader: opening_finished called but SceneLoader returned null; rebooting.")
		bootstrap()
		return
	var menu : Node = GameManager.change_gui_scene_packed(packed);
	if menu == null:
		push_error("ProjectLoader: failed to place main menu from opening load")
		return
	_configure_main_menu(menu);


## Called by the opening when the user finishes the intro before the menu load is done and
## the opening opted to show a loading screen. The opening already awaits SceneLoader.scene_loaded
## one-shot; all we need to do is put the loading overlay in front of the intro.
func opening_show_loading_screen() -> void:
	GameManager.show_gui_overlay(LOADING_SCREEN_SCENE);


## Configures a freshly-placed main menu instance with the project's exports and hooks its
## flow signal onto ProjectLoader. Shared between the opening handoff and direct menu loads.
func _configure_main_menu(menu : Node) -> void:
	_menu = menu;
	menu.game_scene_path = DEFAULT_TRACK_SCENE;
	menu.signal_game_start = true;
	menu.options_packed_scene = load(OPTIONS_WINDOW_SCENE);
	menu.credits_packed_scene = load(CREDITS_WINDOW_SCENE);
	if menu.has_signal("game_started"):
		menu.game_started.connect(_on_game_started_from_menu);


## Loads the main menu directly, skipping the opening intro. Used when returning to the menu
## from a race (the intro only plays at first boot).
func _show_main_menu() -> void:
	var menu : Node = GameManager.change_gui_scene(MAIN_MENU_SCENE);
	if menu == null:
		push_error("ProjectLoader: failed to load main menu %s" % MAIN_MENU_SCENE)
		return
	_configure_main_menu(menu);


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
		_show_main_menu();
		return
	GameManager.change_3D_scene_packed(packed, GameManager.ChangeMode.DELETE);
	GameManager.clear_gui_scene();
	_mount_race_ui();


## Mounts the HUD and the hidden pause layer onto the UI container. Called once the track is
## in World3D. The pause layer starts hidden and is toggled on ui_cancel while a race is up.
func _mount_race_ui() -> void:
	GameManager.show_gui_overlay(HUD_SCENE_UID);
	_pause_layer = GameManager.show_gui_overlay(PAUSE_SCENE, false);


## Toggles the pause layer while a race is active (ui_cancel in-game). Only ever opens it:
## while the game is paused the OverlayWindow owns ui_cancel and hides the layer on close.
func _unhandled_input(_event : InputEvent) -> void:
	if _pause_layer == null or not is_instance_valid(_pause_layer):
		return
	if _event.is_action_pressed("ui_cancel") and not _pause_layer.visible:
		_pause_layer.visible = true


## Returns to the main menu from an active race: clears the 3D container and every GUI
## overlay, then re-boots the menu into the UI container (no opening intro replay).
func return_to_menu() -> void:
	get_tree().paused = false;
	_loading_track = false;
	_pause_layer = null;
	GameManager.clear_3d_scene();
	GameManager.clear_gui_scene();
	_show_main_menu();


## Re-runs the current race from the pause menu's Restart. Unpauses, drops overlays and the
## 3D scene, then reloads the same track through the normal loading chain.
func restart_race() -> void:
	get_tree().paused = false;
	_loading_track = false;
	_pause_layer = null;
	GameManager.clear_3d_scene();
	await _load_track_into_world3d(_current_track_path);
