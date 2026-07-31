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
## Hover altitude in meters — the distance the pod's raycasts try to hold above ground.[br][br]
## Intended purpose: the pod hovers on springs toward this height above the surface.[br][br]
## Higher = floats higher off the ground (clears bumps, more exposed); lower = rides closer to the track (lower center of gravity, more scraping risk).
@export var hover_height: float = 3.0
## Spring stiffness of the hover suspension — how hard the pod pushes back up toward hover_height when it is compressed toward the ground.[br][br]
## Intended purpose: controls how firmly the pod holds its hover altitude and recovers from dips.[br][br]
## Higher = stiffer, snappier recovery, less sag on fast sections; lower = softer, pod sinks and bounces through elevation changes.
@export var spring_stiffness: float = 8.0
## Spring damping of the hover suspension — how much vertical velocity is absorbed so the pod does not oscillate/bounce around hover_height.[br][br]
## Intended purpose: prevent hover bounce and smooth out landings.[br][br]
## Higher = heavily damped, planted, no bounce but slower to settle into drops; lower = bouncier, more lively ride but can oscillate up and down.
@export var spring_damping: float = 3.0

@export_category("Movement")
## Top forward speed in m/s reached when the accelerator is held at full input.[br][br]
## Intended purpose: defines the pod's base performance ceiling; the boost charge threshold and boost top speed are both derived as fractions/sums of this value.[br][br]
## Higher = faster pod at cruise AND a higher bar to reach before the boost gauge can charge (since the charge threshold is a fraction of max_speed); lower = slower pod, easier to charge.
@export var max_speed: float = 30.0
## Catch-up rate — how quickly current speed lerps toward the target speed each frame.[br][br]
## Intended purpose: sets how fast the pod recovers speed lost to turns, brakes, crashes, and standstill, and how quickly it climbs to (or past, during boost) max speed.[br][br]
## Higher = snappier acceleration, instant re-grip after corners; lower = floatier, sluggish pickup.
@export var acceleration_factor: float = 4.0
## Maximum yaw turn rate in radians/second at full steering input (no pitch modulation).[br][br]
## Intended purpose: controls how sharply the pod pivots on its vertical axis.[br][br]
## Higher = tighter, more aggressive corners; lower = wider turns, more understeer.
@export var max_turn_rate: float = 2.0
## Traction — how fast the pod's linear velocity realigns with its facing direction and how much lateral velocity is killed each frame.[br][br]
## Intended purpose: governs grip vs. drift. High traction = the pod turns where it points; low traction = the body slides sideways through turns (EP1R drift feel).[br][br]
## Higher = less drift, more planted corners; lower = more slide, floatier drift.
@export var traction: float = 8.0
## Braking power — how quickly braking bleeds forward speed toward zero each frame.[br][br]
## Intended purpose: controls stopping distance and how hard braking scrubs off speed.[br][br]
## Higher = shorter stopping distance, strong deceleration; lower = longer glide after braking.
@export var brake_deceleration: float = 8.0
## Turn-rate multiplier applied while the nose is pitched UP (pull back).[br][br]
## Intended purpose: reward pulling up mid-turn with sharper handling.[br][br]
## Higher = markedly tighter turns while nose up; 1.0 = no bonus; below 1.0 would turn it into a penalty.
@export var nose_up_turn_multiplier: float = 1.5
## Turn-rate multiplier applied while the nose is pitched DOWN (push forward).[br][br]
## Intended purpose: add a handling cost to diving (e.g. during boost charge), creating trade-off between nose-down charging and cornering.[br][br]
## Lower = weaker turning while nose down (dives sacrifice cornering); 1.0 = neutral; higher would make nose-down turns tighter.
@export var nose_down_turn_multiplier: float = 0.5

