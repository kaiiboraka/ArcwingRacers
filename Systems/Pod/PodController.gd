extends CharacterBody3D

@export_category("Hover")
@export var hover_height: float = 3.0
@export var spring_stiffness: float = 8.0
@export var spring_damping: float = 3.0

@export_category("Movement")
@export var max_speed: float = 30.0
@export var acceleration_factor: float = 4.0
@export var max_turn_rate: float = 2.0
@export var traction: float = 8.0

@export_category("Boost")
@export var boost_thrust: float = 15.0
@export var boost_max_speed: float = 50.0
@export var heat_rate: float = 1.0
@export var cool_rate: float = 1.0
@export var min_charge_speed_fraction: float = 0.8

@export_category("Boost — Charge Thresholds")
@export var charge_rate: float = 1.0

@export_category("Gravity")
@export var gravity: float = 25.0

@export_category("Node References")
@export var hover_raycasts: Array[RayCast3D] = []
@export var camera_mount: Node3D

enum BoostState { CHARGING, READY, BOOSTING, OVERHEAT, COOLING }

var _boost_state: int = BoostState.CHARGING
var _charge: float = 0.0
var _heat: float = 0.0
var _current_speed: float = 0.0
var _was_accelerating: bool = false
var _has_primed: bool = false

func _ready():
	if Engine.is_editor_hint():
		return
	for ray in hover_raycasts:
		if ray:
			ray.enabled = true

func _physics_process(delta):
	if Engine.is_editor_hint():
		return

	var input = InputCollector

	_hover(delta)
	_accelerate(delta, input)
	_steer(delta, input)
	_boost_process(delta, input)

	move_and_slide()

	_handle_collisions()

	_current_speed = velocity.length()

func _hover(delta):
	velocity.y -= gravity * delta

	var max_upward := -999.0
	for ray in hover_raycasts:
		if not ray.is_colliding():
			continue
		var point = ray.get_collision_point()
		var dist = ray.global_position.distance_to(point)
		var compression = hover_height - dist
		if compression <= 0.0:
			continue
		var correction = compression * spring_stiffness - velocity.y * spring_damping
		if correction > max_upward:
			max_upward = correction

	if max_upward > -999.0:
		if max_upward > velocity.y:
			velocity.y = lerp(velocity.y, max_upward, 4.0 * delta)

func _accelerate(delta, input):
	if input.accelerate <= 0.0:
		return

	var target = max_speed
	if _boost_state == BoostState.BOOSTING:
		target = boost_max_speed

	var forward = -global_transform.basis.z
	var current_forward_speed = velocity.dot(forward)

	var target_forward = input.accelerate * target
	var new_forward_speed = lerp(current_forward_speed, target_forward, acceleration_factor * delta)

	velocity += forward * (new_forward_speed - current_forward_speed)

func _steer(delta, input):
	var turn = input.steer * max_turn_rate * delta
	rotate_y(turn)

	var forward = -global_transform.basis.z
	var forward_speed = velocity.dot(forward)
	var lat = velocity - forward * forward_speed

	var lat_target = forward * input.steer * traction * delta
	velocity -= lat * min(1.0, traction * delta)
	velocity += lat_target

func _boost_process(delta, input):
	match _boost_state:
		BoostState.CHARGING:
			_charge_boost(delta, input)
		BoostState.READY:
			_try_activate_boost(input)
		BoostState.BOOSTING:
			_boost_update(delta, input)
		BoostState.OVERHEAT:
			_cool_down(delta)
		BoostState.COOLING:
			_cool_down(delta)

func _charge_boost(delta, input):
	var speed_frac = _current_speed / max_speed if max_speed > 0 else 0.0
	if input.pitch <= 0.0 or speed_frac < min_charge_speed_fraction:
		return
	_charge += charge_rate * abs(input.pitch) * delta
	_charge = min(_charge, 1.0)
	if _charge >= 1.0:
		_boost_state = BoostState.READY

func _try_activate_boost(input):
	if not input.accelerate:
		_has_primed = true
	elif _has_primed and input.accelerate:
		_start_boost()

func _start_boost():
	_boost_state = BoostState.BOOSTING
	_heat = 0.0
	_charge = 0.0
	_has_primed = false

func _boost_update(delta, input):
	_heat += heat_rate * delta
	if _heat >= 1.0:
		_overheat()
		return
	if not input.accelerate or input.brake > 0.0:
		_end_boost()

func _overheat():
	_boost_state = BoostState.OVERHEAT

func _end_boost():
	_boost_state = BoostState.COOLING
	_heat = max(_heat, 0.1)

func _cool_down(delta):
	_heat -= cool_rate * delta
	_heat = max(_heat, 0.0)
	if _heat <= 0.0:
		_boost_state = BoostState.CHARGING
		_charge = 0.0

func _handle_collisions():
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		if not col:
			continue
		var hit_angle = abs(col.get_normal().angle_to(-global_transform.basis.z))
		if hit_angle < deg_to_rad(45.0):
			velocity *= 0.3
		else:
			velocity *= 0.85
