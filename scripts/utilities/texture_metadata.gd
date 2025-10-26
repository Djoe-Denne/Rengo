## Parses and stores texture metadata from configuration files
## Supports composition rules for layering textures (e.g., base + face overlay)
class_name TextureMetadata
extends RefCounted

## Base texture path
var base_texture: String = ""

## Face bounding box [x, y, width, height]
var face_bbox: Array = []

## Folder path for expression/face textures
var expression_folder: String = ""

## Default state
var default_state: String = ""

## Additional metadata
var metadata: Dictionary = {}


## Loads metadata from a JSON file
## (Using JSON instead of TOML since Godot doesn't have built-in TOML support)
func load_from_json(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_warning("Metadata file not found: %s" % file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open metadata file: %s" % file_path)
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("Failed to parse JSON metadata: %s" % json.get_error_message())
		return false
	
	metadata = json.data
	_parse_metadata()
	return true


## Parses the loaded metadata dictionary
func _parse_metadata() -> void:
	if "texture" in metadata:
		var texture_data = metadata["texture"]
		if "base" in texture_data:
			base_texture = texture_data["base"]
	
	if "face" in metadata:
		var face_data = metadata["face"]
		if "bbox" in face_data:
			face_bbox = face_data["bbox"]
		if "folder" in face_data:
			expression_folder = face_data["folder"]
	
	if "states" in metadata:
		var states_data = metadata["states"]
		if "default" in states_data:
			default_state = states_data["default"]


## Gets a value from metadata by path (e.g., "texture.base")
func get_value(path: String, default_value = null):
	var keys = path.split(".")
	var current = metadata
	
	for key in keys:
		if current is Dictionary and key in current:
			current = current[key]
		else:
			return default_value
	
	return current

