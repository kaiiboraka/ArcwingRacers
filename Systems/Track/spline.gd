@tool
class_name Spline
extends Curve3D;

## Recipe for the span AFTER a point. Decides whether geometry is generated from the spline
## or left to modeled terrain (ADR 0010).
enum SegmentRecipe {
	## No generated geometry — modeled terrain/level mesh stands as-is. The spline still drives
	## racing line, AI path, lap, and respawn data here.
	NONE,
	## Generate a flat ribbon surface + side walls from the spline (width from point_data.width).
	ROAD,
	## Generate a tube: ribbon + side walls + roof. Height from point_data.recipe_param.
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
}

## Per-point track authoring data, indexed 1:1 with Curve3D.point_count. One editable object per
## point so a designer can select a point and modify all of its properties in one place —
## width, recipe, recipe param, flags, and tilt (ADR 0010). Position and in/out handles stay in
## Curve3D (gizmo-edited); tilt is mirrored here and written back through set_point_tilt.[br]
## Intended purpose: single source of truth for all non-gizmo point data. The old parallel
## arrays (point_widths/point_recipes/point_recipe_params/point_flags) are gone — this array
## replaces them. Reconciles its length to point_count on every Curve3D.changed.[br]
## Editable per-point in the inspector: expand an entry to see/edit that point's data.
@export var point_data : Array[SplinePointData] = [];

## Whether the spline forms a closed loop (circuit) or runs point 0 → last once (rally).[br]
## Intended purpose: maps to Curve3D.closed — cyclic tracks wrap last→first and lap offsets
## mod the total length; non-cyclic tracks are always 1 lap.[br]
## True = circuit; false = point-to-point.
@export var cyclic : bool = true:
	get:
		return closed;
	set(value):
		closed = value;

@export_group("Recipe Defaults")
## Default width applied when a point is added without explicit metadata (editor authoring).[br]
## Intended purpose: new points in the Path3D gizmo get a sane road width immediately.[br]
## Higher = wider default road.
@export var default_width : float = 5.0;
## Default recipe applied when a point is added without explicit metadata (editor authoring).[br]
## Intended purpose: new points default to modeled-terrain spans so the spline never generates
## geometry the designer did not ask for.[br]
## NONE = modeled terrain; ROAD = generate ribbon.
@export var default_recipe : SegmentRecipe = SegmentRecipe.NONE;
## Default recipe scalar applied when a point is added without explicit metadata (editor authoring).[br]
## Intended purpose: TUNNEL spans start with a sane height.[br]
## Higher = taller default tunnel.
@export var default_recipe_param : float = 6.0;
## Default flags applied when a point is added without explicit metadata (editor authoring).[br]
## Intended purpose: new points are unflagged until explicitly marked.[br]
## 0 = no flags.
@export_flags("None","Start Finish","Waypoint","Respawn", "Path Entrance", "Path Exit"); 
var default_flags : int = SplinePointFlags.NONE;


func _init() -> void:
	bake_interval = 0.25;
	closed = true;
	changed.connect(_on_changed);
	call_deferred("_reconcile_point_data");


## --- Metadata sync: hook Curve3D's changed signal ------------------------------------------
## Native Curve3D methods (add_point, remove_point, set_point_count, clear_points) cannot be
## overridden in GDScript — the engine calls its internal C++ implementation directly, so a
## script override is never invoked. Instead, Curve3D emits `changed` on every mutation
## (add/remove/move point, bake, closed, tilt). We subscribe to it and reconcile point_data to
## point_count, which covers all edit paths including Path3D gizmo editing.

func _on_changed() -> void:
	_reconcile_point_data();


## Reconcile point_data length to Curve3D.point_count. Creates default-backed entries on growth
## (reading current tilt from Curve3D), drops extras on shrink. Called on every Curve3D.changed.
func _reconcile_point_data() -> void:
	var count : int = point_count;
	while point_data.size() > count:
		var pd : SplinePointData = point_data.pop_back();
		if pd and pd.changed.is_connected(_on_point_data_changed):
			pd.changed.disconnect(_on_point_data_changed);
	while point_data.size() < count:
		var index : int = point_data.size();
		var pd : SplinePointData = SplinePointData.new();
		pd.resource_local_to_scene = true;
		pd.width = default_width;
		pd.recipe = default_recipe;
		pd.recipe_param = default_recipe_param;
		pd.flags = default_flags;
		pd.tilt = get_point_tilt(index);
		pd.changed.connect(_on_point_data_changed);
		point_data.append(pd);


## Push a designer's edit back out of point_data. Tilt writes through to Curve3D's native tilt
## (set_point_tilt fires Curve3D.changed itself, which notifies consumers). Metadata-only
## changes have no Curve3D side effect, so emit `changed` manually so geometry/racing-line
## consumers rebuild. The native tilt is compared (get_point_tilt), not point_data, so an edit
## only writes through when it actually differs from the baked curve value.
func _on_point_data_changed(pd : SplinePointData) -> void:
	var index : int = point_data.find(pd);
	if index == -1 or index >= point_count:
		return;
	var native_tilt : float = get_point_tilt(index);
	var tilt_dirty : bool = not is_equal_approx(native_tilt, pd.tilt);
	if tilt_dirty:
		set_point_tilt(index, pd.tilt);
	if not tilt_dirty:
		changed.emit();


