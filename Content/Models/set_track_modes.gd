@tool
extends EditorScript

# Point this to your exact saved animation library file path
# (the scene Arcwing.tscn loads this .tres via libraries/Arcwing)
const LIBRARY_PATH : String = "res://Content/Animations/Arcwing.res"

# --- Interpolation mode applied to EVERY track -------------------------------
# Choose one:
#INTERPOLATION_NEAREST = 0
#No interpolation (nearest value).
#INTERPOLATION_LINEAR = 1
#Linear interpolation.
#INTERPOLATION_CUBIC = 2
#Cubic interpolation. This looks smoother than linear interpolation, but is more expensive to interpolate. Stick to INTERPOLATION_LINEAR for complex 3D animations imported from external software, even if it requires using a higher animation framerate in return.
#INTERPOLATION_LINEAR_ANGLE = 3
#Linear interpolation with shortest path rotation.
#Note: The result value is always normalized and may not match the key value.
#INTERPOLATION_CUBIC_ANGLE = 4
#Cubic interpolation with shortest path rotation.
#Note: The result value is always normalized and may not match the key value.
const INTERP_MODE : int = 2

# --- Loop mode applied to EVERY track ----------------------------------------
# Choose one:
#   true  = Wrap Loop  (interpolation wraps around so the animation loops seamlessly)
#   false = Clamp Loop (holds the last keyframe value once time passes the end)
const LOOP_WRAP : bool = false

func _run() -> void:
	apply_track_modes()

func apply_track_modes() -> void:
	if not ResourceLoader.exists(LIBRARY_PATH):
		print("Error: Animation library file not found: ", LIBRARY_PATH)
		return

	var library: AnimationLibrary = ResourceLoader.load(LIBRARY_PATH)
	if library == null:
		print("Error: Failed to load animation library.")
		return

	var updated_tracks: int = 0
	for anim_name in library.get_animation_list():
		var anim: Animation = library.get_animation(anim_name)
		var updated: int = _apply_modes_to_animation(anim)
		updated_tracks += updated
		if updated > 0:
			print("Updated %d track(s) in animation '%s'." % [updated, anim_name])

	var error: Error = ResourceSaver.save(library, LIBRARY_PATH)
	if error == OK:
		print("Successfully set interpolation mode %d and loop_wrap=%s on %d track(s) in %s." % [INTERP_MODE, LOOP_WRAP, updated_tracks, LIBRARY_PATH])
	else:
		print("Failed to save animation library. Error code: ", error)

# Sets the chosen interpolation + loop mode on every track in `anim`.
# Returns the number of tracks updated.
func _apply_modes_to_animation(anim: Animation) -> int:
	var updated: int = 0
	for i in range(anim.get_track_count()):
		anim.track_set_interpolation_type(i, INTERP_MODE)
		anim.track_set_interpolation_loop_wrap(i, LOOP_WRAP)
		updated += 1
	return updated
