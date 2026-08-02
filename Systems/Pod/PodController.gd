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
@export var hover_height : float = 3.0
## Spring stiffness of the hover suspension — how hard the pod pushes back up toward hover_height when it is compressed toward the ground.[br][br]
## Intended purpose: controls how firmly the pod holds its hover altitude and recovers from dips.[br][br]
## Higher = stiffer, snappier recovery, less sag on fast sections; lower = softer, pod sinks and bounces through elevation changes.
@export var spring_stiffness : float = 8.0
## Spring damping of the hover suspension — how much vertical velocity is absorbed so the pod does not oscillate/bounce around hover_height.[br][br]
## Intended purpose: prevent hover bounce and smooth out landings.[br][br]
## Higher = heavily damped, planted, no bounce but slower to settle into drops; lower = bouncier, more lively ride but can oscillate up and down.
@export var spring_damping : float = 3.0
## Hysteresis band in meters ABOVE hover_height within which the pod is still treated as grounded while it bobs through its hover altitude.[br][br]
## Intended purpose: keep the grounded flag latched during normal hover bounce. Without a band, grounded drops the moment the pod passes hover_height, which flicks the pod into "airborne" arc pitch (nose-up while climbing) — that nose-up tilts the forward thrust vector upward, so the pod climbs and flies away in a runaway feedback loop.[br][br]
## Higher = pod stays grounded longer as it rises (more stable hover, arc pitch only on real launches); lower = grounded drops sooner past hover_height (more arc pitch during hover, livelier but risks the climb-away).
@export var grounded_band : float = 1.5
## Perpetual idle hover-bob amplitude in meters — the hover target height oscillates around hover_height by this amount, so the springs never fully settle to a dead stop.[br][br]
## Intended purpose: EP1R pods always hover-bounce a little at idle (the springs are alive, not locked at rest). This drives the hover target sinusoidally with a per-corner phase so the pod keeps riding its springs instead of locking to a standstill.[br][br]
## Higher = more visible idle bob (more suspension travel); 0 = springs settle to a dead rest.
@export var idle_bob_amplitude : float = 0.15
## Idle hover-bob frequency in Hz (cycles per second) for the perpetual idle bounce.[br][br]
## Intended purpose: the pace of the idle bob — how fast the pod rides its springs while standing still.[br][br]
## Higher = faster, tighter bob; lower = slower, more floaty lope.
@export var idle_bob_frequency : float = 2.0
## Visual idle-bob amplitude in meters applied to the chassis (Blade) and engines (wings) independently, on top of the physics bob — the parts ride their own sine, out of phase with each other.[br][br]
## Intended purpose: EP1R's chassis and engines idle-bob independently (the engines drag the blade through the rigs, they are not one rigid block). With the chassis bobbed on one sine and both engines on an opposite-phase sine, the pod reads as separate suspended masses even at idle.[br][br]
## Higher = more dramatic independent part bob; 0 = parts track the body rigidly.
@export var idle_part_bob_amplitude : float = 0.04

@export_category("Debug")
## How much hover_height changes per press of the in-game debug hover-height keys (Debug_IncreaseHoverHeight = Ctrl+=, Debug_DecreaseHoverHeight = Ctrl+-), in meters.[br][br]
## Intended purpose: tune hover feel live while driving. The new value is written to hover_height immediately, so the springs re-target on the next physics frame.[br][br]
## Higher = bigger jumps per keypress (coarse tuning); lower = finer, smaller steps.
@export var debug_hover_step : float = 0.5

@export_category("Movement")
## Top forward speed in m/s reached when the accelerator is held at full input.[br][br]
## Intended purpose: defines the pod's base performance ceiling; the boost charge threshold and boost top speed are both derived as fractions/sums of this value.[br][br]
## Higher = faster pod at cruise AND a higher bar to reach before the boost gauge can charge (since the charge threshold is a fraction of max_speed); lower = slower pod, easier to charge.
@export var max_speed : float = 30.0
## Catch-up rate — how quickly current speed lerps toward the target speed each frame.[br][br]
## Intended purpose: sets how fast the pod recovers speed lost to turns, brakes, crashes, and standstill, and how quickly it climbs to (or past, during boost) max speed.[br][br]
## Higher = snappier acceleration, instant re-grip after corners; lower = floatier, sluggish pickup.
@export var acceleration_factor : float = 4.0
## Maximum yaw turn rate in radians/second at full steering input (no pitch modulation).[br][br]
## Intended purpose: controls how sharply the pod pivots on its vertical axis.[br][br]
## Higher = tighter, more aggressive corners; lower = wider turns, more understeer.
@export var max_turn_rate : float = 2.0
## How quickly the pod's actual yaw rate ramps up toward max_turn_rate after steering input, in radians/second of rate-ramp per unit of steer — the turn response stat.[br][br]
## Intended purpose: separates "how steep the turn can be" (max_turn_rate) from "how fast the pod reaches that turn rate" (this). Without this, steering applies full max_turn_rate instantly, so even a standstill tap whips the nose around. Higher = snappier, more touchy steering (reaches max turn rate sooner); lower = sluggish, floatier turn-in.[br][br]
## Implemented as a per-frame lerp rate on a persistent _yaw_rate state, so the yaw smoothly accelerates into the turn and smooths back to zero on release.
@export var turn_response : float = 4.0
## Traction — how fast the pod's linear velocity realigns with its facing direction and how much lateral velocity is killed each frame.[br][br]
## Intended purpose: governs grip vs. drift. High traction = the pod turns where it points; low traction = the body slides sideways through turns (EP1R drift feel).[br][br]
## Higher = less drift, more planted corners; lower = more slide, floatier drift.
@export var traction : float = 8.0
## Braking power — how quickly braking bleeds forward speed toward zero each frame.[br][br]
## Intended purpose: controls stopping distance and how hard braking scrubs off speed.[br][br]
## Higher = shorter stopping distance, strong deceleration; lower = longer glide after braking.
@export var brake_deceleration : float = 8.0
## Turn-rate multiplier applied while the nose is pitched UP (pull back).[br][br]
## Intended purpose: reward pulling up mid-turn with sharper handling.[br][br]
## Higher = markedly tighter turns while nose up; 1.0 = no bonus; below 1.0 would turn it into a penalty.
@export var nose_up_turn_multiplier : float = 1.5
## Turn-rate multiplier applied while the nose is pitched DOWN (push forward).[br][br]
## Intended purpose: add a handling cost to diving (e.g. during boost charge), creating trade-off between nose-down charging and cornering.[br][br]
## Lower = weaker turning while nose down (dives sacrifice cornering); 1.0 = neutral; higher would make nose-down turns tighter.
@export var nose_down_turn_multiplier : float = 0.5