@export_category("Tilt")
## Maximum visual bank (roll) in degrees at full steering input and full speed.[br][br]
## Intended purpose: how far the pod leans into corners visually; scales with speed fraction so slow pods barely lean.[br][br]
## Higher = dramatic lean into turns; lower = more upright, subtle banking.
@export var max_bank_angle: float = 25.0
## How fast the pod's roll lerps toward its target bank each frame.[br][br]
## Intended purpose: response speed of the visual banking into and out of turns.[br][br]
## Higher = quicker, more aggressive lean-in and recovery; lower = lazier, laggier banking.
@export var bank_speed: float = 5.0
## Degrees of nose-down pitch added while the accelerator is held.[br][br]
## Intended purpose: make the pod visibly nose down when throttling, selling forward thrust.[br][br]
## Higher = stronger throttle-dive attitude; lower = flatter nose while accelerating.
@export var pitch_accel_angle: float = 3.0
## Degrees of nose-up pitch added while the brake is held.[br][br]
## Intended purpose: make the pod visibly nose up when braking, selling deceleration.[br][br]
## Higher = stronger brake-lift attitude; lower = flatter nose while braking.
@export var pitch_brake_angle: float = 5.0
## How fast pitch settles toward its target angle each frame.[br][br]
## Intended purpose: response speed of the pod's pitch attitude to input.[br][br]
## Higher = snappier pitch changes; lower = slower, floatier pitch.
@export var pitch_rate: float = 3.0
## Maximum degrees of nose pitch from manual pitch input at full stick deflection.[br][br]
## Intended purpose: the player-visible range of nose-up / nose-down attitude control.[br][br]
## Higher = wider pitch travel, more dramatic climbs/dives; lower = shallower, subtler pitch.
@export var manual_pitch_angle: float = 20.0
## Meters the turn-side (inside) wing drops DOWN in world space during an UNTILTED turn — applied to both wings. While tilted, both wings instead shift TOGETHER along the pod's local up/down (down-local = this value, up-local = wing_up_vert_travel).[br][br]
## Intended purpose: tunable wing-bob depth; upright, the wing on the inside of the turn drops this far while the opposite wing rises by wing_up_vert_travel — the differential mode.[br][br]
## Higher = deeper dive on the inside wing (upright) and a stronger down-local shift (tilted); lower = subtler. Set 0 to disable the downward motion entirely.
@export var wing_down_vert_travel: float = 1.0
## Meters the opposite (outside) wing rises UP in world space during an UNTILTED turn — applied to both wings. While tilted, both wings instead shift TOGETHER along the pod's local up/down (up-local = this value, down-local = wing_down_vert_travel).[br][br]
## Intended purpose: tunable wing-bob height; upright, the wing on the outside of the turn rises this far while the turn-side wing drops by wing_down_vert_travel — the differential mode.[br][br]
## Higher = taller rise on the outside wing (upright) and a stronger up-local shift (tilted); lower = subtler. Set 0 to disable the upward motion entirely.
@export var wing_up_vert_travel: float = 1.0
## Degrees the wings pitch to mirror the pod's nose attitude.[br][br]
## Intended purpose: keep the wing visual groups in sync with nose-up / nose-down motion.[br][br]
## Higher = wings tilt more with the nose; lower = wings stay more level.
@export var wing_nose_tilt_deg: float = 20.0
## How fast the wings lerp toward their target lift/tilt each frame.[br][br]
## Intended purpose: response speed of both the wing vertical shift and nose tilt.[br][br]
## Higher = wings snap into position; lower = wings lag and float toward position.
@export var wing_tilt_speed: float = 6.0
## Meters the chassis (Blade) body swings LATERALLY (left/right) in the pod's local frame during a turn — the chariot body swings further than the engines, which stay centered in view.[br][br]
## Intended purpose: sell the weight-shift of the body against the turn while the engines hold station; applied to the Blade visual node only.[br][br]
## Higher = more dramatic body whip to the outside of the turn; lower = subtler shift. Set 0 to disable chassis sway entirely.
@export var chassis_sway_travel: float = 1.5
## How fast the chassis body lerps toward its target lateral sway each frame.[br][br]
## Intended purpose: response speed of the body's weight-shift into and out of turns.[br][br]
## Higher = body snaps to the outside of the turn; lower = body floats slowly.
@export var chassis_sway_speed: float = 6.0
## Maximum degrees the pod rolls about its forward axis from the Ship Tilt input (right stick horizontal / Q / E) at full deflection.[br][br]
## Intended purpose: the 90-degree ship tilt used to thread narrow gaps; stacks on top of the steering bank so tilting while steering rolls further.[br][br]
## Higher = ship can roll further over (set to 90 for full wing-vertical clearance); lower = shallower tilt. Set 0 to disable the tilt ability.
@export var tilt_max_angle: float = 90.0
## How fast the pod's roll responds to the Ship Tilt input each frame.[br][br]
## Intended purpose: response speed of the deliberate 90-degree tilt, separate from the steering bank response (bank_speed).[br][br]
## Higher = tilt snaps to full roll quickly; lower = tilt takes longer to reach full roll.
@export var tilt_speed: float = 5.0

