extends Node
## Boot script for the ArcwingRacers master scene (Content/Scenes/ArcwingRacers.tscn).
## Runs once at startup: injects the three master containers into the GameManager
## autoload, then hands the flow off to the ProjectLoader autoload.
##
## The master scene is the one-and-only scene Godot ever loads; everything else lives
## inside its World3D / World2D / UI containers. See ADR 0011 and the GFT plan
## (docs/agent-context/plans/plan-game-flow-and-scene-management.md).

@onready var world_3d : Node3D = %World3D
@onready var world_2d : Node2D = %World2D
@onready var ui : CanvasLayer = %UI


func _ready() -> void:
	GameManager.configure(world_3d, world_2d, ui)
	ProjectLoader.bootstrap()