@export_category("Attitude")
## Maximum visual bank (roll) in degrees at full steering input and full speed.[br][br]
## Intended purpose: how far the pod leans into corners visually; scales with speed fraction so slow pods barely lean.[br][br]
## Higher = dramatic lean into turns; lower = more upright, subtle banking.
@export var max_bank_angle : float = 25.0
## How fast the pod's roll lerps toward its target bank each frame.[br][br]
## Intended purpose: response speed of the visual banking into and out of turns.[br][br]
## Higher = quicker, more aggressive lean-in and recovery; lower = lazier, laggier banking.
@export var bank_speed : float = 5.0
## Maximum degrees the pod rolls about its forward axis from the Ship Tilt input (right stick horizontal / Q / E) at full deflection.[br][br]
## Intended purpose: the whole pod (chassis + wings) rolls together about its own center axis — the classic knife-edge pass — so at full tilt the chassis sits centered between the two wings, tilted onto its side and still hovering.[br][br]
## Higher = ship can roll further over (set to 90 for full wing-vertical clearance); lower = shallower tilt. Set 0 to disable the tilt ability.
@export var tilt_max_angle : float = 90.0
## How fast the pod's roll responds to the Ship Tilt input each frame.[br][br]
## Intended purpose: response speed of the deliberate 90-degree tilt, separate from the steering bank response (bank_speed).[br][br]
## Higher = tilt snaps to full roll quickly; lower = tilt takes longer to reach full roll.
@export var tilt_speed : float = 5.0
## Multiplier applied to yaw turn rate while the pod is tilted (1.0 = no change, 0.5 = half turn rate).[br][br]
## Intended purpose: matching the boost penalty, a committed 90-degree tilt costs agility — the pod turns sluggishly while rolled over, so you commit to the knife-edge line (the EP1R "handling loss" tradeoff). Scales with how far the tilt has actually rolled.[br][br]
## Higher = tilt barely affects steering (agile); lower = tilt makes the pod much harder to steer (committed, risky).
@export var tilt_turn_rate_penalty : float = 0.5
## Fraction (0–1) of max speed the pod must be moving at before the Ship Tilt input is allowed.[br][br]
## Intended purpose: the 90-degree tilt is a high-speed maneuver — below this speed the pod won't roll over, keeping low-speed handling stable.[br][br]
## Higher = tilt locks until the pod is faster; lower = tilt unlocks at lower speeds (0 = always available).
@export var tilt_min_speed_fraction : float = 0.5
## Maximum degrees of nose pitch from manual pitch input at full stick deflection.[br][br]
## Intended purpose: the player-visible nose-up / nose-down attitude control. While grounded it does NOT rotate the pod body — it rotates the wings and chassis in place (see wing_nose_tilt_deg); airborne it pitches the whole pod for climbs/dives.[br][br]
## Higher = wider pitch travel, more dramatic climbs/dives; lower = shallower, subtler pitch.
@export var manual_pitch_angle : float = 20.0
## How fast pitch settles toward its target angle each frame.[br][br]
## Intended purpose: response speed of the pod's pitch attitude to input.[br][br]
## Higher = snappier pitch changes; lower = slower, floatier pitch.
@export var pitch_rate : float = 3.0
## Degrees of nose-down pitch added while the accelerator is held.[br][br]
## Intended purpose: make the pod visibly nose down when throttling, selling forward thrust.[br][br]
## Higher = stronger throttle-dive attitude; lower = flatter nose while accelerating.
@export var pitch_accel_angle : float = 3.0
## Degrees of nose-up pitch added while the brake is held.[br][br]
## Intended purpose: make the pod visibly nose up when braking, selling deceleration.[br][br]
## Higher = stronger brake-lift attitude; lower = flatter nose while braking.
@export var pitch_brake_angle : float = 5.0
## Cap on the TOTAL body pitch (terrain/arc alignment + manual pitch input), in degrees.[br][br]
## Intended purpose: guarantee the pod never tips past a sane attitude regardless of how slope and input stack.[br][br]
## Higher = more extreme combined pitch allowed; lower = keeps the body closer to level.
@export var max_pitch_angle : float = 50.0
## m/s the cruise speed target shifts at full nose-down (+gain) / nose-up (−gain), stacked on top of max_speed and boost.[br][br]
## Intended purpose: give the nose attitude a real speed tradeoff — diving (nose down) raises cruising speed, climbing (nose up) bleeds it, scaled by how far the nose is pitched.[br][br]
## Higher = nose-down is a bigger speed boost and nose-up a bigger slow-down; lower = subtler.
@export var pitch_speed_gain : float = 15.0
## Fractional change to the acceleration factor at full nose-down (+gain) / nose-up (−gain): nose-down accelerates harder, nose-up accelerates more sluggishly.[br][br]
## Intended purpose: layer the speed change onto thrust so pitch is felt as acceleration, not just a retargeted cruise speed.[br][br]
## Higher = stronger acceleration swing with pitch; lower = gentler.
@export var pitch_accel_gain : float = 0.15
## Maximum degrees the wings and chassis (Blade) rotate IN PLACE to show nose-up / nose-down input while grounded — the pod body itself does not pitch.[br][br]
## Intended purpose: the visible nose attitude the player gets from pitch input when grounded, applied to the wing and chassis visuals (fades out while tilted). This is separate from wing_nose_tilt_deg, which is the airborne counter-pitch that holds the wings level with the horizon.[br][br]
## Higher = more dramatic in-place nose tilt on the wings/chassis; lower = subtler.
@export var visual_nose_deg : float = 20.0

