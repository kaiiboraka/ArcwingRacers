@tool
extends Control

## Conversion factor from m/s to mph (1 m/s = 2.23694 mph).[br]
## Used by set_speed_mps() so the HUD can be fed pod-native units.
#const MPS_TO_MPH : float = 2.23694;

## Current speed in mph. Writing this (or calling set_speed / set_speed_mp"res://UI/HUD/Spedometer/bar_colored.PNG"s) updates the speed text and its gradient color.[br]
## Intended purpose: the displayed speed value; source of truth for the speed text + color.[br]
## Higher = faster reading and warmer color.
@export_range(0.0, 9999.0) var current_speed : float = 0.0:
#@export_range(0.0, 9999.0) var speed_mph : float = 0.0:
	set(v):
		#speed_mph = v;
		current_speed = v;
		_update_speed_display();

## Lowest speed in mph at which the text color is cyan; below this it stays cyan.[br]
## Intended purpose: start of the color ramp; the cyan→green→yellow→red→magenta gradient spans floor→ceiling.[br]
## Higher = cyan holds longer; lower = gradient starts sooner.
@export_range(1.0, 9999.0) var speed_floor_mph : float = 100.0:
	set(v):
		speed_floor_mph = v;
		_update_speed_display();

## Highest speed in mph at which the text color is magenta; at/above this it stays magenta.[br]
## Intended purpose: end of the color ramp.[br]
## Higher = gradient stretches longer; lower = gradient ends sooner.
@export_range(1.0, 9999.0) var speed_ceiling_mph : float = 1000.0:
	set(v):
		speed_ceiling_mph = v;
		_update_speed_display();

## Source-of-truth light color driven by external input (boost state, etc.).[br]
## Drives LightTexture + GlassTubes self_modulate, PointLight2D color alpha (fades toward 0 as the color approaches white, with a dip on each change), and LargeIcon_ALPHA self-modulate alpha (same white-falloff curve).[br]
## PointLight2D's color dims proportionally to how far the color is from white — pure white = fully off, saturated/dark colors = near full strength. Energy is left to the scene (does not get touched).<br>
## Tool-editable: tweak in the inspector to preview the whole light reaction.
@export var light_color : Color = Color.WHITE:
	set(v):
		light_color = v;
		_begin_light_transition(v);

## How long each light color change takes to transition, in seconds.[br]
## Intended purpose: timing of the color lerp and the alpha dip-to-0-and-back pulse.[br]
## Higher = slower, more dramatic fade; lower = snappier.
@export_range(0.05, 5.0, 0.05) var light_transition_duration : float = 0.5:
	set(v):
		light_transition_duration = v;

@onready var _speed_label : RichTextLabel = %SpeedText_RichTextLabel;
@onready var _light_texture : TextureRect = %LightTexture;
@onready var _glass_tubes : TextureRect = %LightTexture/GlassTubes;
@onready var _point_light : PointLight2D = %PointLight2D;
@onready var _large_icon_alpha : TextureRect = %LargeIcon_ALPHA;

@onready var bar_fill_uncharged: BarFill = $bar/bar_fill_uncharged
@onready var bar_fill_charging: BarFill = $bar/bar_fill_charging
@onready var bar_fill_boost: BarFill = $bar/bar_fill_BOOST
@onready var bar_black_background_1: BarBackground = $bar/bar_Background_Black1
@onready var bar_black_background_2: BarBackground = $bar/bar_Background_Black2

var _boost_state : PodController.BoostState = PodController.BoostState.NORMAL;

var _display_color : Color = Color.WHITE;
var _transition_from : Color = Color.WHITE;
var _transition_to : Color = Color.WHITE;
var _alpha_from : float = 0.0;
var _alpha_to : float = 0.0;
var _transition_t : float = 1.0;

func _ready():
	set_process(false);
	_update_speed_display();
	_apply_light_state(light_color, _light_alpha_for(light_color));
	if not Engine.is_editor_hint():
		bar_fill_uncharged.visible = true;
		bar_black_background_1.visible = false;
		bar_fill_charging.visible = true;
		bar_black_background_2.visible = false;
		bar_fill_boost.visible = true;
		bar_fill_charging.set_percentage(0.0);
		bar_fill_boost.set_percentage(0.0);
		EventBus.speed_updated.connect(_on_speed_updated);
		EventBus.boost_state_changed.connect(_on_boost_state_changed);
		EventBus.boost_charge_updated.connect(_on_boost_charge_updated);
		EventBus.boost_heat_updated.connect(_on_boost_heat_updated);

## EventBus handler: pod speed in m/s + fraction of max_speed. Feeds the speed number
## (converted to mph) and, while the pod is not charging or boosting, the uncharged bar.
func _on_speed_updated(speed_mps : float, speed_fraction : float) -> void:
	#speed_mph = speed_mps * MPS_TO_MPH;
	current_speed = speed_mps
	bar_fill_uncharged.set_percentage(clampf(speed_fraction, 0.0, 1.0) * 100.0);
	#if _boost_state == PodController.BoostState.NORMAL or _boost_state == PodController.BoostState.OVERHEAT:

