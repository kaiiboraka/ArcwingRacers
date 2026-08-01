class_name SplinePointData
extends Resource

## Track half-width at this point in meters (left + right from the center line).[br]
## Intended purpose: interpolated between points so tracks narrow (tunnel entrances) and widen
## (straights, pit areas).[br]
## Higher = wider road; lower = narrower ribbon.
@export var width: float = 5.0

## Recipe for the span AFTER this point (Spline.SegmentRecipe). Decides what the generator
## builds: ROAD/TUNNEL generate geometry, NONE leaves space for modeled terrain.[br]
## Intended purpose: hybrid authoring — the designer chooses per-point whether to generate.[br]
## NONE = modeled terrain; ROAD = ribbon + walls; TUNNEL = tube.
@export var recipe: Spline.SegmentRecipe = Spline.SegmentRecipe.NONE

## Recipe scalar, currently the tunnel height in meters for TUNNEL spans.[br]
## Intended purpose: carries the extra dimension a recipe needs (tunnel height) without a
## separate data structure.[br]
## Higher = taller tunnel; ignored for ROAD/NONE.
@export var recipe_param: float = 6.0

## Flags bitfield (Spline.SplinePointFlags).[br]
## Intended purpose: mark lap line, waypoints, respawns, and branch hints on this point.[br]
## One checkbox per flag (0 = none).
@export_flags(
	"Start Finish",
	"Waypoint",
	"Respawn",
	"Branch Split",
	"Branch Join",
	"Pit Entry",
	"Pit Exit",
)
var flags: int = Spline.SplinePointFlags.NONE

## Point tilt in radians (roll about the tangent).[br]
## Intended purpose: bank the track at this point; written back to Curve3D via set_point_tilt.[br]
## Higher = more roll; 0 = level.
@export var tilt: float = 0.0