@export_category("Terrain & Arc Pitch")
## Fraction (0–1) of the ground slope the pod's body pitches to follow while grounded (any hover ray compressing).[br][br]
## Intended purpose: climbing a ramp tilts the pod's nose up to match the ground normal beneath it — the whole pod pitches, not just the wings.[br][br]
## Higher = nose tracks the slope steeply; lower = shallower, calmer body pitch. Set 0 to disable terrain-following pitch.
@export var terrain_pitch_align : float = 1.0
## Degrees of body pitch added per m/s of vertical speed while airborne (climbing pitches the nose up, diving pitches it down, level at the apex of an arc).[br][br]
## Intended purpose: make the pod visibly nose-down as it falls faster, nose-up while climbing, and level out at the peak of a jump before starting the dive.[br][br]
## Higher = more dramatic arc pitch (nose dives sharply on fast falls); lower = subtler.
@export var arc_pitch_gain : float = 1.5
## Cap on the terrain/arc body-pitch contribution, in degrees.[br][br]
## Intended purpose: keep the pod from pitching past a readable envelope on steep slopes or fast vertical falls.[br][br]
## Higher = allows steeper body pitch; lower = flatter, more restrained.
@export var arc_pitch_max_deg : float = 35.0

@export_category("Wing Motion")
## Meters the turn-side (inside) wing drops DOWN in world space during an UNTILTED turn — the differential mode (one wing down, the other up). While tilted, the wing shift fades out entirely so the wings only rotate in place with the pod.[br][br]
## Intended purpose: tunable wing-bob depth; upright, the wing on the inside of the turn drops this far while the opposite wing rises by wing_up_vert_travel.[br][br]
## Higher = deeper dive on the inside wing (upright); lower = subtler. Set 0 to disable the downward motion entirely.
@export var wing_down_vert_travel : float = 1.0
## Meters the opposite (outside) wing rises UP in world space during an UNTILTED turn — the differential mode (one wing up, the other down). While tilted, the wing shift fades out entirely so the wings only rotate in place with the pod.[br][br]
## Intended purpose: tunable wing-bob height; upright, the wing on the outside of the turn rises this far while the turn-side wing drops by wing_down_vert_travel.[br][br]
## Higher = taller rise on the outside wing (upright); lower = subtler. Set 0 to disable the upward motion entirely.
@export var wing_up_vert_travel : float = 1.0
## Maximum degrees the wings pitch to hold level with the world horizon as the pod's nose pitches (nose pulled up counter-pitches the wings so they keep tilting toward world up).[br][br]
## Intended purpose: once in the tilted state the wings stay put in every way except rotation — their only motion is this counter-pitch, keeping the wing faces level with the world instead of mirroring the body's nose attitude.[br][br]
## Higher = wings counter-pitch further as the nose pitches (stay more level); lower = wings share more of the body's pitch.
@export var wing_nose_tilt_deg : float = 20.0
## How fast the wings lerp toward their target lift/tilt each frame.[br][br]
## Intended purpose: response speed of both the wing vertical shift and nose tilt.[br][br]
## Higher = wings snap into position; lower = wings lag and float toward position.
@export var wing_tilt_speed : float = 6.0