@export_category("Boost")
## Flat speed in m/s instantly added to velocity on boost activation.[br][br]
## Intended purpose: the immediate "kick" at the moment boost starts.[br][br]
## Higher = bigger instant surge; lower = gentler ramp into boost.
@export var boost_thrust: float = 15.0
## Speed bonus in m/s added ON TOP of max_speed as the acceleration target while boosting.[br][br]
## Intended purpose: the boost top speed is additive (max_speed + boost_speed_bonus), so boosts stay proportionally meaningful regardless of the pod's base speed.[br][br]
## Higher = faster boost top speed (bigger gap over cruise); lower = boost barely exceeds normal max speed. Must be > 0 to be faster than cruising.
@export var boost_speed_bonus: float = 50.0
## Heat units gained per second while boosting (heat goes 0 → 1, 1 = overheat).[br][br]
## Intended purpose: how long a boost lasts before forcing overheat.[br][br]
## Higher = boost overheats faster (shorter bursts); lower = longer sustained boost.
@export var heat_rate: float = 1.0
## Heat units drained per second whenever the pod is NOT boosting (cooldown).[br][br]
## Intended purpose: how quickly heat recovers so the pod can boost again.[br][br]
## Higher = faster cooldown, boost available sooner; lower = longer heat downtime.
@export var cool_rate: float = 1.0
## Fraction of max_speed the pod must be moving at for the boost gauge to charge.[br][br]
## Intended purpose: gate charging behind speed, matching EP1R's "boost only at/near max speed".[br][br]
## Higher = must be closer to top speed to charge (harder, more exclusive); lower = gauge fills even at moderate speeds.
@export var min_charge_speed_fraction: float = 0.8
## If speed drops below this fraction of max_speed WHILE boosting, boost ends early.[br][br]
## Intended purpose: a massive speed loss (collision, hard slowdown) should kill the boost.[br][br]
## Higher = boost is fragile, any speed drop cuts it short; lower = boost survives harder slowdowns. 0 = never ends from speed loss.
@export var boost_end_speed_fraction: float = 0.5
## Multiplier applied to yaw turn rate while boost is active (1.0 = no change, 0.5 = half turn rate).[br][br]
## Intended purpose: boosting costs agility — you commit to a fast, straight-ish line, so the pod turns sluggishly during boost (the EP1R "handling loss" tradeoff).[br][br]
## Higher = boost barely affects steering (agile); lower = boost makes the pod much harder to steer (committed, risky).
@export var boost_turn_rate_penalty: float = 0.5

@export_category("Boost — Charge Thresholds")
## How fast the boost gauge fills (charge units per second) while forward is held and the pod is above the charge speed threshold.[br][br]
## Intended purpose: tune the time it takes to prime a boost.[br][br]
## Higher = gauge fills faster, shorter charge time; lower = longer, more committed charge before boost becomes available.
@export var charge_rate: float = 1.0
## How far (in degrees) the stick may sway off full-forward while still counting as boost charging.[br][br]
## Intended purpose: charging must be a committed straight-line action — the stick has to be basically completely up (nose down), so you can't charge while steering/turning. The threshold converts degrees to a pitch magnitude via cos(deg): 10° ≈ 0.985 full deflection, 5° ≈ 0.996.[br][br]
## Higher = more forgiving (charge while the stick is up to that many degrees off straight-forward); lower = stricter (only near-perfect full-forward counts — recommended so turning out of the charge window).
@export var charge_pitch_deadzone_deg: float = 10.0

@export_category("Gravity")
@export var gravity: float = 25.0
@export var gravity_mod_nose_up: float = 0.5
@export var gravity_mod_nose_down: float = 1.6

