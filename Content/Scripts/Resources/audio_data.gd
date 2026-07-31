class_name AudioData
extends Resource;

@export var sounds: Dictionary = {}

func get_sound(key: String) -> AudioStream:
	return sounds.get(key) as AudioStream;