@export_category("Chassis Sway")
## Meters the chassis (Blade) body swings LATERALLY (left/right) during a turn — the chariot body swings further than the engines, which stay centered in view.[br][br]
## Intended purpose: sell the weight-shift of the body against the turn while the engines hold station; applied to the Blade visual node only. While the pod is tilted, the same turn-driven shift redirects to the pod's up/down axis (read as left/right in world once rolled over) so the chassis moves with the tilt turn instead of fighting it.[br][br]
## Higher = more dramatic body whip to the outside of the turn; lower = subtler shift. Set 0 to disable chassis sway entirely.
@export var chassis_sway_travel : float = 1.5
## How fast the chassis body lerps toward its target lateral sway each frame.[br][br]
## Intended purpose: response speed of the body's weight-shift into and out of turns.[br][br]
## Higher = body snaps to the outside of the turn; lower = body floats slowly.
@export var chassis_sway_speed : float = 6.0
## Degrees the chassis (Blade) body barrel-rolls about its forward (local Z) axis at full sway, so the sway reads as a full-body weight shift instead of a flat slide.[br][br]
## Intended purpose: add a roll component to the chassis sway — the body twists about its own axis as it swings out in a turn.[br][br]
## Higher = more dramatic barrel roll in hard turns; lower = subtler twist. Set 0 to disable the roll (sway stays a pure lateral slide).
@export var chassis_sway_roll_deg : float = 12.0

@export_category("Camera")
## Fraction (0–1) of the pod's total roll (steering bank + ship tilt) that the camera mount counter-rotates.[br][br]
## Intended purpose: counter-roll keeps the chase camera upright and stops the world from "orbiting" around the pod during a 90° ship tilt — the pod visibly tilts in frame while the horizon stays level.[br][br]
## Higher = camera stays more level (1.0 = pod appears to roll fully against a level camera); lower = camera rolls more with the pod.
@export var camera_roll_counter : float = 1.0
## Fraction (0–1) of the ship-tilt roll the camera turns WITH the pod, on top of camera_roll_counter's leveling.[br][br]
## Intended purpose: the tilt turn should feel like a coordinated turn, not a level roll — the camera shares 30–50% of the tilt so the world tilts a little with you, selling the bank.[br][br]
## Higher = camera rolls further with the tilt (world visibly tilts); 0 = camera stays fully level (pure counter-roll).
@export var camera_tilt_follow : float = 0.4

@export_category("Boost")
## Flat speed in m/s instantly added to velocity on boost activation.[br][br]
## Intended purpose: the immediate "kick" at the moment boost starts.[br][br]
## Higher = bigger instant surge; lower = gentler ramp into boost.
@export var boost_thrust : float = 15.0
## Speed bonus in m/s added ON TOP of max_speed as the acceleration target while boosting.[br][br]
## Intended purpose: the boost top speed is additive (max_speed + boost_speed_bonus), so boosts stay proportionally meaningful regardless of the pod's base speed.[br][br]
## Higher = faster boost top speed (bigger gap over cruise); lower = boost barely exceeds normal max speed. Must be > 0 to be faster than cruising.
@export var boost_speed_bonus : float = 50.0
## Heat units gained per second while boosting (heat goes 0 → 1, 1 = overheat).[br][br]
## Intended purpose: how long a boost lasts before forcing overheat.[br][br]
## Higher = boost overheats faster (shorter bursts); lower = longer sustained boost.
@export var heat_rate : float = 1.0
## Heat units drained per second whenever the pod is NOT boosting (cooldown).[br][br]
## Intended purpose: how quickly heat recovers so the pod can boost again.[br][br]
## Higher = faster cooldown, boost available sooner; lower = longer heat downtime.
@export var cool_rate : float = 1.0
## Fraction of max_speed the pod must be moving at for the boost gauge to charge.[br][br]
## Intended purpose: gate charging behind speed, matching EP1R's "boost only at/near max speed".[br][br]
## Higher = must be closer to top speed to charge (harder, more exclusive); lower = gauge fills even at moderate speeds.
@export var min_charge_speed_fraction : float = 0.8
## If speed drops below this fraction of max_speed WHILE boosting, boost ends early.[br][br]
## Intended purpose: a massive speed loss (collision, hard slowdown) should kill the boost.[br][br]
## Higher = boost is fragile, any speed drop cuts it short; lower = boost survives harder slowdowns. 0 = never ends from speed loss.
@export var boost_end_speed_fraction : float = 0.5
## Multiplier applied to yaw turn rate while boost is active (1.0 = no change, 0.5 = half turn rate).[br][br]
## Intended purpose: boosting costs agility — you commit to a fast, straight-ish line, so the pod turns sluggishly during boost (the EP1R "handling loss" tradeoff).[br][br]
## Higher = boost barely affects steering (agile); lower = boost makes the pod much harder to steer (committed, risky).
@export var boost_turn_rate_penalty : float = 0.5

@export_category("Boost — Charge Thresholds")
## How fast the boost gauge fills (charge units per second) while forward is held and the pod is above the charge speed threshold.[br][br]
## Intended purpose: tune the time it takes to prime a boost.[br][br]
## Higher = gauge fills faster, shorter charge time; lower = longer, more committed charge before boost becomes available.
@export var charge_rate : float = 1.0
## How far (in degrees) the stick may sway off full-forward while still counting as boost charging.[br][br]
## Intended purpose: charging must be a committed straight-line action — the stick has to be basically completely up (nose down), so you can't charge while steering/turning. The threshold converts degrees to a pitch magnitude via cos(deg): 10° ≈ 0.985 full deflection, 5° ≈ 0.996.[br][br]
## Higher = more forgiving (charge while the stick is up to that many degrees off straight-forward); lower = stricter (only near-perfect full-forward counts — recommended so turning out of the charge window).
@export var charge_pitch_deadzone_deg : float = 10.0

