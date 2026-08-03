@tool
extends EditorScript

# Point this to your exact saved animation library file path
# (the scene Arcwing.tscn loads this .tres via libraries/Arcwing)
const LIBRARY_PATH : String = "res://Content/Animations/Arcwing.tres"

func _run() -> void:
	mirror_left_to_right_animations()

func mirror_left_to_right_animations() -> void:
	if not ResourceLoader.exists(LIBRARY_PATH):
		print("Error: Animation library file not found: ", LIBRARY_PATH)
		return

	var library: AnimationLibrary = ResourceLoader.load(LIBRARY_PATH)
	if library == null:
		print("Error: Failed to load animation library.")
		return

	var added_tracks: int = 0
	for anim_name in library.get_animation_list():
		var anim: Animation = library.get_animation(anim_name)
		var mirrored: int = _mirror_animation(anim)
		added_tracks += mirrored
		if mirrored > 0:
			print("Mirrored %d track(s) in animation '%s'." % [mirrored, anim_name])

	# Save the updated library asset back to disk (text so it stays diff-friendly)
	var error: Error = ResourceSaver.save(library, LIBRARY_PATH)
	if error == OK:
		print("Successfully mirrored %d L_ track(s) to R_ tracks in %s." % [added_tracks, LIBRARY_PATH])
	else:
		print("Failed to save animation library. Error code: ", error)

# Duplicates every L_ track in `anim` as an R_ track with mirrored key values.
# Returns the number of tracks added.
func _mirror_animation(anim: Animation) -> int:
	var added: int = 0
	var original_track_count: int = anim.get_track_count()

	for i in range(original_track_count):
		var src_path: NodePath = anim.track_get_path(i)
		var mirror_path: NodePath = _mirror_path(src_path)

		# Not a Left-wing track, or there is no Right-wing counterpart to make.
		if mirror_path == src_path:
			continue

		# Avoid duplicating if the Right track already exists (re-run safe).
		if _has_track(anim, mirror_path):
			continue

		var src_type: Animation.TrackType = anim.track_get_type(i)
		var new_idx: int = anim.add_track(src_type)
		anim.track_set_path(new_idx, mirror_path)

		# Preserve interpolation (linear/cubic), enabled state, and loop-wrap.
		anim.track_set_interpolation_type(new_idx, anim.track_get_interpolation_type(i))
		anim.track_set_enabled(new_idx, anim.track_is_enabled(i))
		anim.track_set_interp_loop_wrap(new_idx, anim.track_get_interp_loop_wrap(i))

		# Copy every keyframe with the mirrored value and its easing transition.
		var key_count: int = anim.track_get_key_count(i)
		for k in range(key_count):
			var time: float = anim.track_get_key_time(i, k)
			var value: Variant = anim.track_get_key_value(i, k)
			var transition: float = anim.track_get_key_transition(i, k)
			anim.track_insert_key(new_idx, time, _mirror_value(value), transition)

		added += 1

	return added

# Replaces an "L_" path segment with "R_" (bone name in the track path), e.g.
# NodePath("Skeleton3D:L_wing_root") -> NodePath("Skeleton3D:R_wing_root").
# Returns the original path unchanged when no L_ segment is present.
func _mirror_path(path: NodePath) -> NodePath:
	var names: PackedStringArray = path.get_names()
	var subnames: PackedStringArray = path.get_subnames()
	var changed: bool = false

	for s in range(subnames.size()):
		if subnames[s].begins_with("L_"):
			subnames[s] = "R_" + subnames[s].substr(2)
			changed = true

	if not changed:
		return path

	return NodePath(names, subnames, path.is_absolute())

# Negates the X component of a key value to mirror it across the sagittal
# (x = 0) plane: positions negate x, and rotations flip the two axes
# perpendicular to the mirror plane.
func _mirror_value(value: Variant) -> Variant:
	if value is Vector3:
		return Vector3(-value.x, value.y, value.z)
	elif value is Vector2:
		return Vector2(-value.x, value.y)
	elif value is Quaternion:
		# Mirroring a rotation across x = 0 keeps the x-axis rotation and
		# negates the y/z components. Negating x AND w is the same rotation
		# (a quaternion and its negation are equivalent), so this is valid.
		return Quaternion(-value.x, value.y, value.z, -value.w)
	elif value is Transform3D:
		var t: Transform3D = value
		t.origin.x = -t.origin.x
		t.basis = _mirror_basis(t.basis)
		return t
	elif value is Basis:
		return _mirror_basis(value)
	return value

# Reflects a Basis across the x = 0 plane: M * B * M with M = diag(-1, 1, 1),
# i.e. negate the x-components of the y/z columns and the y/z of the x column.
func _mirror_basis(b: Basis) -> Basis:
	return Basis(
		Vector3(b.x.x, -b.x.y, -b.x.z),
		Vector3(-b.y.x, b.y.y, b.y.z),
		Vector3(-b.z.x, b.z.y, b.z.z)
	)

func _has_track(anim: Animation, path: NodePath) -> bool:
	for i in range(anim.get_track_count()):
		if anim.track_get_path(i) == path:
			return true
	return false
