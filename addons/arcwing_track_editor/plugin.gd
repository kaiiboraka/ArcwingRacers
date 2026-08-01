@tool
extends EditorPlugin

## Registers the TrackSpline gizmo plugin so every path (main + alternates) can be
## authored in the 3D viewport. Phase 1: color-coded point/control-handle editing with
## undo. Phase 2/3 add branch wiring and hover flyouts.

const TrackSplineGizmoPluginScript = preload("res://addons/arcwing_track_editor/track_spline_gizmo_plugin.gd")

var _gizmo_plugin: EditorNode3DGizmoPlugin


func _enter_tree() -> void:
	_gizmo_plugin = TrackSplineGizmoPluginScript.new()
	add_node_3d_gizmo_plugin(_gizmo_plugin)


func _exit_tree() -> void:
	if _gizmo_plugin:
		remove_node_3d_gizmo_plugin(_gizmo_plugin)
		_gizmo_plugin = null
