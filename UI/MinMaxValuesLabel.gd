@tool
class_name MinMaxValuesLabel
extends HBoxContainer

## GDScript port of MinMaxValuesLabel.cs (Elythia). Displays a "current / max" value row
## built from three labelled panels. All editor-facing properties (toggles, text, text size,
## alignment) keep the same names and inspector grouping as the C# original; node references
## are resolved via export with a unique-name fallback, then applied to the nodes in _ready.

@export_group("Components")
@export_subgroup("Labels", "label")
@export var labelCurrent : Label
@export var labelDivider : Label
@export var labelMax : Label
@export_subgroup("Panels", "panel")
@export var panelCurrent : Panel
@export var panelDivider : Panel
@export var panelMax : Panel

## Backing fields mirror the C# so the property setters can run before/without the referenced
## nodes being resolved yet.
var backing_toggle_current : bool = true
var backing_toggle_divider : bool = true
var backing_toggle_max : bool = true
var backing_text_current : String = "0"
var backing_text_divider : String = "/"
var backing_text_maximum : String = "9999"
var backing_alignment_current : HorizontalAlignment = HORIZONTAL_ALIGNMENT_RIGHT
var backing_alignment_divider : HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
var backing_alignment_max : HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
var backing_text_size : int = 16
var backing_offset_x_current : float = 0.0
var backing_offset_x_divider : float = 0.0
var backing_offset_x_max : float = 0.0


# --- Controls ------------------------------------------------------------------

@export_group("Controls")

@export_subgroup("Toggles", "Toggle")
@export var ToggleCurrent : bool:
	get:
		return backing_toggle_current
	set(value):
		backing_toggle_current = value
		if panelCurrent != null:
			panelCurrent.visible = value

@export var ToggleDivider : bool:
	get:
		return backing_toggle_divider
	set(value):
		backing_toggle_divider = value
		if panelDivider != null:
			panelDivider.visible = value

@export var ToggleMax : bool:
	get:
		return backing_toggle_max
	set(value):
		backing_toggle_max = value
		if panelMax != null:
			panelMax.visible = value

@export_subgroup("Text", "Text")
@export var TextCurrent : String:
	get:
		return backing_text_current
	set(value):
		backing_text_current = value
		if labelCurrent != null:
			labelCurrent.text = value

@export var TextDivider : String:
	get:
		return backing_text_divider
	set(value):
		backing_text_divider = value
		if labelDivider != null:
			labelDivider.text = value

@export var TextMaximum : String:
	get:
		return backing_text_maximum
	set(value):
		backing_text_maximum = value
		if labelMax != null:
			labelMax.text = value

@export var TextSize : int:
	get:
		return backing_text_size
	set(value):
		backing_text_size = value
		if labelCurrent != null:
			labelCurrent.add_theme_font_size_override("font_size", backing_text_size)
		if labelDivider != null:
			labelDivider.add_theme_font_size_override("font_size", backing_text_size)
		if labelMax != null:
			labelMax.add_theme_font_size_override("font_size", backing_text_size)

@export_subgroup("Alignment", "Alignment")
@export var AlignmentCurrent : HorizontalAlignment:
	get:
		return backing_alignment_current
	set(value):
		backing_alignment_current = value
		if labelCurrent != null:
			labelCurrent.horizontal_alignment = value

@export var AlignmentDivider : HorizontalAlignment:
	get:
		return backing_alignment_divider
	set(value):
		backing_alignment_divider = value
		if labelDivider != null:
			labelDivider.horizontal_alignment = value

@export var AlignmentMax : HorizontalAlignment:
	get:
		return backing_alignment_max
	set(value):
		backing_alignment_max = value
		if labelMax != null:
			labelMax.horizontal_alignment = value

@export_subgroup("Offsets", "Offset")
@export var OffsetCurrentX : float:
	get:
		return backing_offset_x_current
	set(value):
		backing_offset_x_current = value
		if labelCurrent != null:
			labelCurrent.offset_transform_position.x = value

@export var OffsetDividerX : float:
	get:
		return backing_offset_x_divider
	set(value):
		backing_offset_x_divider = value
		if labelDivider != null:
			labelDivider.offset_transform_position.x = value

@export var OffsetMaxX : float:
	get:
		return backing_offset_x_max
	set(value):
		backing_offset_x_max = value
		if labelMax != null:
			labelMax.offset_transform_position.x = value


func _ready() -> void:
	# Ensures the nodes are found and their properties are set both when the scene runs
	# and when it's displayed in the editor.
	_get_components()
	_update_node_properties()


func _get_components() -> void:
	# Node references are resolved via the geomatically exported NodePaths; unique names
	# (%Name) act as a fallback when the references aren't assigned.
	if labelCurrent == null:
		labelCurrent = get_node("%LabelCurrent")
	if labelDivider == null:
		labelDivider = get_node("%LabelDivider")
	if labelMax == null:
		labelMax = get_node("%LabelMax")
	if panelCurrent == null:
		panelCurrent = get_node("%PanelCurrent")
	if panelDivider == null:
		panelDivider = get_node("%PanelDivider")
	if panelMax == null:
		panelMax = get_node("%PanelMax")


func _update_node_properties() -> void:
	# Apply all backed properties to the nodes.
	if panelCurrent != null:
		panelCurrent.visible = backing_toggle_current
	if panelDivider != null:
		panelDivider.visible = backing_toggle_divider
	if panelMax != null:
		panelMax.visible = backing_toggle_max

	if labelCurrent != null:
		labelCurrent.text = backing_text_current
		labelCurrent.horizontal_alignment = backing_alignment_current
		labelCurrent.offset_transform_position.x = backing_offset_x_current

	if labelDivider != null:
		labelDivider.text = backing_text_divider
		labelDivider.horizontal_alignment = backing_alignment_divider
		labelDivider.offset_transform_position.x = backing_offset_x_divider

	if labelMax != null:
		labelMax.text = backing_text_maximum
		labelMax.horizontal_alignment = backing_alignment_max
		labelMax.offset_transform_position.x = backing_offset_x_max
