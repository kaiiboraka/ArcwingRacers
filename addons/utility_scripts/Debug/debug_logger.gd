@tool
class_name DebugLogger
extends RefCounted

enum LogLevel {
	TRACE,
	DEBUG,
	INFO,
	WARNING,
	ERROR,
}

const DELIMITERS : Array[String] = ["[", "]"]

var object_name : String = ""
var type_name : String = ""
var script_class : String = ""


func _init(loggee : Node = null, self_node : Node = null) -> void:
	if self_node != null and loggee != null:
		object_name = self_node.name
		type_name = _type_name_of(self_node)
		script_class = loggee.name
	elif loggee != null:
		object_name = loggee.name
		script_class = loggee.get_class()
		type_name = _type_name_of(loggee)


static func _type_name_of(node : Node) -> String:
	var script : Script = node.get_script()
	if script != null:
		return script.resource_path.get_file().get_basename()
	return node.get_class()


static func _get_level_name(level : LogLevel) -> String:
	match level:
		LogLevel.TRACE:
			return "TRACE"
		LogLevel.DEBUG:
			return "DEBUG"
		LogLevel.INFO:
			return "INFO"
		LogLevel.WARNING:
			return "WARNING"
		LogLevel.ERROR:
			return "ERROR"
	return "UNKNOWN"


static func _get_level_color(level : LogLevel) -> Color:
	match level:
		LogLevel.TRACE:
			return Color.CYAN
		LogLevel.DEBUG:
			return Color.LIGHT_GREEN
		LogLevel.INFO:
			return Color.LIGHT_SKY_BLUE
		LogLevel.WARNING:
			return Color.GOLD
		LogLevel.ERROR:
			return Color.RED
	return Color.WHITE


static func _get_level_color_hex(level : LogLevel) -> String:
	return _get_level_color(level).to_html()


func _get_header(level : LogLevel) -> String:
	var level_name := _get_level_name(level)
	var time := float(Time.get_ticks_msec())
	return "%s[color=%s]%s : %s%s%s%s @ %s: %s%s" % [
		DELIMITERS[0],
		_get_level_color_hex(level),
		level_name,
		_ms_to_sec(time),
		DELIMITERS[1],
		DELIMITERS[0],
		object_name,
		type_name,
		script_class,
		DELIMITERS[1],
	]


func _log(level : LogLevel, message : String, print_color : Color = Color(0, 0, 0, 0)) -> void:
	var color : String
	if print_color == Color(0, 0, 0, 0):
		color = _get_level_color_hex(level)
	else:
		color = print_color.to_html()
	var text := "[color=%s]%s[/color]" % [color, message]
	var header_text := "%s %s" % [_get_header(level), text]
	print_rich(header_text)

	if Engine.is_editor_hint():
		return

	match level:
		LogLevel.WARNING:
			push_warning(message)
		LogLevel.ERROR:
			push_error(message)


func trace(message : String) -> void:
	_log(LogLevel.TRACE, message)


func debug(message : String) -> void:
	_log(LogLevel.DEBUG, message)


func info(message : String) -> void:
	_log(LogLevel.INFO, message)


func warning(message : String) -> void:
	_log(LogLevel.WARNING, message)


func error(message : String) -> void:
	_log(LogLevel.ERROR, message)


static func _ms_to_sec(ms : float, precision : int = 2) -> float:
	var amount := ms / 1000.0
	if precision > 0:
		return snappedf(amount, pow(10.0, -precision))
	return floor(amount)
