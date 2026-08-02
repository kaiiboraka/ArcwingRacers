extends CanvasLayer

const HUD : PackedScene = preload("res://UI/HUD.tscn");

@onready var root_control: Control = $Root_Control

var hud_control : Control;

func _ready() -> void:
	hud_control = HUD.instantiate();
	root_control.add_child(hud_control);



func _enter_tree() -> void:
	if (!is_node_ready()): return;
	root_control.add_child(hud_control);


func _exit_tree() -> void:
	remove_child(hud_control);
