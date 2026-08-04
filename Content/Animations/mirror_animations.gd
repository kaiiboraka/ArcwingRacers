@tool
extends EditorScript

## Bakes a "_flipped" twin of every animation in the live Arcwing library so the
## right wing mirrors the left wing's motion.
##
## The two wings are SEPARATE FBX models (SM_Wing_Left.fbx / SM_Wing_Right.fbx).
## The right FBX already authors its base (bind) pose as a mirror, so its per-bone
## rest differs from a plain reflection of the left rest (measured mean ~3.18 in
## world space). A naive reflection of the whole skeleton therefore double-mirrors
## the right base and flips face winding (inside-out meshes).
##
## Correct approach - a delta mirror applied over the right's OWN rest (bind) pose,
## all in skeleton-local space (each skeleton's global pose accumulates pose-only;
## rest is not folded in):
##
##     delta(b)   = L_anim(b) * L_rest(b)^-1
##     R_anim(b)  = M * delta(b) * M * R_rest(b)
##     R_local(b) = R_anim(parent)^-1 * R_anim(b)      (top-down)
##
## with M = diag(-1, 1, 1) (sagittal reflection). At rest delta = identity, so
## R_anim = R_rest exactly: the right wing stays at its authored base pose with
## correct winding (det(M) * det(M) = +1). During animation the left wing's motion
## relative to its own rest is mirrored and applied over the right bind.
##
## Bones the source clip does NOT key get no keys in the twin: an un-keyed bone
## inherits its parent's delta, which resolves to staying at its own rest local -
## the same behaviour the left wing has at runtime, and it keeps the twin's track
## structure identical to the base clip (paths, types, key times all preserved).
##
## Rest/bind data is read from the FBX skeleton imports, not from the library.
## Run from the Script tab (or via tests/test_mirror_wing_anims.gd). Re-runs are
## safe: existing *_flipped clips are removed and re-added.

const LIBRARY_PATH : String = "res://Content/Animations/Arcwing.res"
const LEFT_FBX_PATH : String = "res://Content/Models/SM_Wing_Left.fbx"
const RIGHT_FBX_PATH : String = "res://Content/Models/SM_Wing_Right.fbx"
const FLIP_SUFFIX : String = "_flipped"
const MIRROR : Vector3 = Vector3(-1.0, 1.0, 1.0)

var _prepared : bool = false
var _left_inst : Node = null
var _right_inst : Node = null
var _left_skel : Skeleton3D = null
var _right_skel : Skeleton3D = null

## Per-bone data aligned to the LEFT skeleton's bone indices.
var _bone_names : Array[String] = []
var _left_parent : Array[int] = []                  # left bone index, or -1
var _left_rest_local : Array[Transform3D] = []
var _left_rest_global : Array[Transform3D] = []
var _right_rest_local : Array[Transform3D] = []
var _right_rest_global : Array[Transform3D] = []
var _left_bone_index : Dictionary = {}              # name -> index
var _order : Array[int] = []                        # left indices, parents first


func _run() -> void:
	_ensure_prepared()
	bake_mirrored_animations()
	_cleanup()


func _ensure_prepared() -> bool:
	if _prepared:
		return true
	if not ResourceLoader.exists(LEFT_FBX_PATH) or not ResourceLoader.exists(RIGHT_FBX_PATH):
		printerr("Mirror: FBX skeleton files not found (", LEFT_FBX_PATH, ", ", RIGHT_FBX_PATH, ")")
		return false
	var left_scene : PackedScene = ResourceLoader.load(LEFT_FBX_PATH)
	var right_scene : PackedScene = ResourceLoader.load(RIGHT_FBX_PATH)
	if left_scene == null or right_scene == null:
		printerr("Mirror: failed to load FBX skeleton scenes")
		return false
	_left_inst = left_scene.instantiate()
	_right_inst = right_scene.instantiate()
	_left_skel = _find_skeleton(_left_inst)
	_right_skel = _find_skeleton(_right_inst)
	if _left_skel == null or _right_skel == null:
		printerr("Mirror: no Skeleton3D found in wing FBX scenes")
		_cleanup()
		return false

	var count : int = _left_skel.get_bone_count()
	_bone_names.resize(count)
	_left_parent.resize(count)
	_left_rest_local.resize(count)
	_left_rest_global.resize(count)
	_right_rest_local.resize(count)
	_right_rest_global.resize(count)
	for i in range(count):
		_bone_names[i] = _left_skel.get_bone_name(i)
		_left_parent[i] = _left_skel.get_bone_parent(i)
		_left_rest_local[i] = _left_skel.get_bone_rest(i)
		_left_bone_index[_bone_names[i]] = i

	_order = _parent_first_order(count, _left_parent)

	for idx in _order:
		var parent : int = _left_parent[idx]
		if parent < 0:
			_left_rest_global[idx] = _left_rest_local[idx]
		else:
			_left_rest_global[idx] = _left_rest_global[parent] * _left_rest_local[idx]

	var right_parents : Array[int] = []
	right_parents.resize(_right_skel.get_bone_count())
	for i in range(_right_skel.get_bone_count()):
		right_parents[i] = _right_skel.get_bone_parent(i)
	var right_order : Array[int] = _parent_first_order(_right_skel.get_bone_count(), right_parents)
	var right_global : Dictionary = {}
	for ridx in right_order:
		var rp : int = _right_skel.get_bone_parent(ridx)
		var local : Transform3D = _right_skel.get_bone_rest(ridx)
		if rp < 0:
			right_global[ridx] = local
		else:
			right_global[ridx] = right_global[rp] * local

	for i in range(count):
		var name : String = _bone_names[i]
		var ridx : int = _right_skel.find_bone(name)
		if ridx < 0:
			printerr("Mirror: right skeleton missing bone '", name, "'")
			_cleanup()
			return false
		_right_rest_local[i] = _right_skel.get_bone_rest(ridx)
		_right_rest_global[i] = right_global[ridx]

	_prepared = true
	return true


