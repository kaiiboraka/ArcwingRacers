class_name ManaCrystalResource
extends Resource;

enum CrystalSize { SMALL, LARGE, SUPER }

@export var crystal_size : CrystalSize = CrystalSize.SMALL;
@export var display_name : String = "Small Crystal";
@export var mana_value_percent : float = 0.05;
@export var respawn_time : float = 8.0;
@export var sprite : Texture2D;
