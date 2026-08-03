extends CanvasLayer

@onready var speed_lines: ColorRect = $SpeedLines

func _ready() -> void:
	speed_lines.visible = false;