@export_category("Gravity")
## Base downward acceleration in m/s² applied every physics frame; the hover springs lift against it.[br][br]
## Intended purpose: the reference gravity that sets how hard the springs must push to hold hover height.[br][br]
## Higher = stronger pull to the ground (springs work harder); lower = floatier pod.
@export var gravity : float = 25.0
## Downward acceleration in m/s² applied when the pitch stick is held fully nose-up (fixed value, lighter than base gravity).[br][br]
## Intended purpose: holding nose-up reduces effective gravity so the pod floats up and lofts over crests — a fixed value rather than a multiplier so it stays predictable at any base gravity.[br][br]
## Higher = still heavy while nose-up (barely rises); lower = floats strongly nose-up (can launch off crests).
@export var gravity_nose_up : float = 20.0
## Downward acceleration in m/s² applied when the pitch stick is held fully nose-down (fixed value, heavier than base gravity).[br][br]
## Intended purpose: holding nose-down presses the pod toward the ground hard enough to sink the hover springs — this is what makes nose-down actually push you down, and it applies whether or not the pod is grounded.[br][br]
## Higher = dives/presses harder nose-down; lower = gentler descent.
@export var gravity_nose_down : float = 120.0

@export_category("Collision")
## Fraction of velocity lost on a glancing wall hit at LOW speed.[br][br]
## Intended purpose: the penalty applied for grazing/scraping along a wall; blends toward wall_brute_force_loss as speed rises.[br][br]
## Higher = shallow clips cost more speed; lower = soft scrapes barely slow you.
@export var wall_impact_loss : float = 0.7
## Fraction of velocity lost on a HIGH-speed (brute-force) wall hit.[br][br]
## Intended purpose: the speed-loss penalty when smashing into a wall at top speed; blends toward this from wall_impact_loss as speed fraction rises.[br][br]
## Higher = fast crashes lose more speed (harder punishment); lower = high-speed hits keep most of their momentum.
@export var wall_brute_force_loss : float = 0.15
## Curve that maps impact angle to the wall-penalty factor. x = angle fraction (0 = grazing side-scrape, 1 = dead-on nose hit).[br][br]
## Intended purpose: choose how forgiving wall scrapes are based on impact angle.[br][br]
## COSINE hits hard even on shallow clips; CUBIC barely touches you until near-perfect head-ons; SMOOTHSTEP has a soft shoulder then snaps to full near dead-on.
@export var wall_angle_curve : WallAngleCurve = WallAngleCurve.COSINE

@export_category("Node References")
## Raycasts used to measure the ground distance for the hover springs.[br][br]
## Intended purpose: each ray samples terrain height under the pod; the highest correction among colliding rays drives the hover spring.[br][br]
## More/appropriately placed rays = more stable hovering over uneven terrain; rays too far apart or mis-aimed = the pod reads bumps and ditches poorly.
@export var hover_raycasts : Array[RayCast3D] = []
## Node the camera rig follows / is attached to on the pod.[br][br]
## Intended purpose: anchor point for the follow camera so it tracks pod position and rotation cleanly.
@export var camera_mount : Node3D
@onready var wing_left : Node3D = %Wing_Left
@onready var wing_right : Node3D = %Wing_Right
@onready var blade : Node3D = $Visuals/Blade
@onready var pcam_noise_emitter : PhantomCameraNoiseEmitter3D = $CameraMount/PhantomCameraNoiseEmitter3D
@onready var hover_raycasts_root : Node3D = %HoverRaycasts

enum BoostState { NORMAL, CHARGING, READY, BOOSTING, OVERHEAT }
enum BoostLight { OFF, GREEN, YELLOW, RED }

var _boost_state : int = BoostState.NORMAL
var _charge : float = 0.0
var _heat : float = 0.0
var _current_speed : float = 0.0
var _yaw : float = 0.0
var _yaw_rate : float = 0.0
var _pitch : float = 0.0
var _roll : float = 0.0
var _visual_nose : float = 0.0
var _tilt_roll : float = 0.0
var _wing_left_base_rot : Vector3
var _wing_right_base_rot : Vector3
var _wing_left_base_pos : Vector3
var _wing_right_base_pos : Vector3
var _wing_left_lift : float = 0.0
var _wing_right_lift : float = 0.0
var _wing_nose : float = 0.0
var _wing_left_particles : Array[GPUParticles3D] = []
var _wing_right_particles : Array[GPUParticles3D] = []
var _blade_base_pos : Vector3
var _blade_base_rot : Vector3
var _chassis_sway_amount : float = 0.0
var _grounded : bool = false
var _ground_normal : Vector3 = Vector3.UP
var _camera_mount_base_rot : Vector3
var _camera_mount_base_pos : Vector3
var _hover_time : float = 0.0

