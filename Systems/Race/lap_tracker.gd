class_name LapTracker
extends RefCounted

## Lap counting for the time-trial slice: projects the pod onto the main spline each tick
## and credits a completed lap on every forward crossing of the start/finish seam.
##
## The first crossing is treated as the true START line when the grid sits BEHIND it (the
## classic racing layout), or as lap-1 completion when the grid sits IN FRONT of / on the
## line — decided once from the pod's initial offset, so a pod parked over the finish line
## never earns a phantom lap. Backward seam crossings (driving the wrong way) are ignored.

var track : TrackSpline
var total_length : float = 0.0
var lap_count : int = 0
var lap_times : Array[float] = []
var best_lap_time : float = INF

var _prev_offset : float = 0.0
var _initial_offset : float = 0.0
var _first_crossing_is_start : bool = false
var _first_crossing_done : bool = false
var _lap_start_time : float = 0.0


func has_track() -> bool:
	return track != null and track.get_spline() != null and total_length > 0.0


## Resets all lap state. Call once at GO before the pod can move. race_start_time seeds the
## current lap's clock (normally 0.0 — the race starts counting when controls unlock).
func setup(spline_track : TrackSpline, pod_position : Vector3, race_start_time : float) -> void:
	track = spline_track
	lap_count = 0
	lap_times.clear()
	best_lap_time = INF
	_lap_start_time = race_start_time
	_first_crossing_done = false
	_prev_offset = 0.0
	_initial_offset = 0.0
	if track == null:
		return
	var spline : Spline = track.get_spline()
	if spline == null:
		return
	total_length = spline.get_total_length()
	_prev_offset = track.project_world(pod_position)
	_initial_offset = _prev_offset
	_first_crossing_is_start = _initial_offset > total_length * 0.5


func update(pod_position : Vector3, race_time : float) -> void:
	if not has_track():
		return
	var offset : float = track.project_world(pod_position)
	var jump : float = offset - _prev_offset
	_prev_offset = offset
	if jump < -total_length * 0.5:
		if not _first_crossing_done:
			_first_crossing_done = true
			if _first_crossing_is_start:
				_lap_start_time = race_time
			else:
				_complete_lap(race_time)
		else:
			_complete_lap(race_time)


func current_lap_time(race_time : float) -> float:
	return maxf(0.0, race_time - _lap_start_time)


func current_lap_number() -> int:
	return lap_count + 1


func _complete_lap(race_time : float) -> void:
	lap_count += 1
	var lap_time : float = race_time - _lap_start_time;
	lap_times.append(lap_time)
	if lap_time < best_lap_time:
		best_lap_time = lap_time
	_lap_start_time = race_time