@export_category("Collision")
## Fraction of velocity lost on a glancing wall hit at LOW speed.[br][br]
## Intended purpose: the penalty applied for grazing/scraping along a wall; blends toward wall_brute_force_loss as speed rises.[br][br]
## Higher = shallow clips cost more speed; lower = soft scrapes barely slow you.
@export var wall_impact_loss: float = 0.7
## Fraction of velocity lost on a HIGH-speed (brute-force) wall hit.[br][br]
## Intended purpose: the speed-loss penalty when smashing into a wall at top speed; blends toward this from wall_impact_loss as speed fraction rises.[br][br]
## Higher = fast crashes lose more speed (harder punishment); lower = high-speed hits keep most of their momentum.
@export var wall_brute_force_loss: float = 0.15
## Curve that maps impact angle to the wall-penalty factor. x = angle fraction (0 = grazing side-scrape, 1 = dead-on nose hit).[br][br]
## Intended purpose: choose how forgiving wall scrapes are based on impact angle.[br][br]
## COSINE hits hard even on shallow clips; CUBIC barely touches you until near-perfect head-ons; SMOOTHSTEP has a soft shoulder then snaps to full near dead-on.
@export var wall_angle_curve: WallAngleCurve = WallAngleCurve.COSINE

@export_category("Node References")
## Raycasts used to measure the ground distance for the hover springs.[br][br]
## Intended purpose: each ray samples terrain height under the pod; the highest correction among colliding rays drives the hover spring.[br][br]
## More/appropriately placed rays = more stable hovering over uneven terrain; rays too far apart or mis-aimed = the pod reads bumps and ditches poorly.
@export var hover_raycasts: Array[RayCast3D] = []
## Node the camera rig follows / is attached to on the pod.[br][br]
## Intended purpose: anchor point for the follow camera so it tracks pod position and rotation cleanly.
@export var camera_mount: Node3D
@onready var wing_left: Node3D = %Wing_Left
@onready var wing_right: Node3D = %Wing_Right
@onready var blade: Node3D = $Visuals/Blade
@onready var pcam_noise_emitter: PhantomCameraNoiseEmitter3D = $CameraMount/PhantomCameraNoiseEmitter3D

enum BoostState { NORMAL, CHARGING, READY, BOOSTING, OVERHEAT }
enum BoostLight { OFF, GREEN, YELLOW, RED }

var _boost_state: int = BoostState.NORMAL
var _charge: float = 0.0
var _heat: float = 0.0
var _current_speed: float = 0.0
var _yaw: float = 0.0
var _pitch: float = 0.0
var _roll: float = 0.0
var _tilt_roll: float = 0.0
var _wing_left_base_rot: Vector3
var _wing_right_base_rot: Vector3
var _wing_left_base_pos: Vector3
var _wing_right_base_pos: Vector3
var _wing_left_lift: float = 0.0
var _wing_right_lift: float = 0.0
var _wing_nose: float = 0.0
var _blade_base_pos: Vector3
var _chassis_sway_amount: float = 0.0

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
		_wing_left_base_rot = wing_left.rotation
		_wing_left_base_pos = wing_left.position
	if wing_right:
		_wing_right_base_rot = wing_right.rotation
		_wing_right_base_pos = wing_right.position
	if blade:
		_blade_base_pos = blade.position

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
	_chassis_sway(delta, input)
	rotation = Vector3(0.0, _yaw, _roll + _tilt_roll)
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
	DebugManager.update_property("Wing Left Lift (m)", String.num(_wing_left_lift, 2));
	DebugManager.update_property("Wing Right Lift (m)", String.num(_wing_right_lift, 2));
	DebugManager.update_property("Chassis Sway (m)", String.num(_chassis_sway_amount, 2));
	DebugManager.update_property("~~_ BOOST _~~", "~~~~~~~~~~~~")
	DebugManager.update_property("Boost State", BoostState.keys()[_boost_state]);
	DebugManager.update_property("Boost Charge (%)", roundi(_charge * 100.0));
	DebugManager.update_property("Heat (%)", roundi(_heat * 100.0));
	DebugManager.update_property("~~_ INPUT _~~", "~~~~~~~~~~~~")
	DebugManager.update_property("Steer Input", input.steer);
	DebugManager.update_property("Accelerate Input", input.accelerate);
	DebugManager.update_property("Brake Input", input.brake);
	DebugManager.update_property("Pitch Input", input.pitch);
	DebugManager.update_property("Tilt Input", input.tilt);
	DebugManager.update_property("Tilt Roll (deg)", String.num(rad_to_deg(_tilt_roll), 2));
	


