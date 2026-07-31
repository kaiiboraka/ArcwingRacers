extends HBoxContainer

@export var property_label: Label
@export var value_label: Label

@export var property_text: String:
	get:
		if property_label != null:
			return property_label.text
		return ""
	set(value):
		if property_label != null:
			property_label.text = value

@export var value_text: String:
	get:
		if value_label != null:
			return value_label.text
		return ""
	set(value):
		if value_label != null:
			value_label.text = value


func _ready() -> void:
	_get_property_label()
	_get_value_label()


func _get_property_label() -> void:
	if not is_node_ready():
		return
	if property_label == null:
		property_label = %PropertyLabel


func _get_value_label() -> void:
	if not is_node_ready():
		return
	if value_label == null:
		value_label = %ValueLabel


func update_value_text(which: String, value: String) -> void:
	if which != property_text:
		return
	value_text = value
