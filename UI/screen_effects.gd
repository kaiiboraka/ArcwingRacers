extends CanvasLayer

@onready var speed_lines: ColorRect = $SpeedLines_ColorRect

@export_category("Line Density")
## Density of the speed-lines overlay while cruising (non-charge/boost states), reached
## as the pod approaches the boost charge speed threshold. The lines are fully transparent
## at 0 density, so this doubles as the "effect off at low speed" control.
@export var density_idle_max : float = 0.5
## Density while the boost gauge is charging or fully charged (READY).
@export var density_charge : float = 0.65
## Density while boosting.
@export var density_boost : float = 1.0
## Fraction of max speed at which idle density ramps to density_idle_max. Mirrors
## PodController.min_charge_speed_fraction so the lines peak right where charging begins.
@export var charge_speed_fraction : float = 0.8
## How fast the shader's line_density lerps toward its target each second. Higher = snappier.
@export var density_lerp_speed : float = 4.0

var _target_density : float = 0.0
var _current_density : float = 0.0
var _boost_state : PodController.BoostState = PodController.BoostState.NORMAL
var _last_speed_fraction : float = 0.0

func _ready() -> void:
	speed_lines.visible = true
	EventBus.speed_updated.connect(_on_speed_updated)
	EventBus.boost_state_changed.connect(_on_boost_state_changed)

func _process(delta : float) -> void:
	var rate : float = minf(density_lerp_speed * delta, 1.0)
	_current_density = lerp(_current_density, _target_density, rate)
	if absf(_current_density - _target_density) < 0.0005:
		_current_density = _target_density
	var mat : ShaderMaterial = speed_lines.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("line_density", _current_density)

func _on_speed_updated(speed_mph : float, speed_fraction : float) -> void:
	_last_speed_fraction = speed_fraction
	_target_density = _compute_density()

func _on_boost_state_changed(state : PodController.BoostState) -> void:
	_boost_state = state
	_target_density = _compute_density()

func _compute_density() -> float:
	match _boost_state:
		PodController.BoostState.CHARGING, PodController.BoostState.READY:
			return density_charge
		PodController.BoostState.BOOSTING:
			return density_boost
		_:
			var ramp : float = clampf(_last_speed_fraction / charge_speed_fraction, 0.0, 1.0)
			return smoothstep(0.0, 1.0, ramp) * density_idle_max