func _hover(delta, input):
	var grounded: bool = false
	var max_upward: float = -999.0
	for ray in hover_raycasts:
		if not ray.is_colliding():
			continue
		var point = ray.get_collision_point()
		var dist = ray.global_position.distance_to(point)
		var compression = hover_height - dist
		if compression <= 0.0:
			continue
		grounded = true
		var correction = compression * spring_stiffness - velocity.y * spring_damping
		if correction > max_upward:
			max_upward = correction

	var grav_scale: float = 1.0
	if not grounded:
		if input.pitch > 0.0:
			grav_scale = lerp(1.0, gravity_mod_nose_up, input.pitch)
		elif input.pitch < 0.0:
			grav_scale = lerp(1.0, gravity_mod_nose_down, -input.pitch)
	velocity.y -= gravity * grav_scale * delta

	if max_upward > -999.0:
		if max_upward > velocity.y:
			velocity.y = lerp(velocity.y, max_upward, 4.0 * delta)

func _accelerate(delta, input):
	if input.accelerate <= 0.0:
		return

	var target = max_speed
	if _boost_state == BoostState.BOOSTING:
		target = max_speed + boost_speed_bonus

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
	var boost_turn_mult: float = 1.0
	if _boost_state == BoostState.BOOSTING:
		boost_turn_mult = boost_turn_rate_penalty
	var turn = -input.steer * max_turn_rate * turn_mult * boost_turn_mult * delta
	_yaw += turn

	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	var forward_speed = velocity.dot(forward)
	var lat = velocity - forward * forward_speed
	var lat_target = right * input.steer * traction * turn_mult * boost_turn_mult * delta
	velocity -= lat * min(1.0, traction * delta)
	velocity += lat_target

func _tilt(delta, input):
	var speed_frac = clampf(_current_speed / max_speed, 0.0, 1.0) if max_speed > 0.0 else 0.0
	var target_roll = -input.steer * deg_to_rad(max_bank_angle) * speed_frac
	_roll = lerp(_roll, target_roll, bank_speed * delta)

	var target_tilt_roll = -input.tilt * deg_to_rad(tilt_max_angle)
	_tilt_roll = lerp(_tilt_roll, target_tilt_roll, tilt_speed * delta)

	var target_pitch = input.pitch * deg_to_rad(manual_pitch_angle)
	target_pitch += input.accelerate * deg_to_rad(pitch_accel_angle)
	target_pitch -= input.brake * deg_to_rad(pitch_brake_angle)
	_pitch = lerp(_pitch, target_pitch, pitch_rate * delta)

func _chassis_sway(delta, input):
	if not blade:
		return
	var speed_frac = clampf(_current_speed / max_speed, 0.0, 1.0) if max_speed > 0.0 else 0.0
	var sway_target = -input.steer * chassis_sway_travel * speed_frac
	_chassis_sway_amount = lerp(_chassis_sway_amount, sway_target, chassis_sway_speed * delta)
	blade.position = _blade_base_pos + Vector3(_chassis_sway_amount, 0.0, 0.0)

func _wing_tilt(delta, input):
	if not wing_left or not wing_right:
		return
	var speed_frac: float = clampf(_current_speed / max_speed, 0.0, 1.0) if max_speed > 0.0 else 0.0
	var turn_intensity: float = input.steer * speed_frac

	_wing_nose = lerp(_wing_nose, input.pitch * deg_to_rad(wing_nose_tilt_deg), wing_tilt_speed * delta)

	var up: float = abs(turn_intensity) * wing_up_vert_travel
	var down: float = -abs(turn_intensity) * wing_down_vert_travel
	if turn_intensity >= 0.0:
		_wing_left_lift = lerp(_wing_left_lift, up, wing_tilt_speed * delta)
		_wing_right_lift = lerp(_wing_right_lift, down, wing_tilt_speed * delta)
	else:
		_wing_left_lift = lerp(_wing_left_lift, down, wing_tilt_speed * delta)
		_wing_right_lift = lerp(_wing_right_lift, up, wing_tilt_speed * delta)

	var tilt_mix: float = clampf(abs(input.tilt), 0.0, 1.0)
	var together_world: Vector3 = Vector3.ZERO
	if tilt_mix > 0.0 and abs(input.steer) > 0.0001:
		var pod_right: Vector3 = global_transform.basis.x
		var horizontal: Vector3 = Vector3(pod_right.x, 0.0, pod_right.z)
		if horizontal.length() < 0.001:
			horizontal = Vector3.RIGHT
		var world_turn: Vector3 = horizontal.normalized() * signf(input.steer)
		var local_turn: Vector3 = global_transform.basis.inverse() * world_turn
		var together_dir: float = 1.0 if local_turn.y >= 0.0 else -1.0
		var together_mag: float = abs(turn_intensity) * (wing_up_vert_travel if together_dir > 0.0 else wing_down_vert_travel)
		together_world = global_transform.basis.y * (together_dir * together_mag)

	var diff_left_world: Vector3 = Vector3(0.0, _wing_left_lift, 0.0)
	var diff_right_world: Vector3 = Vector3(0.0, _wing_right_lift, 0.0)
	wing_left.rotation = _wing_left_base_rot + Vector3(_wing_nose, 0.0, 0.0)
	wing_right.rotation = _wing_right_base_rot + Vector3(_wing_nose, 0.0, 0.0)
	wing_left.position = _wing_left_base_pos + _world_offset(diff_left_world.lerp(together_world, tilt_mix), wing_left)
	wing_right.position = _wing_right_base_pos + _world_offset(diff_right_world.lerp(together_world, tilt_mix), wing_right)

