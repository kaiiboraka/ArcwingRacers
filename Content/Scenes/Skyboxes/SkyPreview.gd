@tool
class_name SkyPreviewer
extends WorldEnvironment

@export var panorama_textures: Array[Texture2D] = []

@export_range(0, 100, 1, "or_greater") var current_index: int = 0:
	set(value):
		if panorama_textures.is_empty():
			current_index = 0
			return
		current_index = posmod(value, panorama_textures.size())
		_update_sky_panorama()

@export_tool_button("Next Sky", "Forward")
var next_sky_button = _next_sky

@export_tool_button("Previous Sky", "Back")
var prev_sky_button = _prev_sky


func _next_sky() -> void:
	if not panorama_textures.is_empty():
		current_index += 1


func _prev_sky() -> void:
	if not panorama_textures.is_empty():
		current_index -= 1


func _ready() -> void:
	if Engine.is_editor_hint():
		_update_sky_panorama()


func _update_sky_panorama() -> void:
	if panorama_textures.is_empty():
		return
		
	var tex: Texture2D = panorama_textures[current_index]
	if not tex:
		return

	if not environment:
		environment = Environment.new()
	
	if environment.background_mode != Environment.BG_SKY:
		environment.background_mode = Environment.BG_SKY

	if not environment.sky:
		environment.sky = Sky.new()

	var sky_mat: PanoramaSkyMaterial = environment.sky.sky_material as PanoramaSkyMaterial
	if not sky_mat:
		sky_mat = PanoramaSkyMaterial.new()
		environment.sky.sky_material = sky_mat

	sky_mat.panorama = tex
