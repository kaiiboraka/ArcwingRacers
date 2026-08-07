extends Control

## Time-trial race HUD for the walkable slice. Discrete race events (countdown numerals, GO,
## lap completed, finish) arrive via EventBus (ADR 0002); the running lap/time numbers are
## polled every frame from the level's RaceManager node. When no RaceManager exists (any
## non-race level) the whole HUD hides itself — safe to keep mounted in the global HUD.tscn.

const GROUP_NAME : String = "RaceManager"

@onready var _panel : Control = $Panel
@onready var _lap_label : Label = $Panel/LapLabel
@onready var _current_lap_label : Label = $Panel/CurrentLapLabel
@onready var _best_lap_label : Label = $Panel/BestLapLabel
@onready var _total_time_label : Label = $Panel/TotalTimeLabel
@onready var _countdown_label : Label = $CountdownLabel
@onready var _finished_label : Label = $FinishedLabel

var _race_manager : RaceManager
var _counting_down : bool = false


func _ready() -> void:
	EventBus.race_countdown_tick.connect(_on_countdown_tick)
	EventBus.race_countdown_go.connect(_on_countdown_go)
	EventBus.race_lap_completed.connect(_on_lap_completed)
	EventBus.race_finished.connect(_on_finished)
	set_process(true)
	_update_visibility()


func _process(_delta : float) -> void:
	_update_visibility()
	var rm := _resolve_race_manager()
	if rm == null:
		return
	if rm.state == RaceManager.State.RACING:
		_lap_label.text = "Lap %d / %d" % [clampi(rm.lap_tracker.current_lap_number(), 1, rm.total_laps), rm.total_laps]
		_current_lap_label.text = "Time %s" % _format_time(rm.lap_tracker.current_lap_time(rm.race_time))
		_best_lap_label.text = "Best %s" % _format_time(rm.lap_tracker.best_lap_time)
		_total_time_label.text = "Total %s" % _format_time(rm.race_time)
	elif rm.state == RaceManager.State.FINISHED:
		_lap_label.text = "Lap %d / %d" % [rm.total_laps, rm.total_laps]
		_current_lap_label.text = "Last %s" % _format_time(rm.lap_tracker.lap_times.back() if not rm.lap_tracker.lap_times.is_empty() else rm.race_time)
		_best_lap_label.text = "Best %s" % _format_time(rm.lap_tracker.best_lap_time)
		_total_time_label.text = "Total %s" % _format_time(rm.race_time)


func _update_visibility() -> void:
	var rm := _resolve_race_manager()
	var show_panel : bool = rm != null and (rm.state == RaceManager.State.RACING or rm.state == RaceManager.State.FINISHED)
	_panel.visible = show_panel
	_finished_label.visible = rm != null and rm.state == RaceManager.State.FINISHED
	if not _counting_down:
		_countdown_label.visible = false


func _on_countdown_tick(tick : int) -> void:
	_counting_down = true
	_countdown_label.text = str(tick)
	_countdown_label.visible = true
	_countdown_label.modulate.a = 1.0


func _on_countdown_go() -> void:
	_counting_down = true
	_countdown_label.text = "GO!"
	_countdown_label.visible = true
	_countdown_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.7).tween_property(_countdown_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		_countdown_label.visible = false
		_countdown_label.modulate.a = 1.0
		_counting_down = false)


func _on_lap_completed(_lap : int, _lap_time : float, _best_lap : float) -> void:
	pass


func _on_finished(total_time : float, lap_times : Array) -> void:
	_update_visibility()
	_finished_label.text = "FINISH!\nTotal %s  |  Best %s" % [_format_time(total_time), _format_time(_best_of(lap_times))]


func _resolve_race_manager() -> RaceManager:
	if _race_manager != null and is_instance_valid(_race_manager):
		return _race_manager
	var rm := get_tree().get_first_node_in_group(GROUP_NAME) as RaceManager
	if rm != null:
		_race_manager = rm
	return rm


func _best_of(values : Array) -> float:
	var best : float = INF
	for value in values:
		best = minf(best, value)
	return best


func _format_time(seconds : float) -> String:
	if not is_finite(seconds) or seconds < 0.0:
		return "--:--.---"
	var total_ms : int = maxi(0, roundi(seconds * 1000.0))
	return "%d:%02d.%03d" % [total_ms / 60000, (total_ms / 1000) % 60, total_ms % 1000]
