@tool
class_name BarFill
extends TextureRect

## Clips the bar fill's colored texture to the union of three sliding masks.
## Each mask's transform is a pure function of current_percentage, so any jump
## instantly produces the correct state (hidden fills reset to their start).

const PIXEL_RANGE : float = 260.0;

@export var _viewport : SubViewport;
@export var _fill_1 : TextureRect;
@export var _fill_2 : TextureRect;
@export var _fill_3 : TextureRect;
@export var _background : BarBackground;
@export var bg_darken_rate : float = 1;

@export_range(0, 100, 0.01) var current_percentage : float = 0.0:
	set(value):
		current_percentage = clampf(value, 0.0, 100.0);
		if _fill_1 != null:
			_update_fills();

## External input in percent (0-100) — call from a system signal.
func set_percentage(pct : float) -> void:
	current_percentage = pct;
	if (_background):
		#print("bar name:", get_path())
		#print("current percentage:", current_percentage)
		#print("bg mod:", _background.modulate)
		_background._set_percentage(current_percentage * bg_darken_rate);

func _ready():
	
	material.set_shader_parameter("mask", _viewport.get_texture());
	_update_fills();

func _update_fills() -> void:
	var px : float = current_percentage / 100.0 * PIXEL_RANGE;
	_update_fill_1(px);
	_update_fill_2(px);
	_update_fill_3(px);

func _lerp_angle(from_deg : float, to_deg : float, t : float) -> float:
	return deg_to_rad(lerpf(from_deg, to_deg, t));

func _update_fill_1(px : float) -> void:
	_fill_1.visible = true;
	if px <= 49.0:
		var t : float = px / 49.0;
		_fill_1.position = Vector2(lerpf(-75.0, -26.0, t), 189.0);
		_fill_1.rotation = 0.0;
	elif px <= 60.0:
		var t : float = (px - 49.0) / 11.0;
		_fill_1.position = Vector2(-26.0, 189.0);
		_fill_1.rotation = _lerp_angle(0.0, -20.0, t);
	else:
		_fill_1.position = Vector2(-26.0, 189.0);
		_fill_1.rotation = deg_to_rad(-20.0);

func _update_fill_2(px : float) -> void:
	if px < 60.0:
		_fill_2.visible = false;
		_fill_2.position = Vector2(53.0, 193.0);
		_fill_2.rotation = deg_to_rad(70.0);
		return;
	_fill_2.visible = true;
	if px <= 66.0:
		var t : float = (px - 60.0) / 6.0;
		_fill_2.position = Vector2(53.0, 193.0);
		_fill_2.rotation = _lerp_angle(70.0, 45.0, t);
	elif px <= 150.0:
		var t : float = (px - 66.0) / 84.0;
		_fill_2.position = Vector2(lerpf(53.0, 137.0, t), lerpf(193.0, 110.0, t));
		_fill_2.rotation = deg_to_rad(45.0);
	else:
		_fill_2.position = Vector2(137.0, 110.0);
		_fill_2.rotation = deg_to_rad(45.0);

func _update_fill_3(px : float) -> void:
	if px < 150.0:
		_fill_3.visible = false;
		_fill_3.position = Vector2(137.0, 110.0);
		_fill_3.rotation = deg_to_rad(45.0);
		return;
	_fill_3.visible = true;
	if px <= 160.0:
		var t : float = (px - 150.0) / 10.0;
		_fill_3.position = Vector2(137.0, 110.0);
		_fill_3.rotation = _lerp_angle(45.0, 0.0, t);
	elif px <= 170.0:
		var t : float = (px - 160.0) / 10.0;
		_fill_3.position = Vector2(137.0, lerpf(110.0, 111.0, t));
		_fill_3.rotation = _lerp_angle(0.0, -45.0, t);
	elif px <= 260.0:
		var t : float = (px - 170.0) / 90.0;
		_fill_3.position = Vector2(lerpf(137.0, 48.0, t), lerpf(111.0, 22.0, t));
		_fill_3.rotation = deg_to_rad(-45.0);
	else:
		_fill_3.position = Vector2(48.0, 22.0);
		_fill_3.rotation = deg_to_rad(-45.0);
