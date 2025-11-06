## Theater-style actor director for multi-layer character sprites
## Creates and manages Node2D with multiple Sprite2D children (layers)
class_name TheaterActorDirector
extends ActorDirector

const TheaterCostumier = preload("res://rengo/controllers/theater_costumier.gd")

func _init() -> void:
	super()

## Instructs an actor to change states (pose, expression, outfit, etc.)
## Creates or updates multi-layer sprite setup using unified template system
func instruct(displayable_model: DisplayableModel) -> void:
	if not controller:
		return
	
	# Ensure wardrobe is loaded for clothing layers
	if not costumier:
		if not load_wardrobe(displayable_model.name):
			push_warning("Failed to load wardrobe for character: %s" % displayable_model.name)
	
	# new_states contains the current states from Character model
	var current_states = displayable_model.get_states()
	
	# Update all layers based on current states (body + face + clothing)
	_update_layers_unified(current_states)


## Updates all layers using unified template system (body + face + clothing)
func _update_layers_unified(current_states: Dictionary) -> void:
	var actor = controller.get_view()
	if not actor:
		return
	
	# Prepare state dictionary with plan for template resolution
	var state = current_states.duplicate()
	if scene_model:
		state["plan"] = scene_model.current_plan_id
	
	# Collect all layer definitions
	var all_layers = get_character_layers()
	
	# Ensure all layers exist as DisplayableLayer instances
	for layer_def in all_layers:
		var layer_name = layer_def.get("layer", layer_def.get("id", ""))
		if layer_name == "":
			continue
		
		# Create layer if it doesn't exist (using DisplayableNode's add_layer)
		if not layer_name in actor.layers:
			actor.add_layer(layer_name, layer_def)
	
	# Update all layers with resolved textures
	for layer_def in all_layers:
		var layer_name = layer_def.get("layer", layer_def.get("id", ""))
		if layer_name == "" or not layer_name in actor.layers:
			continue
		
		var layer = actor.get_layer(layer_name)
		if not layer:
			continue
		
		# Resolve template path
		var image_template = layer_def.get("image", "")
		var image_path = ResourceRepository.resolve_template_path(image_template, state)
		
		# Load and apply texture
		if image_path != "" and image_path != layer.texture_path:
			var texture = _load_texture(actor, image_path)
			if texture:
				# Apply texture to DisplayableLayer
				_apply_texture_to_displayable_layer(layer, texture, layer_def)
				layer.texture_path = image_path
			else:
				# Hide layer if texture not found
				layer.set_layer_visible(false)


## Applies a texture to a DisplayableLayer and updates its size
func _apply_texture_to_displayable_layer(layer: DisplayableLayer, texture: Texture2D, layer_def: Dictionary) -> void:
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
	PostProcessorBuilder.take(layer.displayable) \
		.set_base_texture(texture) \
		.set_size(texture.get_size()) \
		.build()
	
	# Set texture for collision detection
	layer.set_texture(texture)
	
	# Set character size on actor for output mesh
	actor.character_size = char_size
	
	# Make layer visible
	layer.set_layer_visible(true)


## Determines which state key to use for a given layer
func _get_state_key_for_layer(current_states: Dictionary, layer_name: String) -> String:
	# Map layer names to state keys
	var layer_to_state = {
		"body": "body",
		"face": "expression",
	}
	
	var state_name = layer_to_state.get(layer_name, layer_name)
	return current_states.get(state_name, "default")


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
		return Vector2(60, 170)  # Default size
	
	# Try to get size from character metadata
	var metadata = model.metadata
	if metadata and "size_cm" in metadata:
		var size_cm = metadata.size_cm
		return Vector2(
			size_cm.get("width", 60),
			size_cm.get("height", 170)
		)
	
	return Vector2(60, 170)  # Default size


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
		
