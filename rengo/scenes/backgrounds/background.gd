## Background scene script
## Represents a background in the visual novel
extends Sprite2D

## Background ID
@export var background_id: String = ""

## Background configuration
var config: Dictionary = {}


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

