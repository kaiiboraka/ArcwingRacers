extends TextureRect
@onready var _viewport : SubViewport = $MaskViewport;

@export_range(0,100,.01)
var current_percentage : float = 0;

func _ready():
	material.set_shader_parameter("mask", _viewport.get_texture())