func _cleanup() -> void:
	if _left_inst != null:
		_left_inst.free()
		_left_inst = null
	if _right_inst != null:
		_right_inst.free()
		_right_inst = null
	_left_skel = null
	_right_skel = null


func _find_skeleton(node : Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for c in node.get_children():
		var found := _find_skeleton(c)
		if found != null:
			return found
	return null


func _parent_first_order(bone_count : int, parents : Array) -> Array[int]:
	var order : Array[int] = []
	var queue : Array[int] = []
	for i in range(bone_count):
		if parents[i] < 0:
			queue.append(i)
	while queue.size() > 0:
		var b : int = queue.pop_front()
		order.append(b)
		for c in range(bone_count):
			if parents[c] == b:
				queue.append(c)
	return order


## True when `bone_name` exists in the (left) skeleton. Used by the test suite to
## skip tracks that reference non-skeleton properties.
func has_bone(bone_name : String) -> bool:
	return _left_bone_index.has(bone_name)


## Right wing's rest (bind) local for a bone, aligned to the left bone index.
func right_rest_local(bone_name : String) -> Transform3D:
	if not _left_bone_index.has(bone_name):
		return Transform3D.IDENTITY
	return _right_rest_local[_left_bone_index[bone_name]]


func bake_mirrored_animations() -> void:
	if not _ensure_prepared():
		printerr("Mirror: skeleton data unavailable; not baking.")
		return
	if not ResourceLoader.exists(LIBRARY_PATH):
		printerr("Mirror: animation library file not found: ", LIBRARY_PATH)
		return
	var library : AnimationLibrary = ResourceLoader.load(LIBRARY_PATH)
	if library == null:
		printerr("Mirror: failed to load animation library.")
		return
	var baked : int = 0
	for anim_name in library.get_animation_list():
		if String(anim_name).ends_with(FLIP_SUFFIX):
			continue
		var src : Animation = library.get_animation(anim_name)
		var flipped_name : String = String(anim_name) + FLIP_SUFFIX
		var flipped : Animation = _make_flipped(src, flipped_name)
		if flipped == null:
			continue
		if library.has_animation(flipped_name):
			library.remove_animation(flipped_name)
		var err : Error = library.add_animation(flipped_name, flipped)
		if err != OK:
			printerr("Mirror: add_animation '", flipped_name, "' failed with error ", err)
			continue
		baked += 1
	var error : Error = ResourceSaver.save(library, LIBRARY_PATH)
	if error == OK:
		print("Mirror: baked %d flipped animation(s) into %s." % [baked, LIBRARY_PATH])
	else:
		printerr("Mirror: failed to save animation library. Error code: ", error)


func _make_flipped(src : Animation, flipped_name : String) -> Animation:
	var bone_tracks : Dictionary = {}    # name -> {"pos": idx, "rot": idx}
	var verbatim_tracks : Array[int] = []
	for i in range(src.get_track_count()):
		var t : Animation.TrackType = src.track_get_type(i)
		if t != Animation.TYPE_POSITION_3D and t != Animation.TYPE_ROTATION_3D:
			verbatim_tracks.append(i)
			continue
		var path : NodePath = src.track_get_path(i)
		var bone_name : String = ""
		if path.get_subname_count() > 0:
			bone_name = String(path.get_subname(0))
		if bone_name != "" and _left_bone_index.has(bone_name):
			if not bone_tracks.has(bone_name):
				bone_tracks[bone_name] = {}
			if t == Animation.TYPE_POSITION_3D:
				bone_tracks[bone_name]["pos"] = i
			else:
				bone_tracks[bone_name]["rot"] = i
		else:
			verbatim_tracks.append(i)

	var times : Array[float] = []
	for bone_name in bone_tracks:
		var pinfo : Dictionary = bone_tracks[bone_name]
		for k in range(src.track_get_key_count(pinfo["pos"])):
			var tk : float = src.track_get_key_time(pinfo["pos"], k)
			if not times.has(tk):
				times.append(tk)
		for k in range(src.track_get_key_count(pinfo["rot"])):
			var tk : float = src.track_get_key_time(pinfo["rot"], k)
			if not times.has(tk):
				times.append(tk)
	times.sort()

	var out : Animation = Animation.new()
	out.resource_name = flipped_name
	out.length = src.length
	out.loop_mode = src.loop_mode
	out.step = src.step

	var out_track_of : Dictionary = {}   # src track idx -> out track idx
	for i in verbatim_tracks:
		out_track_of[i] = _copy_track(out, src, i, true)
	for bone_name in bone_tracks:
		var pinfo : Dictionary = bone_tracks[bone_name]
		if pinfo.has("pos"):
			out_track_of[pinfo["pos"]] = _copy_track(out, src, pinfo["pos"], false)
		if pinfo.has("rot"):
			out_track_of[pinfo["rot"]] = _copy_track(out, src, pinfo["rot"], false)

	for t in times:
		var l_anim_local : Dictionary = {}
		for bone_name in bone_tracks:
			l_anim_local[bone_name] = _sample_bone_local(src, bone_tracks[bone_name], t)

		var l_anim_global : Dictionary = {}
		var delta : Dictionary = {}
		var r_anim_global : Dictionary = {}
		for idx in _order:
			var name : String = _bone_names[idx]
			var parent : int = _left_parent[idx]
			var local : Transform3D
			if l_anim_local.has(name):
				local = l_anim_local[name]
			else:
				local = _left_rest_local[idx]
			if parent < 0:
				l_anim_global[name] = local
			else:
				l_anim_global[name] = l_anim_global[_bone_names[parent]] * local
			var d : Transform3D = l_anim_global[name] * _left_rest_global[idx].affine_inverse()
			if parent >= 0 and not l_anim_local.has(name):
				d = delta[_bone_names[parent]]
			delta[name] = d
			r_anim_global[name] = _mirror_delta(d) * _right_rest_global[idx]

		for bone_name in bone_tracks:
			var idx : int = _left_bone_index[bone_name]
			var parent : int = _left_parent[idx]
			var r_local : Transform3D
			if parent < 0:
				r_local = r_anim_global[bone_name]
			else:
				r_local = r_anim_global[_bone_names[parent]].affine_inverse() * r_anim_global[bone_name]
			var pinfo : Dictionary = bone_tracks[bone_name]
			if pinfo.has("pos"):
				out.track_insert_key(
					out_track_of[pinfo["pos"]], t, r_local.origin,
					_src_transition(src, pinfo["pos"], t)
				)
			if pinfo.has("rot"):
				out.track_insert_key(
					out_track_of[pinfo["rot"]], t, r_local.basis.get_rotation_quaternion(),
					_src_transition(src, pinfo["rot"], t)
				)
	return out


## Copies a source track's structure (and, when `verbatim`, its keys unchanged).
func _copy_track(out : Animation, src : Animation, i : int, verbatim : bool) -> int:
	var idx : int = out.add_track(src.track_get_type(i))
	out.track_set_path(idx, src.track_get_path(i))
	out.track_set_interpolation_type(idx, src.track_get_interpolation_type(i))
	out.track_set_interpolation_loop_wrap(idx, src.track_get_interpolation_loop_wrap(i))
	out.track_set_enabled(idx, src.track_is_enabled(i))
	if verbatim:
		var key_count : int = src.track_get_key_count(i)
		for k in range(key_count):
			out.track_insert_key(
				idx,
				src.track_get_key_time(i, k),
				src.track_get_key_value(i, k),
				src.track_get_key_transition(i, k)
			)
	return idx


func _sample_bone_local(src : Animation, pinfo : Dictionary, t : float) -> Transform3D:
	var pos : Vector3 = Vector3.ZERO
	var quat : Quaternion = Quaternion.IDENTITY
	if pinfo.has("pos"):
		pos = src.track_interpolate_value(pinfo["pos"], t)
	if pinfo.has("rot"):
		quat = src.track_interpolate_value(pinfo["rot"], t)
	return Transform3D(quat, pos)


func _mirror_delta(d : Transform3D) -> Transform3D:
	var m := Transform3D(Basis.from_scale(MIRROR), Vector3.ZERO)
	return m * d * m


func _src_transition(src : Animation, track : int, t : float) -> float:
	for k in range(src.track_get_key_count(track)):
		if is_equal_approx(src.track_get_key_time(track, k), t):
			return src.track_get_key_transition(track, k)
	return 0.0
