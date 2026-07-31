extends Node;

var steer: float = 0.0;
var accelerate: float = 0.0;
var brake: float = 0.0;
var pitch: float = 0.0;
var boost_just_pressed: bool = false;
var boost_held: bool = false;
var shield_just_pressed: bool = false;
var shield_held: bool = false;
var ability_just_pressed: bool = false;
var ability_held: bool = false;
var repair_held: bool = false;
var look_behind_just_pressed: bool = false;
var minimap_cycle_just_pressed: bool = false;

var _steer_left: bool = false;
var _steer_right: bool = false;
var _pitch_up: bool = false;
var _pitch_down: bool = false;

func _input(event):
	if event.is_action_pressed("Player_Steer_Left"):
		_steer_left = true;
		_update_steer_from_keyboard();
	elif event.is_action_released("Player_Steer_Left"):
		_steer_left = false;
		_update_steer_from_keyboard();

	if event.is_action_pressed("Player_Steer_Right"):
		_steer_right = true;
		_update_steer_from_keyboard();
	elif event.is_action_released("Player_Steer_Right"):
		_steer_right = false;
		_update_steer_from_keyboard();

	if event.is_action_pressed("Player_Accelerate"):
		accelerate = 1.0;
	elif event.is_action_released("Player_Accelerate"):
		accelerate = 0.0;

	if event.is_action_pressed("Player_Brake"):
		brake = 1.0;
	elif event.is_action_released("Player_Brake"):
		brake = 0.0;

	if event.is_action_pressed("Player_Pitch_Up"):
		_pitch_up = true;
		_update_pitch_from_keyboard();
	elif event.is_action_released("Player_Pitch_Up"):
		_pitch_up = false;
		_update_pitch_from_keyboard();

	if event.is_action_pressed("Player_Pitch_Down"):
		_pitch_down = true;
		_update_pitch_from_keyboard();
	elif event.is_action_released("Player_Pitch_Down"):
		_pitch_down = false;
		_update_pitch_from_keyboard();

	if event.is_action_pressed("Player_Boost"):
		boost_just_pressed = true;
		boost_held = true;
	elif event.is_action_released("Player_Boost"):
		boost_held = false;

	if event.is_action_pressed("Player_Shield"):
		shield_just_pressed = true;
		shield_held = true;
	elif event.is_action_released("Player_Shield"):
		shield_held = false;

	if event.is_action_pressed("Player_Ability"):
		ability_just_pressed = true;
		ability_held = true;
	elif event.is_action_released("Player_Ability"):
		ability_held = false;

	if event.is_action_pressed("Player_Repair"):
		repair_held = true;
	elif event.is_action_released("Player_Repair"):
		repair_held = false;

	if event.is_action_pressed("Player_Look_Behind"):
		look_behind_just_pressed = true;

	if event.is_action_pressed("Player_Minimap_Cycle"):
		minimap_cycle_just_pressed = true;

	if event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_LEFT_X:
				steer = event.axis_value;
			JOY_AXIS_LEFT_Y:
				pitch = event.axis_value;
			JOY_AXIS_TRIGGER_RIGHT:
				accelerate = event.axis_value;
			JOY_AXIS_TRIGGER_LEFT:
				shield_held = event.axis_value > 0.1;


func _process(_delta):
	boost_just_pressed = false;
	shield_just_pressed = false;
	ability_just_pressed = false;
	look_behind_just_pressed = false;
	minimap_cycle_just_pressed = false;


func _update_steer_from_keyboard():
	if _steer_left:
		steer = -1.0;
	elif _steer_right:
		steer = 1.0;
	else:
		steer = 0.0;


func _update_pitch_from_keyboard():
	if _pitch_up:
		pitch = 1.0;
	elif _pitch_down:
		pitch = -1.0;
	else:
		pitch = 0.0;
