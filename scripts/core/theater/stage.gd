## Stage class for managing backgrounds and stage elements
class_name Stage
extends RefCounted

## Dictionary of background configurations { bg_id: { config } }
var backgrounds: Dictionary = {}

## Current background ID
var current_background_id: String = ""

## The actual background sprite in the scene
var background_sprite: Sprite2D = null

## Reference to the parent VNScene
var vn_scene: Node = null


func _init() -> void:
	pass


## Adds a background configuration
func add_background(bg_id: String, config: Dictionary) -> void:
	backgrounds[bg_id] = config


## Creates the initial background sprite
func create_background_node(parent: Node, bg_id: String = "") -> Node:
	if bg_id == "":
		bg_id = current_background_id
	
	if bg_id == "" or not bg_id in backgrounds:
		push_warning("Background '%s' not found" % bg_id)
		return null
	
	var bg_config = backgrounds[bg_id]
	
	background_sprite = Sprite2D.new()
	background_sprite.name = "Background_" + bg_id
	background_sprite.centered = false
	background_sprite.z_index = -100  # Backgrounds are behind everything
	
	parent.add_child(background_sprite)
	
	# Set texture based on config
	if "image" in bg_config:
		var image_path = bg_config.image
		if ResourceLoader.exists(image_path):
			background_sprite.texture = load(image_path)
		else:
			push_warning("Background image not found: %s" % image_path)
	elif "color" in bg_config:
		# Create colored background
		var color_data = bg_config.color
		var color = Color(color_data[0], color_data[1], color_data[2])
		background_sprite.texture = _create_color_texture(color)
	
	# Scale to fill viewport
	if background_sprite.texture and vn_scene:
		scale_background_to_viewport()
	
	current_background_id = bg_id
	return background_sprite


## Changes the background to a different one
func set_background(bg_id: String) -> void:
	if not bg_id in backgrounds:
		push_warning("Background '%s' not found" % bg_id)
		return
	
	if not background_sprite:
		push_warning("Background sprite not created yet")
		return
	
	var bg_config = backgrounds[bg_id]
	
	# Update texture
	if "image" in bg_config:
		var image_path = bg_config.image
		if ResourceLoader.exists(image_path):
			background_sprite.texture = load(image_path)
	elif "color" in bg_config:
		var color_data = bg_config.color
		var color = Color(color_data[0], color_data[1], color_data[2])
		background_sprite.texture = _create_color_texture(color)
	
	# Re-scale
	if background_sprite.texture and vn_scene:
		scale_background_to_viewport()
	
	current_background_id = bg_id


## Scales the background to fill the viewport
func scale_background_to_viewport() -> void:
	if not background_sprite or not background_sprite.texture:
		return
	
	# Check if vn_scene is in the tree before accessing viewport
	if not vn_scene or not vn_scene.is_inside_tree():
		return
	
	var viewport_size = vn_scene.get_viewport().get_visible_rect().size
	var texture_size = background_sprite.texture.get_size()
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	background_sprite.scale = Vector2(scale_x, scale_y)


## Creates a simple colored texture
func _create_color_texture(color: Color, size: Vector2 = Vector2(800, 600)) -> Texture2D:
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
