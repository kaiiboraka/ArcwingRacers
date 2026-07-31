extends CharacterBody3D

## Wall-angle penalty curve. x = angle fraction (0 = grazing side-scrape, 1 = dead-on nose hit).
## Penalty factor at 45° off-dead-on: COSINE 0.71, LINEAR 0.50, QUADRATIC 0.25, CUBIC 0.13, SMOOTHSTEP 0.25.
## COSINE hits hard even on shallow clips; CUBIC barely touches you until near-perfect head-ons.
enum WallAngleCurve {
	## cos(angle) — the raw metric. Harsh falloff: 0.71 penalty even at 45° off-dead-on. Default.
	COSINE,
	## Flat in angle: penalty = 1 - angle/90. 0.50 at 45° off-dead-on.
	LINEAR,
	## penalty = x^2. Forgiving: 0.25 at 45° off-dead-on.
	QUADRATIC,
	## penalty = x^3. Most forgiving: only dead-on hits hurt (0.13 at 45° off-dead-on).
	CUBIC,
	## S-curve: penalty = x^2 * (3 - 2x). Soft shoulder, snaps to full near dead-on (0.25 at 45°).
	SMOOTHSTEP,
}

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
@export var nose_up_turn_multiplier: float = 1.5
@export var nose_down_turn_multiplier: float = 0.5

@export_category("Tilt")
@export var max_bank_angle: float = 25.0
@export var bank_speed: float = 5.0
@export var pitch_accel_angle: float = 3.0
@export var pitch_brake_angle: float = 5.0
@export var pitch_rate: float = 3.0
@export var manual_pitch_angle: float = 20.0
@export var wing_counter_tilt_deg: float = 25.0
@export var wing_nose_tilt_deg: float = 20.0
@export var wing_tilt_speed: float = 6.0

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
@export var gravity_mod_nose_up: float = 0.5
@export var gravity_mod_nose_down: float = 1.6

@export_category("Collision")
@export var wall_impact_loss: float = 0.7
@export var wall_brute_force_loss: float = 0.15
@export var wall_angle_curve: WallAngleCurve = WallAngleCurve.COSINE

@export_category("Node References")
@export var hover_raycasts: Array[RayCast3D] = []
@export var camera_mount: Node3D
@onready var wing_left: Node3D = %Wing_Left
@onready var wing_right: Node3D = %Wing_Right
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
var _wing_bank: float = 0.0
var _wing_nose: float = 0.0

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

	_hover(delta, input)
	_accelerate(delta, input)
	_brake(delta, input)
	_steer(delta, input)
	_tilt(delta, input)
	_wing_tilt(delta, input)
	rotation = Vector3(0.0, _yaw, _roll)
	_boost_process(delta, input)
	
	move_and_slide()

	_handle_collisions()

	_current_speed = velocity.length()
	DebugManager.update_property("~~_ Movement _~~", "~~~~~~~~~~~~")
	DebugManager.update_property("Current Speed", String.num(_current_speed, 2));
	DebugManager.update_property("Speed Fraction", String.num(_current_speed / max_speed, 2));
	DebugManager.update_property("Vertical Speed", String.num(velocity.y, 2));
	DebugManager.update_property("Heading (deg)", String.num(rad_to_deg(_yaw), 2));
	DebugManager.update_property("Bank (deg)", String.num(rad_to_deg(_roll), 2));
	DebugManager.update_property("Pitch (deg)", String.num(rad_to_deg(_pitch), 2));
	DebugManager.update_property("Wing Bank (deg)", String.num(rad_to_deg(_wing_bank), 2));
	DebugManager.update_property("Wing Nose (deg)", String.num(rad_to_deg(_wing_nose), 2));
	DebugManager.update_property("~~_ BOOST _~~", "~~~~~~~~~~~~")
	DebugManager.update_property("Boost State", BoostState.keys()[_boost_state]);
	DebugManager.update_property("Boost Charge (%)", roundi(_charge * 100.0));
	DebugManager.update_property("Heat (%)", roundi(_heat * 100.0));
	DebugManager.update_property("~~_ INPUT _~~", "~~~~~~~~~~~~")
	DebugManager.update_property("Steer Input", input.steer);
	DebugManager.update_property("Accelerate Input", input.accelerate);
	DebugManager.update_property("Brake Input", input.brake);
	DebugManager.update_property("Pitch Input", input.pitch);
	


func _hover(delta, input):
	var grav_scale: float = 1.0
	if input.pitch > 0.0:
		grav_scale = lerp(1.0, gravity_mod_nose_up, input.pitch)
	elif input.pitch < 0.0:
		grav_scale = lerp(1.0, gravity_mod_nose_down, -input.pitch)
	velocity.y -= gravity * grav_scale * delta

	var max_upward: float = -999.0
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
	var turn_mult: float = 1.0
	if input.pitch > 0.0:
		turn_mult = lerp(1.0, nose_up_turn_multiplier, input.pitch)
	elif input.pitch < 0.0:
		turn_mult = lerp(1.0, nose_down_turn_multiplier, -input.pitch)
	var turn = -input.steer * max_turn_rate * turn_mult * delta
	_yaw += turn

	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	var forward_speed = velocity.dot(forward)
	var lat = velocity - forward * forward_speed

	var lat_target = right * input.steer * traction * turn_mult * delta
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

func _wing_tilt(delta, input):
	if not wing_left or not wing_right:
		return
	var roll_frac: float = 0.0
	if max_bank_angle > 0.0:
		roll_frac = clampf(_roll / deg_to_rad(max_bank_angle), -1.0, 1.0)
	var bank_target : float = roll_frac * deg_to_rad(wing_counter_tilt_deg)
	var nose_target : float = input.pitch * deg_to_rad(wing_nose_tilt_deg)
	_wing_bank = lerp(_wing_bank, bank_target, wing_tilt_speed * delta)
	_wing_nose = lerp(_wing_nose, nose_target, wing_tilt_speed * delta)
	wing_left.rotation = _wing_left_base + Vector3(_wing_nose, 0.0, _wing_bank)
	wing_right.rotation = _wing_right_base + Vector3(_wing_nose, 0.0, _wing_bank)

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
		var speed: float = velocity.length()
		if speed <= 0.001:
			continue
		var into_wall: float = maxf(-velocity.dot(normal), 0.0)
		var into_frac: float = into_wall / speed
		if into_frac <= 0.001:
			continue
		var head_on: float = clampf(-global_transform.basis.z.dot(normal), 0.0, 1.0)
		var angle_frac: float = 1.0 - acos(head_on) / deg_to_rad(90.0)
		var angle_factor: float = _curve_angle(angle_frac)
		var speed_frac: float = clampf(speed / max_speed, 0.0, 1.0)
		var penalty: float = lerp(wall_impact_loss, wall_brute_force_loss, speed_frac)
		velocity *= 1.0 - (penalty * angle_factor * into_frac)

func _curve_angle(x: float) -> float:
	match wall_angle_curve:
		WallAngleCurve.COSINE:
			return cos((1.0 - x) * deg_to_rad(90.0))
		WallAngleCurve.LINEAR:
			return x
		WallAngleCurve.QUADRATIC:
			return x * x
		WallAngleCurve.CUBIC:
			return x * x * x
		WallAngleCurve.SMOOTHSTEP:
			return x * x * (3.0 - 2.0 * x)
	return x