func _ready():
	if Engine.is_editor_hint():
		return
	_yaw = rotation.y
	_pitch = rotation.x
	_roll = rotation.z
	for ray in hover_raycasts:
		if ray:
			ray.enabled = true
	if hover_raycasts.is_empty():
		if hover_raycasts_root:
			for child in hover_raycasts_root.get_children():
				if child is RayCast3D:
					hover_raycasts.append(child)
					child.enabled = true
	if wing_left:
		_wing_left_base_rot = wing_left.rotation
		_wing_left_base_pos = wing_left.position
		_wing_left_particles = _get_wing_particles(wing_left)
	if wing_right:
		_wing_right_base_rot = wing_right.rotation
		_wing_right_base_pos = wing_right.position
		_wing_right_particles = _get_wing_particles(wing_right)
	if blade:
		_blade_base_pos = blade.position
		_blade_base_rot = blade.rotation
	if camera_mount:
		_camera_mount_base_rot = camera_mount.rotation
		_camera_mount_base_pos = camera_mount.position

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
	_debug_hover_tuning()
	_build_pod_basis()
	_counter_rotate_camera(delta)
	_boost_process(delta, input)
	_update_thruster_particles(input)
	
	move_and_slide()

	_handle_collisions()

	_current_speed = velocity.length()
	DebugManager.update_property("~~_ Movement _~~", "~~~~~~~~~~~~")
	DebugManager.update_property("Current Speed", String.num(_current_speed, 2));
	DebugManager.update_property("Speed Fraction", String.num(_current_speed / max_speed, 2));
	DebugManager.update_property("Vertical Speed", String.num(velocity.y, 2));
	DebugManager.update_property("Hover Height", String.num(hover_height, 2));
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
	


func _debug_hover_tuning():
	if Input.is_action_just_pressed(&"Debug_IncreaseHoverHeight"):
		hover_height = clampf(hover_height + debug_hover_step, 0.1, 20.0)
	elif Input.is_action_just_pressed(&"Debug_DecreaseHoverHeight"):
		hover_height = clampf(hover_height - debug_hover_step, 0.1, 20.0)

func _hover(delta, input):
	_hover_time += delta
	var grounded : bool = false
	var near_ground : bool = false
	var normal_sum : Vector3 = Vector3.ZERO
	var normal_count : int = 0
	var max_upward : float = -999.0
	var ray_index : int = 0
	for ray in hover_raycasts:
		var phase : float = float(ray_index) / float(hover_raycasts.size())
		ray_index += 1
		ray.global_rotation = Vector3.ZERO
		ray.force_raycast_update()
		if not ray.is_colliding():
			continue
		var point = ray.get_collision_point()
		var dist = ray.global_position.distance_to(point)
		if dist < hover_height + grounded_band:
			near_ground = true
		var bob : float = idle_bob_amplitude * sin(_hover_time * TAU * idle_bob_frequency + phase * TAU)
		var compression = hover_height + bob - dist
		if compression <= 0.0:
			continue
		grounded = true
		var n : Vector3 = ray.get_collision_normal()
		if n.length() > 0.001:
			normal_sum += n
			normal_count += 1
		var correction = compression * spring_stiffness - velocity.y * spring_damping
		if correction > max_upward:
			max_upward = correction
	if _grounded:
		_grounded = near_ground
	else:
		_grounded = grounded
	if normal_count > 0:
		_ground_normal = (normal_sum / float(normal_count)).normalized()
	else:
		_ground_normal = Vector3.UP

	var eff_gravity : float = gravity
	if input.pitch > 0.0:
		eff_gravity = lerp(gravity, gravity_nose_up, input.pitch)
	elif input.pitch < 0.0:
		eff_gravity = lerp(gravity, gravity_nose_down, -input.pitch)
	velocity.y -= eff_gravity * delta

	if max_upward > -999.0:
		if max_upward > velocity.y:
			velocity.y = lerp(velocity.y, max_upward, 4.0 * delta)

func _accelerate(delta, input):
	if input.accelerate <= 0.0:
		return

	var target = max_speed
	if _boost_state == BoostState.BOOSTING:
		target = max_speed + boost_speed_bonus

	var nose_bias : float = -input.pitch
	target += nose_bias * pitch_speed_gain
	target = maxf(target, 0.0)
	var accel : float = acceleration_factor * (1.0 + nose_bias * pitch_accel_gain)

	var forward = _flat_forward()
	var current_forward_speed = velocity.dot(forward)

	var target_forward = input.accelerate * target
	var new_forward_speed = lerp(current_forward_speed, target_forward, acceleration_factor * delta)

	velocity += forward * (new_forward_speed - current_forward_speed)

func _brake(delta, input):
	if input.brake <= 0.0:
		return
	var forward = _flat_forward()
	var forward_speed = velocity.dot(forward)
	if forward_speed <= 0.0:
		return
	var new_forward_speed = lerp(forward_speed, 0.0, brake_deceleration * delta)
	velocity += forward * (new_forward_speed - forward_speed)

