class_name AudioBucket
extends AudioStream

@export var bucket: Array[AudioStream]
@export var pitch_scale: float = 1.0
@export var volume_db: float = 0.0

var _count: int = 0

func _init():
	_count = bucket.size()

func _instantiate_playback() -> AudioStreamPlayback:
	if bucket.is_empty():
		return null
	var stream = bucket[randi() % bucket.size()]
	return stream.instantiate_playback()

func _get_length() -> float:
	if bucket.is_empty():
		return 0.0
	return bucket[0].get_length()

func _get_stream_name() -> String:
	if bucket.is_empty():
		return ""
	return bucket[0]._get_stream_name()

func _is_monophonic() -> bool:
	if bucket.is_empty():
		return false
	return bucket[0].is_monophonic()
