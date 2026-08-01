@tool
class_name Spline
extends Curve3D

## Recipe for the span AFTER a point. Decides whether geometry is generated from the spline
## or left to modeled terrain (ADR 0010).
enum SegmentRecipe {
	## No generated geometry — modeled terrain/level mesh stands as-is. The spline still drives
	## racing line, AI path, lap, and respawn data here.
	NONE,
	## Generate a flat ribbon surface + side walls from the spline (width from point_widths).
	ROAD,
	## Generate a tube: ribbon + side walls + roof. Height from point_recipe_params.
	TUNNEL,
}

## Bitfield flags for a point (ADR 0005 / tracks-and-splines.md).
enum SplinePointFlags {
	NONE          = 0,
	START_FINISH  = 1 << 0,
	WAYPOINT      = 1 << 1,
	RESPAWN       = 1 << 2,
	BRANCH_SPLIT  = 1 << 3,
	BRANCH_JOIN   = 1 << 4,
	PIT_ENTRY     = 1 << 5,
	PIT_EXIT      = 1 << 6,
}

## Per-point track half-width in meters (left + right from center line). Indexed 1:1 with
## Curve3D point_count.[br]
## Intended purpose: interpolated between points so tracks can narrow (tunnel entrances) and
## widen (straights, pit areas).[br]
## Higher = wider road; lower = narrower ribbon.
@export var point_widths: PackedFloat32Array = PackedFloat32Array()
## Per-point mesh recipe (SegmentRecipe enum). Decides what the generator builds on the span
## AFTER this point.[br]
## Intended purpose: hybrid authoring — ROAD/TUNNEL generate geometry, NONE leaves space for
## modeled .glb terrain.[br]
## NONE = modeled terrain; ROAD = ribbon + walls; TUNNEL = tube.
@export var point_recipes: Array[int] = []
## Per-point recipe scalar, currently the tunnel height in meters for TUNNEL spans.[br]
## Intended purpose: carries the extra dimension a recipe needs (tunnel height) without a
## separate data structure.[br]
## Higher = taller tunnel; ignored for ROAD/NONE.
@export var point_recipe_params: PackedFloat32Array = PackedFloat32Array()
## Per-point flags bitfield (SplinePointFlags).[br]
## Intended purpose: mark lap line, waypoints, respawns, and branch hints on the spline.[br]
## Bitwise OR of SplinePointFlags values.
@export var point_flags: Array[int] = []
## Whether the spline forms a closed loop (circuit) or runs point 0 → last once (rally).[br]
## Intended purpose: maps to Curve3D.closed — cyclic tracks wrap last→first and lap offsets
## mod the total length; non-cyclic tracks are always 1 lap.[br]
## True = circuit; false = point-to-point.
@export var cyclic: bool = true:
	get:
		return closed
	set(value):
		closed = value

@export_group("Recipe Defaults")
## Default width applied when a point is added without explicit metadata (editor authoring).[br]
## Intended purpose: new points in the Path3D gizmo get a sane road width immediately.[br]
## Higher = wider default road.
@export var default_width: float = 5.0
## Default recipe applied when a point is added without explicit metadata (editor authoring).[br]
## Intended purpose: new points default to modeled-terrain spans so the spline never generates
## geometry the designer did not ask for.[br]
## NONE = modeled terrain; ROAD = generate ribbon.
@export var default_recipe: SegmentRecipe = SegmentRecipe.NONE
## Default recipe scalar applied when a point is added without explicit metadata (editor authoring).[br]
## Intended purpose: TUNNEL spans start with a sane height.[br]
## Higher = taller default tunnel.
@export var default_recipe_param: float = 6.0
## Default flags applied when a point is added without explicit metadata (editor authoring).[br]
## Intended purpose: new points are unflagged until explicitly marked.[br]
## 0 = no flags.
@export var default_flags: int = SplinePointFlags.NONE


func _init() -> void:
	bake_interval = 0.25
	closed = true
	changed.connect(_on_changed)


## --- Metadata sync: hook Curve3D's changed signal ------------------------------------------
## Native Curve3D methods (add_point, remove_point, set_point_count, clear_points) cannot be
## overridden in GDScript — the engine calls its internal C++ implementation directly, so a
## script override is never invoked. Instead, Curve3D emits `changed` on every mutation
## (add/remove/move point, bake, closed, tilt). We subscribe to it and reconcile the metadata
## arrays to point_count, which covers all edit paths including Path3D gizmo editing.

func _on_changed() -> void:
	_reconcile_metadata()


## Reconcile metadata array lengths to Curve3D.point_count. Pads with defaults on growth,
## truncates on shrink. Called on every Curve3D.changed and lazily from accessors.
func _reconcile_metadata() -> void:
	var count: int = point_count
	_pad_or_trim(point_widths, count, default_width)
	_pad_or_trim_int_array(point_recipes, count, default_recipe)
	_pad_or_trim(point_recipe_params, count, default_recipe_param)
	_pad_or_trim_int_array(point_flags, count, default_flags)


func _pad_or_trim(array: PackedFloat32Array, count: int, fill: float) -> void:
	var delta: int = count - array.size()
	if delta > 0:
		for i in delta:
			array.append(fill)
	elif delta < 0:
		array.resize(count)