# --- Per-point accessors --------------------------------------------------------------------
## Returns the SplinePointData for a point index, or null if out of range. Use this instead of
## touching point_data directly when you need one point's data.
func get_point_data(index : int) -> SplinePointData:
	_reconcile_point_data();
	if point_data.is_empty():
		return null;
	return point_data[clampi(index, 0, point_data.size() - 1)];


func get_point_width(index : int) -> float:
	var pd := get_point_data(index);
	return pd.width if pd else default_width;


func set_point_width(index : int, value : float) -> void:
	var pd := get_point_data(index);
	if pd:
		pd.width = value;


func get_point_recipe(index : int) -> SegmentRecipe:
	var pd := get_point_data(index);
	return pd.recipe if pd else default_recipe;


func set_point_recipe(index : int, value : SegmentRecipe) -> void:
	var pd := get_point_data(index);
	if pd:
		pd.recipe = value;


func get_point_recipe_param(index : int) -> float:
	var pd := get_point_data(index);
	return pd.recipe_param if pd else default_recipe_param;


func set_point_recipe_param(index : int, value : float) -> void:
	var pd := get_point_data(index);
	if pd:
		pd.recipe_param = value;


func get_point_flags(index : int) -> int:
	var pd := get_point_data(index);
	return pd.flags if pd else default_flags;


func set_point_flags(index : int, value : int) -> void:
	var pd := get_point_data(index);
	if pd:
		pd.flags = value;


func has_point_flag(index : int, flag : SplinePointFlags) -> bool:
	return get_point_flags(index) & flag != 0;


# --- Traversal helpers ----------------------------------------------------------------------
# NOTE: Curve3D baked sampling and closest-point queries are all LOCAL-SPACE. Positions come
# back relative to the curve's owning Path3D origin, and query points must be transformed into
# that local space first (world_to_local). Use the world-space wrappers on TrackSpline when
# dealing with gameplay positions (pods, AI, laps), not these directly.

## Total spline length in meters (baked).
func get_total_length() -> float:
	return get_baked_length();


## Forward (tangent) direction at a baked offset, from two close samples. Local space.
func sample_forward(offset : float, delta : float = 0.01) -> Vector3:
	var a : Vector3 = sample_baked(offset - delta);
	var b : Vector3 = sample_baked(offset + delta);
	return (b - a).normalized();


## Surface up (normal) direction at a baked offset. Uses the baked up vector when
## up_vector_enabled is on; otherwise returns world up. Local space.
func sample_normal(offset : float) -> Vector3:
	if up_vector_enabled:
		return sample_baked_up_vector(offset);
	return Vector3.UP;


## Surface normal at a baked offset derived from forward tangent + banked lateral, for
## spans where the baked up vector is not configured. lateral = forward × world_up. Local space.
func sample_normal_banked(offset : float, forward : Vector3, bank : float) -> Vector3:
	var lateral : Vector3 = forward.cross(Vector3.UP).normalized();
	var rot : Basis = Basis(forward.normalized(), bank);
	return (rot * lateral).cross(forward).normalized();


## Nearest offset in meters along the spline to a LOCAL-SPACE point. Convert world points with
## the owning Path3D's world_to_local before calling — see TrackSpline.project_world.
func project(point : Vector3) -> float:
	return get_closest_offset(point);


## Wrap a raw offset into [0, total_length) for cyclic splines; clamp for non-cyclic.
func wrap_offset(offset : float) -> float:
	var total : float = get_baked_length();
	if cyclic and total > 0.0:
		return fposmod(offset, total);
	return clampf(offset, 0.0, total);


## Convert normalized t ∈ [0,1] to a baked offset in meters.
func t_to_offset(t : float) -> float:
	return t * get_baked_length();


## Convert a baked offset in meters to normalized t ∈ [0,1].
func offset_to_t(offset : float) -> float:
	var total : float = get_baked_length();
	return offset / total if total > 0.0 else 0.0;


# --- Authoring ------------------------------------------------------------------------------

## Copy all points from a source Curve3D (plain or Spline) into this spline, replacing any
## existing points. Copies position, in/out handles, and tilt; when the source is also a
## Spline, its per-point SplinePointData is copied too. Plain Curve3D sources leave metadata at
## the current defaults. Editor/authoring tool only.
func import_from(source : Curve3D) -> void:
	if source == null:
		push_warning("Spline '%s': import_from received a null curve." % resource_path);
		return;
	if source == self:
		push_warning("Spline '%s': import_from called with self — no-op." % resource_path);
		return;
	clear_points();
	for i in source.point_count:
		add_point(
			source.get_point_position(i),
			source.get_point_in(i),
			source.get_point_out(i),
			-1
		)
		set_point_tilt(i, source.get_point_tilt(i));
		var pd := get_point_data(i);
		if pd:
			pd.tilt = source.get_point_tilt(i);
	closed = source.closed;
	up_vector_enabled = source.up_vector_enabled;
	if source is Spline:
		var src : Spline = source;
		for i in src.point_data.size():
			var src_pd : SplinePointData = src.point_data[i];
			if src_pd == null:
				continue;
			var pd := get_point_data(i);
			if pd:
				pd.width = src_pd.width;
				pd.recipe = src_pd.recipe;
				pd.recipe_param = src_pd.recipe_param;
				pd.flags = src_pd.flags;
				pd.tilt = src_pd.tilt;
	notify_property_list_changed();
