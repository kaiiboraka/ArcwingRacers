extends Control

## Race HUD for the time-trial slice, driven by the self-contained RaceHUD.tscn.
## Discrete race events (countdown numerals, GO, finish) arrive via EventBus (ADR 0002);
## the running numbers are snapshotted from the level's RaceManager when one is present:
## the timer and lap rows are polled per process tick and only written when their value
## changes, using the MinMax values' public Current/Maximum fields. The countdown
## numerals pop via a per-tick offset-transform tween.
##
## Without a RaceManager the HUD keeps its configured visuals (POS 1/12, LAP 1/3,
## TIME 00:00.000) and simply doesn't snapshot live data — it never hides itself.

const GROUP_NAME : String = "RaceManager"

@onready var _position_label : MinMaxValuesLabel = %Position_MinMaxValuesLabel
@onready var _timer_label : RichTextLabel = %Timer_RichTextLabel
@onready var _lap_label : MinMaxValuesLabel = %Lap_MinMaxValuesLabel
@onready var _countdown_label : RichTextLabel = %Countdown_RichTextLabel
@onready var _finished_label : RichTextLabel = %Finished_RichTextLabel
@onready var _go_label_box : HBoxContainer = $Screen_CenterContainer/GO_HBoxContainer

var _race_manager : RaceManager
var _last_timer_text : String = ""
var _last_lap_current : int = -1
var _last_lap_max : int = -1
var _tween : Tween


func _ready() -> void:
	_race_manager = get_tree().get_first_node_in_group(GROUP_NAME) as RaceManager
	EventBus.race_countdown_tick.connect(_on_countdown_tick)
	EventBus.race_countdown_go.connect(_on_countdown_go)
	EventBus.race_lap_completed.connect(_on_lap_completed)
	EventBus.race_finished.connect(_on_finished)
	set_process(true)


func _process(_delta : float) -> void:
	if _race_manager == null:
		return
	if _race_manager.state == RaceManager.State.RACING or _race_manager.state == RaceManager.State.FINISHED:
		_update_timer()
		_update_lap()


func _update_timer() -> void:
	var text : String = _format_time(_race_manager.race_time)
	if text != _last_timer_text:
		_last_timer_text = text
		_timer_label.text = text


func _update_lap() -> void:
	var current : int = clampi(_race_manager.lap_tracker.current_lap_number(), 1, _race_manager.total_laps)
	if current == _last_lap_current and _race_manager.total_laps == _last_lap_max:
		return
	_last_lap_current = current
	_last_lap_max = _race_manager.total_laps
	_lap_label.TextCurrent = str(current)
	_lap_label.TextMaximum = str(_race_manager.total_laps)


## Snapshot the POS row (current / max racers). No standings source exists yet, so this
## is only called when a system produces a position; until then the scene's configured
## values (e.g. "1 / 12") stay on screen.
func set_race_position(current : int, max_racers : int) -> void:
	_position_label.TextCurrent = str(current)
	_position_label.TextMaximum = str(max_racers)


func _on_countdown_tick(tick : int) -> void:
	_animate_countdown("[b]%d" % tick)


func _on_countdown_go() -> void:
	_go_label_box.offset_transform_position_ratio = Vector2(-2, 0);
	_go_label_box.visible = true;
	var slide_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN);
	slide_tween.tween_property(_go_label_box, "offset_transform_position_ratio", Vector2(0,0), .3);
	slide_tween.finished.connect(
		func():
			get_tree().create_timer(.15, false).timeout.connect(func(): 
				var slide_off_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN);
				slide_off_tween.tween_property(_go_label_box, "offset_transform_position_ratio", Vector2(2,0), .3);
				slide_off_tween.finished.connect(func(): _go_label_box.visible = false);
			);
	)
	#_animate_countdown("[b]GO!")


func _animate_countdown(text_value : String) -> void:
	_kill_tween()
	_countdown_label.text = text_value
	_countdown_label.visible = true
	_countdown_label.modulate.a = 1.0
	_countdown_label.offset_transform_enabled = true
	_countdown_label.offset_transform_scale = Vector2(0.6, 0.6)
	_countdown_label.offset_transform_position = Vector2(0, 40)
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_ELASTIC)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(_countdown_label, "offset_transform_scale", Vector2.ONE, 0.2)
	_tween.parallel().tween_property(_countdown_label, "offset_transform_position", Vector2.ZERO, 0.2)
	_tween.tween_interval(0.55)
	_tween.tween_property(_countdown_label, "modulate:a", 0.0, 0.25)
	_tween.tween_callback(func() -> void:
		_countdown_label.visible = false
		_countdown_label.modulate.a = 1.0
		_countdown_label.offset_transform_scale = Vector2.ONE
		_countdown_label.offset_transform_position = Vector2.ZERO)


func _on_lap_completed(_lap : int, _lap_time : float, _best_lap : float) -> void:
	_update_lap()


func _on_finished(total_time : float, lap_times : Array) -> void:
	_finished_label.text = "[b][i]FINISH\nTotal %s\nBest %s[/i][/b]" % [_format_time(total_time), _format_time(_best_of(lap_times))]
	_finished_label.visible = true
	_kill_tween()
	_finished_label.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_finished_label, "modulate:a", 1.0, 0.35)


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
	_tween = null


func _best_of(values : Array) -> float:
	var best : float = INF
	for value in values:
		best = minf(best, value)
	return best


func _format_time(seconds : float) -> String:
	if not is_finite(seconds) or seconds < 0.0:
		return "--:--.---"
	var total_ms : int = maxi(0, roundi(seconds * 1000.0))
	return "%d:%02d.%02d" % [total_ms / 60000, (total_ms / 1000) % 60, total_ms % 1000]
