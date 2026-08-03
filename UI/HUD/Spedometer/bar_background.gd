@tool
class_name BarBackground extends TextureRect

func _set_percentage(percent : float):
	modulate = Color(0,0,0, min(percent / 100, 1));
