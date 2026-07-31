class_name AudioFile
extends AudioStream;

@export var stream: AudioStream;
@export var pitch_scale: float = 1.0;
@export var volume_db: float = 0.0;

func _instantiate_playback() -> AudioStreamPlayback:
	if not stream:
		return null;
	return stream.instantiate_playback();

func _get_length() -> float:
	if not stream:
		return 0.0;
	return stream.get_length();

func _get_stream_name() -> String:
	if not stream:
		return "";
	return stream._get_stream_name();

func _is_monophonic() -> bool:
	if not stream:
		return false;
	return stream.is_monophonic();
