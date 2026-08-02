@tool
extends McpTestSuite

## Verifies TrackSpline branch reconciliation when points are removed: branches whose
## endpoint is AT the removed index are deleted outright; endpoints BEYOND it shift down
## by one; endpoints BEFORE it are untouched. Covers both the atomic plugin path
## (remove_point_with_branches) and the built-in gizmo path (direct remove_point -> watcher).

const TrackSplineScript = preload("res://Systems/Track/track_spline.gd")

var _track: TrackSpline


func suite_name() -> String:
	return "track_branch_reconcile"


func setup() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root == null:
		skip("No scene open")
		return
	_track = TrackSplineScript.new()
	_track.name = "_McpTestTrackBranch"
	scene_root.add_child(_track)
	_track.owner = scene_root
	_build_path(_track.get_spline(), 6)


func teardown() -> void:
	if _track != null:
		var parent := _track.get_parent()
		if parent != null:
			parent.remove_child(_track)
		_track.queue_free()
		_track = null


## Add `count` points at unit X positions (index-aligned so _detect_removed_index can
## distinguish them) with default in/out handles.
func _build_path(spline: Spline, count: int) -> void:
	for i in count:
		spline.add_point(Vector3(i, 0, 0))
		spline.set_point_tilt(i, 0.0)


func _add_branch(from_index: int, to_index: int) -> BranchConnection:
	var connection := BranchConnection.new()
	connection.from_path_index = 0
	connection.from_point_index = from_index
	connection.to_path_index = 0
	connection.to_point_index = to_index
	connection.is_split = true
	_track.add_branch(connection)
	return connection


## A branch endpoint exactly ON a removed point must be deleted outright.
func test_removal_at_endpoint_deletes_branch() -> void:
	var branch := _add_branch(3, 1)
	_track.remove_point_with_branches(0, 3)
	assert_false(_track.branches.has(branch), "Branch anchored at removed point should be deleted")
	assert_eq(_track.get_spline().point_count, 5, "Point count should shrink by one")


## A branch endpoint BEYOND the removed index must shift down by one.
func test_removal_before_endpoint_shifts_down() -> void:
	var branch := _add_branch(4, 1)
	_track.remove_point_with_branches(0, 2)
	assert_true(_track.branches.has(branch), "Branch should survive a non-anchor removal")
	assert_eq(branch.from_point_index, 3, "from endpoint should shift 4 -> 3")
	assert_eq(branch.to_point_index, 1, "to endpoint before the removal is untouched")


## A branch endpoint BEFORE the removed index is untouched.
func test_removal_after_endpoint_leaves_endpoint() -> void:
	var branch := _add_branch(1, 2)
	_track.remove_point_with_branches(0, 4)
	assert_true(_track.branches.has(branch), "Branch should survive")
	assert_eq(branch.from_point_index, 1, "from endpoint before removal is untouched")
	assert_eq(branch.to_point_index, 2, "to endpoint before removal is untouched")


## Multiple branch endpoints on the same path reconcile independently.
func test_multiple_branches_reconcile_independently() -> void:
	var branch_a := _add_branch(5, 1)
	var branch_b := _add_branch(3, 4)
	_track.remove_point_with_branches(0, 2)
	assert_eq(branch_a.from_point_index, 4, "branch_a endpoint 5 -> 4")
	assert_eq(branch_b.from_point_index, 2, "branch_b endpoint 3 -> 2")
	assert_eq(branch_b.to_point_index, 3, "branch_b to endpoint 4 -> 3")
	assert_eq(_track.branches.size(), 2, "No branch was anchored at index 2")


## The built-in gizmo DELETE path removes via direct remove_point -> watcher reconcile.
func test_watcher_path_builtin_delete() -> void:
	var branch := _add_branch(4, 1)
	var spline: Spline = _track.get_spline()
	# Simulate the built-in Path3D gizmo: it calls remove_point directly, which fires
	# Curve3D.changed; our watcher reconciles branches with no explicit index.
	spline.remove_point(3)
	assert_true(_track.branches.has(branch), "Branch should survive a watcher-driven removal")
	assert_eq(branch.from_point_index, 3, "endpoint 4 -> 3 via watcher reconcile")


## Bulk shrink (clear_points, multi-remove) prunes out-of-range endpoints instead of
## guessing an index.
func test_bulk_shrink_prunes_out_of_range_endpoints() -> void:
	var branch := _add_branch(5, 1)
	var spline: Spline = _track.get_spline()
	spline.clear_points()
	assert_false(_track.branches.has(branch), "Out-of-range endpoint should be pruned on bulk shrink")
	assert_eq(_track.branches.size(), 0, "All branches to the cleared path are pruned")


## Undo of remove_point_with_branches restores both the point AND the branch state.
func test_undo_restores_point_and_branches() -> void:
	_add_branch(4, 1)
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	_track.remove_point_with_branches(0, 2)
	assert_eq(_track.branches[0].from_point_index, 3, "endpoint shifted after removal")
	# Undo the "Remove Track Point" action.
	var undone := editor_undo(ur)
	assert_true(undone, "undo should land")
	assert_eq(_track.get_spline().point_count, 6, "Point restored on undo")
	assert_eq(_track.branches.size(), 1, "Branch restored on undo")
	assert_eq(_track.branches[0].from_point_index, 4, "Branch endpoint restored on undo")
	assert_eq(_track.branches[0].to_point_index, 1, "Branch to endpoint restored on undo")
