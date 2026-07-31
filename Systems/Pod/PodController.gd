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
@export var brake_deceleration: float = 8.0

@export_category("Tilt")
@export var max_bank_angle: float = 25.0
@export var bank_speed: float = 5.0
@export var pitch_accel_angle: float = 3.0
@export var pitch_brake_angle: float = 5.0
@export var pitch_rate: float = 3.0
@export var manual_pitch_angle: float = 20.0
@export var wing_counter_tilt: float = 0.6
@export var wing_nose_tilt: float = 0.5

@export_category("Boost")
@export var boost_thrust: float = 15.0
@export var boost_max_speed: float = 50.0
@export var heat_rate: float = 1.0
@export var cool_rate: float = 1.0
@export var brake_cool_rate: float = 2.0
@export var min_charge_speed_fraction: float = 0.8

@export_category("Boost — Charge Thresholds")
@export var charge_rate: float = 1.0

@export_category("Gravity")
@export var gravity: float = 25.0

@export_category("Node References")
@export var hover_raycasts: Array[RayCast3D] = []
@export var camera_mount: Node3D
@export var wing_left: Node3D
@export var wing_right: Node3D
@onready var pcam_noise_emitter: PhantomCameraNoiseEmitter3D = $CameraMount/PhantomCameraNoiseEmitter3D

enum BoostState { CHARGING, READY, BOOSTING, OVERHEAT, COOLING }

var _boost_state: int = BoostState.CHARGING
var _charge: float = 0.0
var _heat: float = 0.0
var _current_speed: float = 0.0
var _was_accelerating: bool = false
var _has_primed: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0
var _roll: float = 0.0
var _wing_left_base: Vector3
var _wing_right_base: Vector3

func _ready():
	if Engine.is_editor_hint():
		return
	_yaw = rotation.y
	_pitch = rotation.x
	_roll = rotation.z
	for ray in hover_raycasts:
		if ray:
			ray.enabled = true
	if wing_left:
		_wing_left_base = wing_left.rotation
	if wing_right:
		_wing_right_base = wing_right.rotation

func _physics_process(delta):
	if Engine.is_editor_hint():
		return

	var input = InputCollector

	_hover(delta)
	_accelerate(delta, input)
	_brake(delta, input)
	_steer(delta, input)
	_tilt(delta, input)
	_wing_tilt(input)
	rotation = Vector3(_pitch, _yaw, _roll)
	_boost_process(delta, input)
	
	move_and_slide()

	_handle_collisions()

	_current_speed = velocity.length()
	DebugManager.update_property("Current Speed", _current_speed);


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

func _brake(delta, input):
	if input.brake <= 0.0:
		return
	var forward = -global_transform.basis.z
	var forward_speed = velocity.dot(forward)
	if forward_speed <= 0.0:
		return
	var new_forward_speed = lerp(forward_speed, 0.0, brake_deceleration * delta)
	velocity += forward * (new_forward_speed - forward_speed)

func _steer(delta, input):
	var turn = -input.steer * max_turn_rate * delta
	_yaw += turn

	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	var forward_speed = velocity.dot(forward)
	var lat = velocity - forward * forward_speed

	var lat_target = right * input.steer * traction * delta
	velocity -= lat * min(1.0, traction * delta)
	velocity += lat_target

func _tilt(delta, input):
	var speed_frac = clampf(_current_speed / max_speed, 0.0, 1.0) if max_speed > 0.0 else 0.0
	var target_roll = -input.steer * deg_to_rad(max_bank_angle) * speed_frac
	_roll = lerp(_roll, target_roll, bank_speed * delta)

	var target_pitch = input.pitch * deg_to_rad(manual_pitch_angle)
	target_pitch += input.accelerate * deg_to_rad(pitch_accel_angle)
	target_pitch -= input.brake * deg_to_rad(pitch_brake_angle)
	_pitch = lerp(_pitch, target_pitch, pitch_rate * delta)

func _wing_tilt(input):
	if not wing_left or not wing_right:
		return
	var bank = _roll * wing_counter_tilt
	var nose = _pitch * wing_nose_tilt
	wing_left.rotation = _wing_left_base + Vector3(nose, 0.0, bank)
	wing_right.rotation = _wing_right_base + Vector3(nose, 0.0, bank)

# TODO(mechanical-opening): Provisional per-wing mechanical opening infrastructure.
# When turn rate rises, fins/vents/wings open; they hold while the turn is held and decay
# back to closed when the stick returns to neutral. Each part tracks its own openness.
# Independent of the counter-tilt above. Uncomment when the visual parts exist.
#
# Future exports:
#   @export var wing_left_open: Node3D
#   @export var wing_right_open: Node3D
#   @export var open_angle: float = 12.0
#   @export var open_rate: float = 4.0
#   @export var close_rate: float = 4.0
#
# Future per-part state:
#   var _open_l: float = 0.0
#   var _open_r: float = 0.0
#
# Hook point (call from _physics_process next to _wing_tilt):
#   func _mechanical_open(delta, input):
#       var target = clampf(abs(input.steer), 0.0, 1.0)
#       var rate_l = open_rate if target > _open_l else close_rate
#       var rate_r = open_rate if target > _open_r else close_rate
#       _open_l = lerp(_open_l, target, rate_l * delta)
#       _open_r = lerp(_open_r, target, rate_r * delta)
#       if wing_left_open: wing_left_open.rotation.z = _open_l * deg_to_rad(open_angle)
#       if wing_right_open: wing_right_open.rotation.z = _open_r * deg_to_rad(open_angle)

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
	if not input.accelerate:
		_end_boost()
	if input.brake > 0.0:
		_heat = max(_heat - brake_cool_rate * input.brake * delta, 0.0)

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
		var normal = col.get_normal()
		if (!pcam_noise_emitter.is_emitting()):
			pcam_noise_emitter.emit();
		if normal.angle_to(Vector3.UP) < deg_to_rad(70.0):
			continue
		var hit_angle = abs(normal.angle_to(-global_transform.basis.z))
		if hit_angle < deg_to_rad(45.0):
			velocity *= 0.3
		else:
			velocity *= 0.85
