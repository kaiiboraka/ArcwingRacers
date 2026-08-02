@tool
class_name SkyPreviewer
extends WorldEnvironment;

const HDRI_DIR := "res://Content/Textures/HDRI/";
const HDRI_STYLIZED_DIR := HDRI_DIR + "stylized/";
const TEXTURE_EXTS := ["png", "jpg", "jpeg", "webp", "bmp", "tga", "exr"];

@export var panorama_textures : Array[Texture2D] = [];

@export_range(0, 100, 1, "or_greater") var current_index : int = 0:
	set(value):
		if panorama_textures.is_empty():
			current_index = 0;
			return;
		current_index = posmod(value, panorama_textures.size());
		_update_sky_panorama();
		if Engine.is_editor_hint():
			notify_property_list_changed();

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY);
var current_sky_name : String:
	get:
		return _clean_texture_name();

@export_tool_button("Next Sky", "Forward")
var next_sky_button = _next_sky;

@export_tool_button("Previous Sky", "Back")
var prev_sky_button = _prev_sky;

@export_tool_button("Find HDRI Textures", "Image")
var find_hdri_button = _find_hdri_textures;


func _next_sky() -> void:
	if not panorama_textures.is_empty():
		current_index += 1;


func _prev_sky() -> void:
	if not panorama_textures.is_empty():
		current_index -= 1;


func _find_hdri_textures() -> void:
	var found : Array[Texture2D] = [];
	_collect_textures(HDRI_DIR, found);
	_collect_textures(HDRI_STYLIZED_DIR, found);
	found.sort_custom(func(a : Texture2D, b : Texture2D) -> bool:
		return a.resource_path < b.resource_path)
	panorama_textures = found;
	if found.is_empty():
		if Engine.is_editor_hint():
			notify_property_list_changed();
		return;
	current_index = 0;
	_update_sky_panorama();
	if Engine.is_editor_hint():
		notify_property_list_changed();


func _collect_textures(dir_path : String, found : Array[Texture2D]) -> void:
	var dir := DirAccess.open(dir_path);
	if not dir:
		return;
	dir.list_dir_begin();
	var file_name := dir.get_next();
	while file_name != "":
		if not dir.current_is_dir():
			var ext : String = file_name.get_extension().to_lower();
			if ext in TEXTURE_EXTS:
				var tex := load(dir_path + file_name) as Texture2D;
				if tex:
					found.append(tex);
		file_name = dir.get_next();
	dir.list_dir_end();


func _clean_texture_name() -> String:
	if panorama_textures.is_empty():
		return "No textures loaded";
	var tex : Texture2D = panorama_textures[current_index];
	if not tex:
		return "";
	return tex.resource_path.get_file().get_basename().replace("-", " ").capitalize();


func _ready() -> void:
	if Engine.is_editor_hint():
		_update_sky_panorama();


func _update_sky_panorama() -> void:
	if panorama_textures.is_empty():
		return;

	var tex : Texture2D = panorama_textures[current_index];
	if not tex:
		return;

	if not environment:
		environment = Environment.new();

	if environment.background_mode != Environment.BG_SKY:
		environment.background_mode = Environment.BG_SKY;

	if not environment.sky:
		environment.sky = Sky.new();

	var sky_mat : PanoramaSkyMaterial = environment.sky.sky_material as PanoramaSkyMaterial;
	if not sky_mat:
		sky_mat = PanoramaSkyMaterial.new();
		environment.sky.sky_material = sky_mat;

	sky_mat.panorama = tex;
