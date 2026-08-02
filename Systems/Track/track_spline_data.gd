@tool
class_name TrackSplineData
extends Resource

## Single serialized container for a track's full spline authoring state. TrackSpline
## keeps its live curves in memory and persists them HERE (a .tres) so alternate-path
## Splines and BranchConnections stop polluting the level scene file. Path indices in
## branches follow the same convention as TrackSpline.get_spline_at(): 0 = main_curve,
## 1..N = alternate_paths[i-1].

## The main path's curve. TrackSpline.Load Track from Data copies this onto Path3D.curve.
@export var main_curve: Spline

## Alternate routes (shortcuts/chicanes). Path index 1..N maps to alternate_paths[i-1].
@export var alternate_paths: Array[Spline] = []

## Branch topology between paths. Each entry links a point on one path to a point on
## another (split or join).
@export var branches: Array[BranchConnection] = []

## Meters between baked samples; drives sampling fidelity for banking and tunnels.
## Stored here (not on the node) so the whole track definition travels as one asset.
@export_range(0.05, 5.0, 0.05) var bake_interval: float = 0.25
