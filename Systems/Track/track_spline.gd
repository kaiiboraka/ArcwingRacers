@tool
class_name TrackSpline
extends Path3D

## Authoring node for a track spline. The inherited Path3D.curve holds a Spline resource;
## this node ensures it is a Spline (not a bare Curve3D) so per-point metadata arrays exist,
## and re-bakes geometry (future TrackMeshGenerator) when points or metadata change.

## Meters between baked samples. Drives sampling fidelity for banking and tunnels.[br]
## Intended purpose: set once at authoring time; baked geometry and gameplay sampling use it.[br]
## Lower = finer sampling (smoother curves, more points); higher = coarser.
@export_range(0.05, 5.0, 0.05) var bake_interval: float = 0.25

@export_group("Editor")
## Source curve to import points from (plain Curve3D or Spline) via the Import Points button.[br]
## Intended purpose: copy an authored dummy path/curve's points into this spline when the
## editor copy-paste cannot cross resource types.[br]
## Leave empty to skip.
@export var source_curve: Curve3D
## Copy all points from source_curve into this spline, replacing existing points. Editor-only;
## copies position/handles/tilt, plus metadata when the source is a Spline (see Spline.import_from).
@export_tool_button("Import Points from Curve") var import_points: Callable = _import_points
## Regenerate all track geometry from this spline. Editor-only; the mesh generator bakes
## ROAD/TUNNEL spans into StaticBody3D + visuals (see ADR 0010).
@export_tool_button("Generate Track Geometry") var generate_geometry: Callable = _generate_track_geometry

## Copy all points from source_curve into this spline, replacing existing points. Editor-only;
## copies position/handles/tilt, plus metadata when the source is a Spline (see Spline.import_from).
func _import_points() -> void:
	if source_curve == null:
		push_warning("TrackSpline '%s': source_curve is not assigned." % name)
		return
	var spline: Spline = get_spline()
	if spline == null:
		push_warning("TrackSpline '%s': no Spline assigned as curve." % name)
		return
	spline.import_from(source_curve)

func _enter_tree() -> void:
	if curve == null:
		curve = Spline.new()
	elif not curve is Spline:
		push_warning("TrackSpline '%s': curve is a Curve3D, not a Spline — metadata arrays unavailable." % name)
		return
	_apply_bake_settings()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if curve is Spline:
		_apply_bake_settings()

func get_spline() -> Spline:
	return curve as Spline

# --- World-space wrappers ---------------------------------------------------------------
# Curve3D's baked sampling and closest-point queries are local to the curve (relative to this
# Path3D origin). Gameplay uses world positions, so translate here.

## World-space position at a baked offset.
func sample_world(offset: float, cubic: bool = true) -> Vector3:
	var spline: Spline = get_spline()
	if spline == null:
		return Vector3.ZERO
	return to_global(spline.sample_baked(offset, cubic))


## World-space forward (tangent) direction at a baked offset.
func sample_forward_world(offset: float, delta: float = 0.01) -> Vector3:
	var spline: Spline = get_spline()
	if spline == null:
		return Vector3.ZERO
	return global_transform.basis * spline.sample_forward(offset, delta)


## World-space surface normal at a baked offset.
func sample_normal_world(offset: float) -> Vector3:
	var spline: Spline = get_spline()
	if spline == null:
		return Vector3.UP
	var local_normal: Vector3 = spline.sample_normal(offset)
	return global_transform.basis * local_normal


## Nearest offset in meters along the spline to a world-space point.
func project_world(point: Vector3) -> float:
	var spline: Spline = get_spline()
	if spline == null:
		return 0.0
	return spline.get_closest_offset(to_local(point))

func _apply_bake_settings() -> void:
	var spline: Spline = get_spline()
	if spline == null:
		return
	spline.bake_interval = bake_interval

func _generate_track_geometry() -> void:
	# Placeholder: mesh generator lands in the next pass (ADR 0010). For now, emit the bake
	# parameters so the editor stays functional without generator code.
	if not is_inside_tree():
		return
	var spline: Spline = get_spline()
	if spline == null:
		return
	_apply_bake_settings()
	print("[TrackSpline] %s: bake_interval=%.2f points=%d — generator pending." % [name, bake_interval, spline.point_count])