func _world_offset(world_vec: Vector3, wing: Node3D) -> Vector3:
	if world_vec == Vector3.ZERO:
		return Vector3.ZERO
	var parent: Node3D = wing.get_parent()
	return parent.global_transform.affine_inverse().basis * world_vec

# TODO(mechanical-opening): Provisional per-wing mechanical opening infrastructure.
# When turn rate rises, fins/vents/wings open; they hold while the turn is held and decay
# back to closed when the stick returns to neutral. Each part tracks its own openness.
# Independent of the wing vertical shift above. Uncomment when the visual parts exist.
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
		BoostState.NORMAL:
			_normal_boost(delta, input)
		BoostState.CHARGING:
			_cool_heat(delta)
			_charge_boost(delta, input)
		BoostState.READY:
			_ready_boost(delta, input)
		BoostState.BOOSTING:
			_boost_update(delta, input)
		BoostState.OVERHEAT:
			_cool_after_overheat(delta)

func _speed_fraction() -> float:
	return _current_speed / max_speed if max_speed > 0 else 0.0

func _normal_boost(delta, input):
	_cool_heat(delta)
	if _charging_input(input) and _speed_fraction() >= min_charge_speed_fraction:
		_boost_state = BoostState.CHARGING

func _charge_boost(delta, input):
	if not _charging_input(input) or _speed_fraction() < min_charge_speed_fraction:
		_charge = 0.0
		_boost_state = BoostState.NORMAL
		return
	_charge += charge_rate * abs(input.pitch) * delta
	_charge = min(_charge, 1.0)
	if _charge >= 1.0:
		_boost_state = BoostState.READY

func _charging_input(input) -> bool:
	if input.pitch >= 0.0:
		return false
	var full: float = cos(deg_to_rad(charge_pitch_deadzone_deg))
	return -input.pitch >= full

func _cool_heat(delta):
	if _heat <= 0.0:
		return
	_heat = max(_heat - cool_rate * delta, 0.0)

func _ready_boost(delta, input):
	if not _charging_input(input) or _speed_fraction() < min_charge_speed_fraction:
		_charge = 0.0
		_boost_state = BoostState.NORMAL
		return
	_cool_heat(delta)
	if input.boost_just_pressed:
		_start_boost()

func _start_boost():
	_boost_state = BoostState.BOOSTING
	_heat = 0.0
	_charge = 0.0
	velocity += -global_transform.basis.z * boost_thrust

func _boost_update(delta, input):
	_heat += heat_rate * delta
	if _heat >= 1.0:
		_overheat()
		return
	if not input.accelerate or input.brake > 0.0:
		_end_boost()
		return
	if _current_speed < max_speed * boost_end_speed_fraction:
		_end_boost()

func _overheat():
	_boost_state = BoostState.OVERHEAT

func _end_boost():
	_boost_state = BoostState.NORMAL
	_charge = 0.0
	_heat = max(_heat, 0.1)

func _cool_after_overheat(delta):
	_heat -= cool_rate * delta
	_heat = max(_heat, 0.0)
	if _heat <= 0.0:
		_boost_state = BoostState.NORMAL
		_charge = 0.0

func get_boost_light() -> BoostLight:
	match _boost_state:
		BoostState.BOOSTING:
			return BoostLight.RED
		BoostState.READY:
			return BoostLight.YELLOW
		BoostState.CHARGING:
			return BoostLight.GREEN
	return BoostLight.OFF

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
