## Theater-style actor director for multi-layer character sprites
## Creates and manages Node2D with multiple Sprite2D children (layers)
class_name TheaterActorDirector
extends ActorDirector

const TheaterCostumier = preload("res://rengo/controllers/theater_costumier.gd")

func _init() -> void:
	super()

## Instructs an actor to change states (pose, expression, outfit, etc.)
## Creates or updates multi-layer sprite setup using unified template system
func handle_displayable(displayable: Displayable) -> void:
	if not controller:
		return

	var displayable_model = controller.get_model()
	if not displayable_model:
		return
	
	# Ensure wardrobe is loaded for clothing layers
	if not costumier:
		if not load_wardrobe(displayable_model.name):
			push_warning("Failed to load wardrobe for character: %s" % displayable_model.name)
	
	# new_states contains the current states from Character model
	var current_states = displayable_model.get_states().duplicate()

	if scene_model:
		current_states["plan"] = scene_model.current_plan_id

	# Update all layers based on current states (body + face + clothing)
	if displayable.get_parent() and displayable.get_parent() is DisplayableLayer:
		var layer = displayable.get_parent()
		_update_layers_unified(layer, current_states)
	else:
		_compose_displayable(displayable)

func _compose_displayable(displayable: Displayable) -> void:
	var actor = controller.get_view()
	if not actor:
		return
	
	var layers = actor.get_visible_layers()

	displayable.to_builder().clear_base_textures().clear_shaders()
	for layer in layers:
		var texture = layer.get_output_texture()
		displayable.to_builder().add_base_texture(texture)

## Updates all layers using unified template system (body + face + clothing)
func _update_layers_unified(layer: DisplayableLayer, current_states: Dictionary) -> void:
	var actor = controller.get_view()
	if not actor:
		return
	
	var layer_def = layer.layer_definition
	# Resolve template path
	var image_template = layer_def.get("image", "")
	var image_path = ResourceRepository.resolve_template_path(image_template, current_states)
	
	# Load and apply texture
	if image_path != "" and image_path != layer.texture_path:
		var texture = _load_texture(actor, image_path)
		if texture:
			# Apply texture to DisplayableLayer
			_apply_texture_to_displayable_layer(layer, texture)
			layer.texture_path = image_path
		else:
			# Hide layer if texture not found
			layer.set_layer_visible(false)


## Applies a texture to a DisplayableLayer and updates its size
func _apply_texture_to_displayable_layer(layer: DisplayableLayer, texture: Texture2D) -> void:
	if not layer or not texture:
		return
	
	var actor = controller.get_view()
	# Calculate character size in centimeters
	var char_size = _get_character_size(controller.get_model())
	
	# Calculate layer size based on texture and character dimensions
	var layer_size = _calculate_layer_size(texture, char_size, layer.layer_name, actor)
	layer.set_size(layer_size)
	
	# Use PostProcessorBuilder to set up the layer's Displayable
	# Clear shaders to ensure clean state, then set texture and size
	layer.displayable.to_builder() \
		.clear_base_textures() \
		.add_base_texture(TransformableTexture.new(texture, Vector2.ZERO))
	
	# Set character size on actor for output mesh
	actor.base_size = char_size
	
	# Make layer visible
	layer.set_layer_visible(true)


## Loads a texture using ImageRepository with base directory resolution
## Note: Template resolution should be done BEFORE calling this method
## Includes smart fallback for handling "default" state values
func _load_texture(actor, image_path: String) -> Texture2D:
	# Check if it's a color specification (starts with #)
	if image_path.begins_with("#"):
		return _create_color_texture(Color(image_path))
	
	# Get base directories for this character
	var base_dirs = get_character_base_dirs(controller.get_model().name)
	
	# Try to load the resolved path
	var texture = ImageRepository.get_or_load(base_dirs, image_path)
	
	# If not found and path contains "_default", try without it (smart fallback)
	# This handles cases like "idle_default.png" -> "idle.png"
	if not texture and "_default" in image_path:
		var fallback_path = image_path.replace("_default", "")
		texture = ImageRepository.get_or_load(base_dirs, fallback_path)
		if texture:
			return texture
	
	if not texture:
		# Create colored placeholder if image not found
		var plan_id = scene_model.current_plan_id if scene_model else "unknown"
		push_error("Texture not found: %s (character: %s, plan: %s)" % [image_path, actor.actor_name, plan_id])
		return _create_color_texture(Color(1.0, 0.0, 1.0))  # Magenta placeholder
	
	return texture


## Creates a simple colored texture
func _create_color_texture(color: Color, size: Vector2 = Vector2(150, 200)) -> Texture2D:
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Gets the character size in centimeters from metadata
func _get_character_size(model: Character) -> Vector2:
	if not model:
		return Vector2(80, 170)  # Default size
	
	# Try to get size from character metadata
	var metadata = model.metadata
	if metadata and "size_cm" in metadata:
		var size_cm = metadata.size_cm
		return Vector2(
			size_cm.get("width", 60),
			size_cm.get("height", 170)
		)
	
	push_error("No character size found for character: %s" % model.name)
	return Vector2(80, 170)


## Calculates the appropriate quad size for a layer based on its texture dimensions
## Uses the character size as reference for the body layer, and maintains pixel-to-cm ratio
func _calculate_layer_size(texture: Texture2D, char_size: Vector2, layer_name: String, actor) -> Vector2:
	if not texture:
		return char_size
	
	var texture_size = texture.get_size()
	
	# Establish pixel-to-cm ratio from body texture
	var pixels_per_cm: Vector2 = Vector2(1.0, 1.0)
	
	if layer_name == "body":
		# Store for use by other layers
		if actor:
			actor.pixels_per_cm = texture_size / char_size
		return char_size
	else:
		# Other layers use the stored ratio from body
		if actor and actor.pixels_per_cm:
			pixels_per_cm = actor.pixels_per_cm
		else:
			# Fallback: estimate from texture size / char size
			# This shouldn't normally happen if body is loaded first
			pixels_per_cm = texture_size / char_size
	
	# Calculate layer size maintaining texture aspect ratio
	return texture_size / pixels_per_cm


## Loads the wardrobe (panoplie.yaml) for a character
func load_wardrobe(name: String) -> bool:
	# Check if already loaded
	if costumier:
		return true
	
	# Get base directories for this character
	var base_dirs = get_character_base_dirs(name)
	
	if base_dirs.is_empty():
		push_warning("No base directories found for character: %s" % name)
		return false
	
	# Create TheaterCostumier and load wardrobe with merging support
	costumier = TheaterCostumier.new(controller)
	return costumier.load_wardrobe(base_dirs, true)
		
