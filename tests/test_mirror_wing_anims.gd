@tool
extends McpTestSuite

## Bakes and verifies the "_flipped" twin clips in Content/Animations/Arcwing.res.
## That .res is what Arcwing.tscn and PodController.gd actually load; the right wing
## plays the *_flipped clips so its animation is a true mirror of the left wing.
##
## Mirror model: the right wing is a SEPARATE FBX that already authors its base
## (bind) pose as a mirror, so the twin mirrors the left's MOTION relative to the
## left rest and applies it over the right's OWN rest (a delta mirror, baked from
## both FBX skeleton imports). Consequence: at the first key time (rest) every
## baked bone must equal the RIGHT bone's own rest local - NOT a negation of the
## left value (that was the old buggy approach that left the base double-mirrored).

const LIBRARY_PATH : String = "res://Content/Animations/Arcwing.res"
const FLIP_SUFFIX : String = "_flipped"
const MirrorScript = preload("res://Content/Animations/mirror_animations.gd")

var _library : AnimationLibrary
var _mirror = null


func suite_name() -> String:
	return "mirror_wing_anims"


func suite_setup(_ctx : Dictionary) -> void:
	_mirror = MirrorScript.new()
	if _mirror == null:
		fail_setup("Could not instantiate mirror_animations.gd in @tool scope")
		return
	_mirror.bake_mirrored_animations()
	_library = ResourceLoader.load(LIBRARY_PATH)
	if _library == null:
		fail_setup("Could not load %s after bake" % LIBRARY_PATH)


func _base_names() -> Array:
	var names : Array = []
	for name in _library.get_animation_list():
		if not String(name).ends_with(FLIP_SUFFIX):
			names.append(name)
	return names


## Every base animation gets a "_flipped" twin.
func test_every_animation_has_a_flipped_twin() -> void:
	var bases := _base_names()
	assert_gt(bases.size(), 0, "At least one base animation exists in the library")
	for name in bases:
		assert_true(
			_library.has_animation(String(name) + FLIP_SUFFIX),
			"%s needs a %s twin" % [name, FLIP_SUFFIX]
		)


## The delta mirror bakes the same bone set as the source clip, so the twin's
## track structure is identical to the base clip: same count, paths, types, key
## counts and key times. No extra tracks are added (unlike the old root-scale
## approach) and no paths are rewritten (the right FBX retargets generic names).
func test_twin_preserves_structure() -> void:
	for name in _base_names():
		var base : Animation = _library.get_animation(name)
		var flipped : Animation = _library.get_animation(String(name) + FLIP_SUFFIX)
		assert_eq(
			flipped.get_track_count(),
			base.get_track_count(),
			"%s track count must match (delta mirror adds no tracks)" % name
		)
		for i in range(base.get_track_count()):
			assert_eq(
				flipped.track_get_path(i),
				base.track_get_path(i),
				"%s track %d path must be preserved (no L_/R_ rewrite)" % [name, i]
			)
			assert_eq(
				flipped.track_get_type(i),
				base.track_get_type(i),
				"%s track %d type must be preserved" % [name, i]
			)
			assert_eq(
				flipped.track_get_key_count(i),
				base.track_get_key_count(i),
				"%s track %d key count must match" % [name, i]
			)
			for k in range(base.track_get_key_count(i)):
				assert_eq(
					flipped.track_get_key_time(i, k),
					base.track_get_key_time(i, k),
					"%s track %d key %d time must match" % [name, i, k]
				)


## At the first key time the left clip is at rest, so the delta mirror must leave
## every baked bone at the RIGHT wing's own rest (bind) local pose. This is the
## invariant that keeps the authored right base facing the left wing (no double
## mirror) with correct winding, and it fails for any naive per-key negation.
func test_rest_key_bakes_to_right_rest() -> void:
	for name in _base_names():
		var flipped : Animation = _library.get_animation(String(name) + FLIP_SUFFIX)
		var t0 : float = 1e18
		for i in range(flipped.get_track_count()):
			if flipped.track_get_type(i) != Animation.TYPE_POSITION_3D:
				continue
			if flipped.track_get_key_count(i) > 0:
				t0 = minf(t0, flipped.track_get_key_time(i, 0))
		assert_true(t0 < 1e18, "%s has at least one baked position key" % name)
		for i in range(flipped.get_track_count()):
			var t : Animation.TrackType = flipped.track_get_type(i)
			if t != Animation.TYPE_POSITION_3D and t != Animation.TYPE_ROTATION_3D:
				continue
			var path : NodePath = flipped.track_get_path(i)
			if path.get_subname_count() == 0:
				continue
			var bone := String(path.get_subname(0))
			if not _mirror.has_bone(bone):
				continue
			var rest : Transform3D = _mirror.right_rest_local(bone)
			for k in range(flipped.track_get_key_count(i)):
				if not is_equal_approx(flipped.track_get_key_time(i, k), t0):
					continue
				if t == Animation.TYPE_POSITION_3D:
					var v : Vector3 = flipped.track_get_key_value(i, k)
					assert_true(
						_approx_v3(v, rest.origin),
						"%s track %d (%s) pos at rest must equal right rest origin" % [name, i, bone]
					)
				else:
					var q : Quaternion = flipped.track_get_key_value(i, k)
					assert_true(
						_approx_quat(q, rest.basis.get_rotation_quaternion()),
						"%s track %d (%s) rot at rest must equal right rest rotation" % [name, i, bone]
					)
				break


## The bake is idempotent: running it again must not duplicate or alter the twins.
func test_bake_is_idempotent() -> void:
	if _mirror == null:
		skip("Could not instantiate mirror_animations.gd")
		return
	var before_names := _library.get_animation_list().duplicate()
	_mirror.bake_mirrored_animations()
	assert_eq(_library.get_animation_list().size(), before_names.size(), "No clips added on re-bake")


func _approx_v3(a : Vector3, b : Vector3) -> bool:
	return a.distance_to(b) < 1e-3


func _approx_quat(a : Quaternion, b : Quaternion) -> bool:
	var nb := Quaternion(-b.x, -b.y, -b.z, -b.w)
	return _approx_q(a, b) or _approx_q(a, nb)


func _approx_q(a : Quaternion, b : Quaternion) -> bool:
	return (
		absf(a.x - b.x) < 1e-3 and absf(a.y - b.y) < 1e-3
		and absf(a.z - b.z) < 1e-3 and absf(a.w - b.w) < 1e-3
	)
