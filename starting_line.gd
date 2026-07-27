# I need a grid of Marker3D's called "Position_01" through "Position_16" that moves in position based on the exported width and spacing values. Then I need these positions available in a public-facing array for the Race to populate positions with (i.e. for each position, place one of the racers on that position). Maybe that's just a method on the starting line, not sure, maybe take in the array of racers. 
# racer_count indicates how many racers are in THIS race. Put res://Content/Textures/starting_position.png texture3d on each of those. 
# Find and reuse or delete all existing Marker3D children in this process, ensuring no orphans are left around. there should basically always be 16 marker3d's with the right names. rename wrong ones and add new ones if need be and align them to this grid. Don't do it in process, only on update of the values of spacing or count.
@tool
class_name StartingLine extends Node3D

const MAX_RACER_SLOTS : int = 16;

## to be made const once determined. until then, export
#const RACER_POSITION_WIDTH : float = 15;
@export_range(0,100) var RACER_POSITION_WIDTH : float = 15;
@export_range(0,100) var RACER_ROWS_SPACING : float = 25;

@export_range(0,16) var racer_count : int = 8