func _steer(delta, input):
	var turn_mult : float = 1.0
	if input.pitch > 0.0:
		turn_mult = lerp(1.0, nose_up_turn_multiplier, input.pitch)
	elif input.pitch < 0.0:
		turn_mult = lerp(1.0, nose_down_turn_multiplier, -input.pitch)
	var boost_turn_mult : float = 1.0
	if _boost_state == BoostState.BOOSTING:
		boost_turn_mult = boost_turn_rate_penalty
	var tilt_turn_mult : float = 1.0
	if tilt_max_angle > 0.0:
		var tilt_frac : float = clampf(absf(_tilt_roll) / deg_to_rad(tilt_max_angle), 0.0, 1.0)
		tilt_turn_mult = lerp(1.0, tilt_turn_rate_penalty, tilt_frac)
	var max_rate : float = max_turn_rate * turn_mult * boost_turn_mult * tilt_turn_mult
	var target_rate : float = -input.steer * max_rate
	_yaw_rate = lerp(_yaw_rate, target_rate, turn_response * delta)
	_yaw += _yaw_rate * delta

	var forward = _flat_forward()
	var forward_speed = velocity.dot(forward)
	var lat = velocity - forward * forward_speed
	velocity = forward * forward_speed + lat * (1.0 - min(1.0, traction * delta))

func _build_pod_basis():
	var basis : Basis = Basis(Vector3.UP, _yaw)
	basis = basis.rotated(basis.z, _roll + _tilt_roll)
	basis = basis.rotated(basis.x, _pitch)
	global_transform.basis = basis

func _tilt(delta, input):
	var speed_frac = clampf(_current_speed / max_speed, 0.0, 1.0) if max_speed > 0.0 else 0.0
	var tilt_mix : float = clampf(abs(input.tilt), 0.0, 1.0)
	var target_roll = -input.steer * deg_to_rad(max_bank_angle) * speed_frac * (1.0 - tilt_mix)
	_roll = lerp(_roll, target_roll, bank_speed * delta)

	var target_tilt_roll = 0.0
	if _current_speed >= tilt_min_speed_fraction * max_speed:
		target_tilt_roll = -input.tilt * deg_to_rad(tilt_max_angle)
	_tilt_roll = lerp(_tilt_roll, target_tilt_roll, tilt_speed * delta)

	var base_pitch : float = _pitch_attitude_target()
	var target_pitch : float = base_pitch
	var manual_nose : float = input.pitch * deg_to_rad(manual_pitch_angle)
	manual_nose += input.accelerate * deg_to_rad(pitch_accel_angle)
	manual_nose -= input.brake * deg_to_rad(pitch_brake_angle)
	if not _grounded:
		target_pitch += manual_nose
	target_pitch = clampf(target_pitch, -deg_to_rad(max_pitch_angle), deg_to_rad(max_pitch_angle))
	_pitch = lerp(_pitch, target_pitch, pitch_rate * delta)
	_visual_nose = lerp(_visual_nose, input.pitch * deg_to_rad(visual_nose_deg), pitch_rate * delta)

func _pitch_attitude_target() -> float:
	var max_arc : float = deg_to_rad(arc_pitch_max_deg)
	if _grounded:
		var local_n : Vector3 = global_transform.basis.inverse() * _ground_normal
		local_n = local_n.normalized()
		if local_n.length() > 0.001:
			return clampf(atan2(local_n.z, local_n.y) * terrain_pitch_align, -max_arc, max_arc)
		return 0.0
	return clampf(velocity.y * deg_to_rad(arc_pitch_gain), -max_arc, max_arc)

func _counter_rotate_camera(delta):
	if not camera_mount:
		return
	var counter : float = -(_roll + _tilt_roll * (1.0 - camera_tilt_follow)) * camera_roll_counter
	camera_mount.rotation = _camera_mount_base_rot + Vector3(0.0, 0.0, counter)
	camera_mount.position = _camera_mount_base_pos.rotated(Vector3(0.0, 0.0, 1.0), counter)

func _chassis_sway(delta, input):
	if not blade:
		return
	var turn_frac : float = 0.0
	if max_turn_rate > 0.0:
		turn_frac = clampf(_yaw_rate / max_turn_rate, -1.0, 1.0)
	var sway_target : float = turn_frac * chassis_sway_travel
	_chassis_sway_amount = lerp(_chassis_sway_amount, sway_target, chassis_sway_speed * delta)
	var tilt_mix : float = clampf(abs(input.tilt), 0.0, 1.0)
	var tilt_frac : float = 0.0
	if tilt_max_angle > 0.0:
		tilt_frac = clampf(absf(_tilt_roll) / deg_to_rad(tilt_max_angle), 0.0, 1.0)
	var sway_x_world : Vector3 = global_transform.basis * Vector3(_chassis_sway_amount, 0.0, 0.0)
	var sway_y_world : Vector3 = global_transform.basis * Vector3(0.0, _chassis_sway_amount, 0.0)
	var sway_x_flat : Vector3 = Vector3(sway_x_world.x, 0.0, sway_x_world.z)
	var sway_y_flat : Vector3 = Vector3(sway_y_world.x, 0.0, sway_y_world.z)
	var sway_flat : Vector3 = sway_x_flat * (1.0 - tilt_mix) + sway_y_flat * tilt_mix
	var sway_local : Vector3 = Vector3.ZERO
	if sway_flat.length() > 0.001:
		sway_local = global_transform.basis.inverse() * sway_flat
	var part_bob : float = idle_part_bob_amplitude * sin(_hover_time * TAU * idle_bob_frequency * 1.3 + PI) * (1.0 - tilt_mix)
	blade.position = _blade_base_pos + sway_local + Vector3(0.0, part_bob, 0.0)
	var sway_frac : float = 0.0
	if chassis_sway_travel > 0.0:
		sway_frac = clampf(_chassis_sway_amount / chassis_sway_travel, -1.0, 1.0)
	var sway_roll : float = -sway_frac * deg_to_rad(chassis_sway_roll_deg) * (1.0 - tilt_mix)
	var chassis_nose : float = 0.0
	if _grounded:
		chassis_nose = clampf(_visual_nose, -deg_to_rad(visual_nose_deg), deg_to_rad(visual_nose_deg)) * (1.0 - tilt_mix)
	blade.rotation = _blade_base_rot + Vector3(chassis_nose, 0.0, sway_roll)