func _pad_or_trim_int_array(array: Array, count: int, fill: int) -> void:
	var delta: int = count - array.size()
	if delta > 0:
		for i in delta:
			array.append(fill)
	elif delta < 0:
		array.resize(count)


# --- Per-point accessors --------------------------------------------------------------------

func get_point_width(index: int) -> float:
	_reconcile_metadata()
	return point_widths[clampi(index, 0, point_widths.size() - 1)]


func set_point_width(index: int, value: float) -> void:
	_reconcile_metadata()
	point_widths[clampi(index, 0, point_widths.size() - 1)] = value


func get_point_recipe(index: int) -> SegmentRecipe:
	_reconcile_metadata()
	return point_recipes[clampi(index, 0, point_recipes.size() - 1)]


func set_point_recipe(index: int, value: SegmentRecipe) -> void:
	_reconcile_metadata()
	point_recipes[clampi(index, 0, point_recipes.size() - 1)] = value


func get_point_recipe_param(index: int) -> float:
	_reconcile_metadata()
	return point_recipe_params[clampi(index, 0, point_recipe_params.size() - 1)]


func set_point_recipe_param(index: int, value: float) -> void:
	_reconcile_metadata()
	point_recipe_params[clampi(index, 0, point_recipe_params.size() - 1)] = value


func get_point_flags(index: int) -> int:
	_reconcile_metadata()
	return point_flags[clampi(index, 0, point_flags.size() - 1)]


func set_point_flags(index: int, value: int) -> void:
	_reconcile_metadata()
	point_flags[clampi(index, 0, point_flags.size() - 1)] = value


func has_point_flag(index: int, flag: SplinePointFlags) -> bool:
	return get_point_flags(index) & flag != 0


# --- Traversal helpers ----------------------------------------------------------------------
# NOTE: Curve3D baked sampling and closest-point queries are all LOCAL-SPACE. Positions come
# back relative to the curve's owning Path3D origin, and query points must be transformed into
# that local space first (world_to_local). Use the world-space wrappers on TrackSpline when
# dealing with gameplay positions (pods, AI, laps), not these directly.

## Total spline length in meters (baked).
func get_total_length() -> float:
	return get_baked_length()


## Forward (tangent) direction at a baked offset, from two close samples. Local space.
func sample_forward(offset: float, delta: float = 0.01) -> Vector3:
	var a: Vector3 = sample_baked(offset - delta)
	var b: Vector3 = sample_baked(offset + delta)
	return (b - a).normalized()


## Surface up (normal) direction at a baked offset. Uses the baked up vector when
## up_vector_enabled is on; otherwise returns world up. Local space.
func sample_normal(offset: float) -> Vector3:
	if up_vector_enabled:
		return sample_baked_up_vector(offset)
	return Vector3.UP


## Surface normal at a baked offset derived from forward tangent + banked lateral, for
## spans where the baked up vector is not configured. lateral = forward × world_up. Local space.
func sample_normal_banked(offset: float, forward: Vector3, bank: float) -> Vector3:
	var lateral: Vector3 = forward.cross(Vector3.UP).normalized()
	var rot: Basis = Basis(forward, bank)
	return (rot * lateral).cross(forward).normalized()


## Nearest offset in meters along the spline to a LOCAL-SPACE point. Convert world points with
## the owning Path3D's world_to_local before calling — see TrackSpline.project_world.
func project(point: Vector3) -> float:
	return get_closest_offset(point)


## Wrap a raw offset into [0, total_length) for cyclic splines; clamp for non-cyclic.
func wrap_offset(offset: float) -> float:
	var total: float = get_baked_length()
	if cyclic and total > 0.0:
		return fposmod(offset, total)
	return clampf(offset, 0.0, total)


## Convert normalized t ∈ [0,1] to a baked offset in meters.
func t_to_offset(t: float) -> float:
	return t * get_baked_length()


## Convert a baked offset in meters to normalized t ∈ [0,1].
func offset_to_t(offset: float) -> float:
	var total: float = get_baked_length()
	return offset / total if total > 0.0 else 0.0


# --- Authoring ------------------------------------------------------------------------------

## Copy all points from a source Curve3D (plain or Spline) into this spline, replacing any
## existing points. Copies position, in/out handles, and tilt; when the source is also a
## Spline, its metadata arrays (width, recipe, recipe param, flags) are copied too. Plain
## Curve3D sources leave metadata at the current defaults. Editor/authoring tool only.
func import_from(source: Curve3D) -> void:
	if source == null:
		push_warning("Spline '%s': import_from received a null curve." % resource_path)
		return
	if source == self:
		push_warning("Spline '%s': import_from called with self — no-op." % resource_path)
		return
	clear_points()
	for i in source.point_count:
		add_point(
			source.get_point_position(i),
			source.get_point_in(i),
			source.get_point_out(i),
			-1
		)
		set_point_tilt(i, source.get_point_tilt(i))
	closed = source.closed
	up_vector_enabled = source.up_vector_enabled
	if source is Spline:
		var src: Spline = source
		point_widths = src.point_widths.duplicate()
		point_recipes = src.point_recipes.duplicate()
		point_recipe_params = src.point_recipe_params.duplicate()
		point_flags = src.point_flags.duplicate()
	notify_property_list_changed()
