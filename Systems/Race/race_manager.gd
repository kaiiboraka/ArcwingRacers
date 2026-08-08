class_name RaceManager
extends Node

## Single-player time-trial coordinator for the race vertical slice. Places the pod on the
## starting grid, locks its controls through the 3-2-1 countdown, then clocks laps via
## LapTracker until the pod finishes `total_laps` (or the timeout) and broadcasts the result.
##
## Lives as a scene node in the level with pod / track / starting-line exported in the
## inspector. Everything the HUD needs is broadcast through the EventBus autoload (ADR 0002);
## the HUD finds this node via the "RaceManager" group when it polls the running clock.

const GROUP_NAME : String = "RaceManager"

enum State {
	## Pod parked on the grid, controls locked, waiting out pregame_duration.
	PREGAME,
	## 3-2-1 numerals per second; controls still locked.
	COUNTDOWN,
	## Clock running; LapTracker credits laps each forward seam crossing.
	RACING,
	## Timer stopped; result broadcast once (lap target reached or timeout).
	FINISHED,
}

## The player pod. Its global_position is read for lap projection and it is placed on the
## grid and input-locked via set_input_locked() during PREGAME + COUNTDOWN.
@export var pod : Node3D
## The constructed track spline the loop drives around — the lap seam is its offset 0.
@export var track : TrackSpline
## Worldground markers. The pod is dropped on Position_01 at PREGAME. Optional: when unset the
## pod keeps its placed position.
@export var starting_line : StartingLine

## How many completed laps end the race.
@export_range(1, 9) var total_laps : int = 3
## Seconds the pod sits parked on the grid before the 3-2-1 countdown begins.
@export_range(0.0, 10.0) var pregame_duration : float = 1.0
## Safety: total race_clock seconds after which the race is cut short even if total_laps is
## unmet. Higher = more forgiving for long tracks.
@export_range(30.0, 600.0) var timeout_seconds : float = 360.0

var state : int = State.PREGAME
var race_time : float = 0.0
var lap_tracker : LapTracker = LapTracker.new()

var _last_notified_laps : int = 0


func _ready() -> void:
	add_to_group(GROUP_NAME)
	if pod == null or track == null:
		push_warning("RaceManager (%s): `pod` and `track` must be wired in the inspector — race disabled." % name)
		return
	_begin_pregame()


func _begin_pregame() -> void:
	_set_state(State.PREGAME)
	_place_pod_on_grid()
	_set_pod_locked(true)
	EventBus.race_pregame_ready.emit()
	await get_tree().create_timer(pregame_duration, false).timeout
	_start_countdown()


func _start_countdown() -> void:
	_set_state(State.COUNTDOWN)
	for tick in [3, 2, 1]:
		EventBus.race_countdown_tick.emit(tick)
		await get_tree().create_timer(1.0, false).timeout
	EventBus.race_countdown_go.emit()
	_start_racing()


func _start_racing() -> void:
	_set_state(State.RACING)
	race_time = 0.0
	lap_tracker.setup(track, pod.global_position, 0.0)
	_last_notified_laps = 0
	_set_pod_locked(false)
	EventBus.race_started.emit()


func _physics_process(delta : float) -> void:
	if state != State.RACING:
		return
	race_time += delta
	lap_tracker.update(pod.global_position, race_time)
	if lap_tracker.lap_count > _last_notified_laps:
		_last_notified_laps = lap_tracker.lap_count
		EventBus.race_lap_completed.emit(
			lap_tracker.lap_count,
			lap_tracker.lap_times.back(),
			lap_tracker.best_lap_time)
	if lap_tracker.lap_count >= total_laps or race_time >= timeout_seconds:
		_finish_race()


func _finish_race() -> void:
	if state == State.FINISHED:
		return
	_set_state(State.FINISHED)
	EventBus.race_finished.emit(race_time, lap_tracker.lap_times)


func _set_state(new_state : int) -> void:
	if state == new_state:
		return
	state = new_state
	EventBus.race_state_changed.emit(state)


func _place_pod_on_grid() -> void:
	if pod == null or starting_line == null:
		return
	var marker := starting_line.get_node_or_null("Position_01") as Marker3D
	if marker == null:
		var positions : Array[Marker3D] = starting_line.get_start_positions()
		if not positions.is_empty():
			marker = positions[0]
	if marker != null:
		pod.global_position = marker.global_position


func _set_pod_locked(locked : bool) -> void:
	if pod != null and pod.has_method("set_input_locked"):
		pod.set_input_locked(locked)