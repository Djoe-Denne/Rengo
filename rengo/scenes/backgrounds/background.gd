## Background scene script
## Represents a background in the visual novel
extends Sprite2D

## Background ID
@export var background_id: String = ""

## Background configuration
var config: Dictionary = {}

## Current background states (for shader activation)
var current_states: Dictionary = {}


func _ready() -> void:
	# Configure background if config is set
	if config:
		_apply_config()
	

## Applies configuration to the background
func _apply_config() -> void:
	if "image" in config:
		var image_path = config.image
		if ResourceLoader.exists(image_path):
			texture = load(image_path)
	
	if "color" in config:
		var color_data = config.color
		if color_data is Array and color_data.size() >= 3:
			var color = Color(color_data[0], color_data[1], color_data[2])
			texture = _create_color_texture(color)


## Creates a colored texture
func _create_color_texture(color: Color, size: Vector2 = Vector2(800, 600)) -> Texture2D:
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Gets base directories for background resources
func _get_background_base_dirs() -> Array:
	var base_dirs = []
	
	# Try scene-specific backgrounds
	if "scene_path" in config and config.scene_path != "":
		var scene_bg_path = "res://assets/scenes/" + config.scene_path + "/backgrounds/" + background_id + "/"
		if DirAccess.dir_exists_absolute(scene_bg_path):
			base_dirs.append(scene_bg_path)
	
	# Try common backgrounds
	var common_bg_path = "res://assets/scenes/common/backgrounds/" + background_id + "/"
	if DirAccess.dir_exists_absolute(common_bg_path):
		base_dirs.append(common_bg_path)
	
	return base_dirs


## Sets a background state value
func set_state(key: String, value: Variant) -> void:
	if current_states.get(key) != value:
		current_states[key] = value
		

## Updates multiple states at once
func update_states(new_states: Dictionary) -> void:
	var changed = false
	for key in new_states:
		if current_states.get(key) != new_states[key]:
			current_states[key] = new_states[key]
			changed = true
	
