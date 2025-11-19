## Theater-style actor director for multi-layer character sprites
## Creates and manages Node2D with multiple Sprite2D children (layers)
class_name TheaterActorDirector
extends ActorDirector

const TheaterCostumier = preload("res://rengo/controllers/theater_costumier.gd")

## Maps clothing_id to layer_id for finding the correct variant
var clothing_to_layer_map: Dictionary = {}

## Stores all composition layers grouped by layer_id for variant selection
var composition_layers_by_layer_id: Dictionary = {}

func _init() -> void:
	super(TheaterCostumier.new())

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

	current_states["plan"] = Scene.get_instance().current_plan_id

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
	
	# Get only root layers (layers without parent)
	var root_layers = actor.get_root_layers()
	
	displayable.to_builder().clear_base_textures().clear_shaders()
	
	# Build hierarchical texture structure for each root layer
	for layer in root_layers:
		if layer.is_layer_visible():
			var texture = _build_texture_hierarchy(layer)
			displayable.to_builder().add_base_texture(texture)

## Builds hierarchical texture structure recursively
## Returns a VNTexture with all child textures properly nested
func _build_texture_hierarchy(layer: DisplayableLayer) -> VNTexture:
	# Get the layer's output texture
	var texture = layer.displayable.get_output_pass().get_output_texture()
	texture.set_position(layer.position)
	texture.set_source(layer)
	texture.set_padding(layer.displayable.get_input_pass().get_padding())
	texture.set_layer_id(layer.layer_id)
	
	# Recursively add child textures
	for child_layer in layer.get_child_layers():
		if child_layer.is_layer_visible():
			var child_texture = _build_texture_hierarchy(child_layer)
			texture.add_child_texture(child_texture)
	
	return texture

## Updates all layers using unified template system (body + face + clothing)
## Now handles variant selection based on panoplie
func _update_layers_unified(layer: DisplayableLayer, current_states: Dictionary) -> void:
	var actor = controller.get_view()
	if not actor:
		return
	
	# Determine which variant to use based on layer_id and panoplie
	var active_variant = _get_active_variant_for_layer(layer.layer_id, current_states)
	
	if not active_variant:
		# No active variant for this layer - hide it
		layer.set_layer_visible(false)
		return
	
	# Use the active variant's definition
	var layer_def = active_variant.to_layer_definition()
	
	# Resolve template path
	var image_template = layer_def.get("image", "")
	var image_path = ResourceRepository.resolve_template_path(image_template, current_states)
	
	# Load and apply texture
	if image_path != "" and image_path != layer.texture_path:
		var texture = _load_texture(actor, image_path)
		var vn_texture = VNTexture.new(texture, Vector2.ZERO)
		vn_texture.set_layer_id(layer.layer_id)
		vn_texture.set_texture_id(active_variant.id)
		if vn_texture:
			# Apply texture to DisplayableLayer
			_apply_texture_to_displayable_layer(layer, vn_texture)
			layer.texture_path = image_path
		else:
			# Hide layer if texture not found
			layer.set_layer_visible(false)


## Determines which variant (CompositionLayer) should be active for a given layer_id
## Based on the current panoplie (worn clothing items)
func _get_active_variant_for_layer(layer_id: String, current_states: Dictionary) -> CompositionLayer:
	if not layer_id in composition_layers_by_layer_id:
		return null
	
	var variants = composition_layers_by_layer_id[layer_id]
	if variants.is_empty():
		return null
	
	# For non-clothing layers (body, face), return the first (and only) variant
	var first_variant = variants[0]
	if first_variant.layer_type != CompositionLayer.LayerType.CLOTHING:
		return first_variant
	
	# For clothing layers, check which item in panoplie matches this layer_id
	var model = controller.get_model()
	if not model:
		return null
	
	var panoplie = model.panoplie
	
	# Find which clothing item in panoplie has this layer_id
	for clothing_id in panoplie:
		if clothing_id in clothing_to_layer_map:
			var mapped_layer_id = clothing_to_layer_map[clothing_id]
			if mapped_layer_id == layer_id:
				# Found the active clothing item - find its CompositionLayer
				for variant in variants:
					if variant.id == clothing_id:
						return variant
	
	# No matching clothing in panoplie - layer should be hidden
	return null


## Applies a texture to a DisplayableLayer and updates its size
func _apply_texture_to_displayable_layer(layer: DisplayableLayer, vn_texture: VNTexture) -> void:
	if not layer or not vn_texture:
		return
	
	var actor = controller.get_view()
	# Calculate character size in centimeters
	var char_size = _get_character_size(controller.get_model())
	
	# Calculate layer size based on texture and character dimensions
	var layer_size = _calculate_layer_size(vn_texture.get_texture(), char_size, layer.layer_name, actor)
	layer.set_size(layer_size)
	
	# Use PostProcessorBuilder to set up the layer's Displayable
	# Clear shaders to ensure clean state, then set texture and size
	layer.displayable.to_builder() \
		.clear_base_textures() \
		.add_base_texture(vn_texture)
	
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
		var plan_id = Scene.get_instance().current_plan_id if Scene.get_instance() else "unknown"
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


## Loads wardrobe from a CharacterCompositionResource (overrides base method)
func _load_wardrobe_from_resource(composition_resource: CharacterCompositionResource) -> bool:
	if not composition_resource:
		return false
	
	# Load wardrobe array directly from resource
	var wardrobe_array = composition_resource.to_wardrobe_array()
	costumier.wardrobe = wardrobe_array
	
	# Build clothing_id to layer_id mapping
	clothing_to_layer_map.clear()
	composition_layers_by_layer_id.clear()
	
	for layer in composition_resource.layers:
		var lid = layer.layer_id if layer.layer_id != "" else layer.id
		var clothing_id = layer.id
		
		# Map clothing_id to layer_id
		clothing_to_layer_map[clothing_id] = lid
		
		# Group composition layers by layer_id
		if not lid in composition_layers_by_layer_id:
			composition_layers_by_layer_id[lid] = []
		composition_layers_by_layer_id[lid].append(layer)
	
	return true


## Override to create layers by unique layer_id instead of per-item
func _create_displayable_layers() -> void:
	var actor = controller.get_view()
	if not actor:
		return
	
	# Get the composition resource to access unique layer_ids
	var character_name = controller.get_model().name if controller.get_model() else ""
	var resource_path = _get_composition_resource_path(character_name)
	
	if not ResourceLoader.exists(resource_path):
		# Fallback to parent implementation for YAML-based characters
		super._create_displayable_layers()
		return
	
	var composition_resource = load(resource_path) as CharacterCompositionResource
	if not composition_resource:
		super._create_displayable_layers()
		return
	
	# Get unique layer_ids
	var unique_layer_ids = composition_resource.get_unique_layer_ids()
	
	# Create layers sorted by hierarchy
	var layer_creation_queue = []
	
	for layer_id in unique_layer_ids:
		# Get the first layer with this layer_id as a template
		var layers = composition_resource.get_layers_by_layer_id(layer_id)
		if layers.is_empty():
			continue
		
		var template_layer = layers[0]
		var layer_def = template_layer.to_layer_definition()
		
		layer_creation_queue.append(layer_def)
	
	# Sort by hierarchy
	layer_creation_queue = _sort_layers_by_hierarchy(layer_creation_queue)
	
	# Create DisplayableLayer for each unique layer_id
	for layer_def in layer_creation_queue:
		var layer_id = layer_def.get("layer_id", layer_def.get("id", ""))
		if layer_id == "":
			continue
		
		actor.add_layer(layer_id, layer_def)
		
