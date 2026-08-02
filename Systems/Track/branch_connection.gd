class_name BranchConnection
extends Resource

## Path index the connection originates on: 0 = main (Path3D.curve); 1..N = alternate_paths[i-1].[br]
## Intended purpose: identify which path carries this branch endpoint without holding node
## references (paths live on TrackSpline as Spline resources).[br]
## 0..N — index into TrackSpline.get_spline_at().
@export var from_path_index : int = 0

## Point index on from_path_index where the branch starts (split) or ends (join).[br]
## Intended purpose: pin the endpoint to an exact point on that path's Curve3D.[br]
## 0..point_count-1.
@export var from_point_index : int = 0

## Path index the connection targets: 0 = main; 1..N = alternate_paths[i-1].[br]
## Intended purpose: identify the other endpoint of the connection.[br]
## 0..N.
@export var to_path_index : int = 0

## Point index on to_path_index where the branch ends (split) or starts (join).[br]
## Intended purpose: pin the other endpoint to an exact point on that path's Curve3D.[br]
## 0..point_count-1.
@export var to_point_index : int = 0

## true = this connection diverges from from_path to to_path (a branch leaves the path);[br]
## false = it rejoins (the path merges back in).[br]
## Intended purpose: AI uses this to decide whether a downstream path is a shortcut (join) or a
## risk (split), per ADR 0005.
@export var is_split : bool = true