func _wing_tilt(delta, input):
	if not wing_left or not wing_right:
		return
	var turn_frac : float = 0.0
	if max_turn_rate > 0.0:
		turn_frac = clampf(_yaw_rate / max_turn_rate, -1.0, 1.0)
	var turn_intensity : float = -turn_frac

	var tilt_mix : float = clampf(abs(input.tilt), 0.0, 1.0)
	var nose_target : float
	if _grounded:
		nose_target = clampf(_visual_nose, -deg_to_rad(visual_nose_deg), deg_to_rad(visual_nose_deg))
	else:
		nose_target = -clampf(_pitch, -deg_to_rad(wing_nose_tilt_deg), deg_to_rad(wing_nose_tilt_deg))
	_wing_nose = lerp(_wing_nose, nose_target * (1.0 - tilt_mix), wing_tilt_speed * delta)

	var up : float = abs(turn_intensity) * wing_up_vert_travel
	var down : float = -abs(turn_intensity) * wing_down_vert_travel
	if turn_intensity >= 0.0:
		_wing_left_lift = lerp(_wing_left_lift, up, wing_tilt_speed * delta)
		_wing_right_lift = lerp(_wing_right_lift, down, wing_tilt_speed * delta)
	else:
		_wing_left_lift = lerp(_wing_left_lift, down, wing_tilt_speed * delta)
		_wing_right_lift = lerp(_wing_right_lift, up, wing_tilt_speed * delta)

	var lift_scale : float = 1.0 - tilt_mix
	var diff_left_world : Vector3 = Vector3(0.0, _wing_left_lift, 0.0) * lift_scale
	var diff_right_world : Vector3 = Vector3(0.0, _wing_right_lift, 0.0) * lift_scale
	var engine_bob : float = idle_part_bob_amplitude * sin(_hover_time * TAU * idle_bob_frequency * 1.3) * lift_scale
	diff_left_world.y += engine_bob
	diff_right_world.y += engine_bob
	wing_left.rotation = _wing_left_base_rot + Vector3(_wing_nose, 0.0, 0.0)
	wing_right.rotation = _wing_right_base_rot + Vector3(_wing_nose, 0.0, 0.0)
	wing_left.position = _wing_left_base_pos + _world_offset(diff_left_world, wing_left)
	wing_right.position = _wing_right_base_pos + _world_offset(diff_right_world, wing_right)

func _world_offset(world_vec : Vector3, wing : Node3D) -> Vector3:
	if world_vec == Vector3.ZERO:
		return Vector3.ZERO
	var parent : Node3D = wing.get_parent()
	return parent.global_transform.affine_inverse().basis * world_vec

func _get_wing_particles(node : Node3D) -> Array[GPUParticles3D]:
	var particles : Array[GPUParticles3D] = []
	for child in node.get_children():
		if child is GPUParticles3D:
			particles.append(child);
	return particles

func _update_thruster_particles(input):
	var emitting : bool = input.accelerate > 0.0;
	for particles in _wing_left_particles:
		particles.amount_ratio = _speed_fraction();
		particles.emitting = emitting;
	for particles in _wing_right_particles:
		particles.amount_ratio = _speed_fraction();
		particles.emitting = emitting;

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
			_cool_heat(delta)
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

func _flat_forward() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))

func _flat_right() -> Vector3:
	return Vector3(cos(_yaw), 0.0, -sin(_yaw))

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
	var full : float = cos(deg_to_rad(charge_pitch_deadzone_deg))
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

func _reset_charge_level():
	_charge = 0.0;

func _start_boost():
	_boost_state = BoostState.BOOSTING
	_reset_charge_level();
	velocity += _flat_forward() * boost_thrust

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
	_reset_charge_level();
	_heat = max(_heat, 0.1)

func _cool_after_overheat(delta):
	_heat -= cool_rate * delta
	_heat = max(_heat, 0.0)
	if _heat <= 0.0:
		_boost_state = BoostState.NORMAL
		_reset_charge_level();

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
		var speed : float = velocity.length()
		if speed <= 0.001:
			continue
		var into_wall : float = maxf(-velocity.dot(normal), 0.0)
		var into_frac : float = into_wall / speed
		if into_frac <= 0.001:
			continue
		var head_on : float = clampf(_flat_forward().dot(normal), 0.0, 1.0)
		var angle_frac : float = 1.0 - acos(head_on) / deg_to_rad(90.0)
		var angle_factor : float = _curve_angle(angle_frac)
		var speed_frac : float = clampf(speed / max_speed, 0.0, 1.0)
		var penalty : float = lerp(wall_impact_loss, wall_brute_force_loss, speed_frac)
		velocity *= 1.0 - (penalty * angle_factor * into_frac)

func _curve_angle(x : float) -> float:
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