## EventBus handler: BoostState (NORMAL, CHARGING, READY, BOOSTING, OVERHEAT). Sets the
## light color and drives the three stacked bars + black background.
func _on_boost_state_changed(state : PodController.BoostState) -> void:
	_boost_state = state;
	light_color = _boost_light_color(state);
	match state:
		PodController.BoostState.NORMAL, PodController.BoostState.OVERHEAT:
			bar_fill_charging.set_percentage(0.0);
			bar_fill_boost.set_percentage(0.0);
			bar_black_background_1.visible = false;
			bar_black_background_2.visible = false;
		PodController.BoostState.CHARGING:
			bar_fill_boost.set_percentage(0.0);
			bar_black_background_1.visible = true;
			bar_black_background_2.visible = false;
		PodController.BoostState.READY:
			bar_fill_boost.set_percentage(0.0);
			bar_black_background_1.visible = true;
			bar_black_background_2.visible = false;
		PodController.BoostState.BOOSTING:
			bar_fill_uncharged.set_percentage(100.0);
			bar_fill_charging.set_percentage(100.0);
			bar_black_background_1.visible = true;
			bar_black_background_2.visible = true;

## EventBus handler: boost charge gauge 0-100. Fills the charging bar while charging
## (and holds it full once READY); charge resets on boost start and normal return.
func _on_boost_charge_updated(charge_percent : float) -> void:
	if _boost_state == PodController.BoostState.CHARGING or _boost_state == PodController.BoostState.READY:
		bar_fill_charging.set_percentage(charge_percent);

## EventBus handler: boost heat gauge 0-100. Fills the BOOST bar only while boosting;
## once out of BOOSTING the bar is reset by the state handler.
func _on_boost_heat_updated(heat_pct : float) -> void:
	if _boost_state == PodController.BoostState.BOOSTING:
		bar_fill_boost.set_percentage(heat_pct);

func _boost_light_color(state : PodController.BoostState) -> Color:
	match state:
		PodController.BoostState.NORMAL:
			return Color.WHITE;
		PodController.BoostState.CHARGING:
			return Color.GREEN;
		PodController.BoostState.READY:
			return Color.YELLOW;
		PodController.BoostState.BOOSTING:
			return Color.MAGENTA;
		PodController.BoostState.OVERHEAT:
			return Color.DARK_RED;
	return Color.WHITE;

### External speed input in mph (e.g. connected from a system signal).
#func set_speed(mph : float) -> void:
	#speed_mph = mph;
#
### External speed input in m/s — converts to mph before updating the display.
#func set_speed_mps(mps : float) -> void:
	#speed_mph = mps * MPS_TO_MPH;

func _process(delta : float):
	if _transition_t >= 1.0:
		return;
	_transition_t += delta / maxf(light_transition_duration, 0.001);
	if _transition_t >= 1.0:
		_transition_t = 1.0;
		set_process(false);
	var t : float = _transition_t;
	var color : Color = _transition_from.lerp(_transition_to, t);
	var pulse : float = absf(1.0 - 2.0 * t);
	var alpha : float = lerpf(_alpha_from, _alpha_to, t) * pulse;
	_display_color = color;
	_apply_light_state(color, alpha);

func _begin_light_transition(target : Color) -> void:
	if not is_inside_tree() or _light_texture == null:
		return;
	_transition_from = _display_color;
	_transition_to = target;
	_alpha_from = _light_alpha_for(_transition_from);
	_alpha_to = _light_alpha_for(target);
	_transition_t = 0.0;
	set_process(true);

func _apply_light_state(color : Color, alpha : float) -> void:
	_light_texture.self_modulate = Color(color, 1.0);
	_glass_tubes.self_modulate = Color(color, 1.0);
	_point_light.color = Color(color, alpha);
	_large_icon_alpha.self_modulate = Color(1.0, 1.0, 1.0, alpha);

## Light strength as a function of how far `color` is from white — the closer to
## white (255,255,255), the closer alpha gets to 0. Pure/highly-saturated or dark
## colors stay near full strength. Normalized Euclidean distance from white.
func _light_alpha_for(color : Color) -> float:
	var r : float = 1.0 - color.r;
	var g : float = 1.0 - color.g;
	var b : float = 1.0 - color.b;
	return sqrt(r * r + g * g + b * b) / sqrt(3.0);

func _update_speed_display() -> void:
	if not is_inside_tree() or _speed_label == null:
		return;
	#_speed_label.text = str(int(speed_mph));
	_speed_label.text = str(int(current_speed));
	#_speed_label.add_theme_color_override("default_color", _speed_color(speed_mph));
	_speed_label.add_theme_color_override("default_color", _speed_color(current_speed));

func _speed_color(mph : float) -> Color:
	const LIGHT_GREY : Color = Color(0.8, 0.8, 0.8);
	const CYAN : Color = Color(0.0, 1.0, 1.0);
	const GREEN : Color = Color(0.0, 1.0, 0.0);
	const YELLOW : Color = Color(1.0, 1.0, 0.0);
	const RED : Color = Color(1.0, 0.0, 0.0);
	const MAGENTA : Color = Color(1.0, 0.0, 1.0);
	if mph < 10.0:
		return LIGHT_GREY;
	if mph <= speed_floor_mph:
		return CYAN;
	if mph >= speed_ceiling_mph:
		return MAGENTA;
	var t : float = (mph - speed_floor_mph) / maxf(speed_ceiling_mph - speed_floor_mph, 0.001);
	var stops : Array = [CYAN, GREEN, YELLOW, RED, MAGENTA];
	var scaled : float = t * 4.0;
	var index : int = mini(int(scaled), 3);
	var frac : float = scaled - float(index);
	return (stops[index] as Color).lerp(stops[index + 1] as Color, frac);
