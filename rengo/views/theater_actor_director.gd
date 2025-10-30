## Theater-style actor director for multi-layer character sprites
## Creates and manages Node2D with multiple Sprite2D children (layers)
class_name TheaterActorDirector
extends ActorDirector

const TheaterCostumier = preload("res://rengo/domain/theater_costumier.gd")


## Instructs an actor to change states (pose, expression, outfit, etc.)
## Creates or updates multi-layer sprite setup using unified template system
func instruct(actor, new_states: Dictionary = {}) -> void:
	if not actor:
		return
	
	# Ensure wardrobe is loaded for clothing layers
	if not actor.actor_name in costumiers:
		if not load_wardrobe(actor.actor_name):
			push_warning("Failed to load wardrobe for character: %s" % actor.actor_name)
	
	# new_states contains the current states from Character model
	var current_states = new_states
	
	# If sprite_container doesn't exist, create it
	if not actor.sprite_container:
		_create_sprite_container(actor, current_states)
	
	# Update all layers based on current states (body + face + clothing)
	_update_layers_unified(actor, current_states)


## Creates the sprite container with initial layer setup
func _create_sprite_container(actor, current_states: Dictionary) -> void:
	var container = Node3D.new()
	container.name = "Actor_" + actor.actor_name
	actor.sprite_container = container
	
	# Initialize layers dictionary
	if not "layers" in actor:
		actor.layers = {}
	
	# Layers will be created dynamically in _update_layers_unified


## Updates all layers using unified template system (body + face + clothing)
func _update_layers_unified(actor, current_states: Dictionary) -> void:
	if not actor.sprite_container:
		return
	
	# Prepare state dictionary with plan for template resolution
	var state = current_states.duplicate()
	if scene_model:
		state["plan"] = scene_model.current_plan_id
	
	# Collect all layer definitions
	var all_layers = []
	
	# 1. Load body layers from character.yaml
	var body_layers = load_character_layers(actor.actor_name)
	all_layers.append_array(body_layers)
	
	# 2. Load face layers from faces.yaml
	var face_layers = load_face_layers(actor.actor_name)
	all_layers.append_array(face_layers)
	
	# 3. Get clothing layers from costumier
	var costumier = get_costumier(actor.actor_name)
	if costumier and actor.character:
		var clothing_layers_dict = costumier.get_layers(actor.character.panoplie, state)
		
		# Convert clothing dictionary to array format
		for clothing_id in clothing_layers_dict.keys():
			var clothing_layer = clothing_layers_dict[clothing_id]
			all_layers.append({
				"id": clothing_id,
				"layer": clothing_id,
				"image": clothing_layer.image,
				"z": clothing_layer.z,
				"anchor": clothing_layer.get("anchor", {"x": 0, "y": 0})
			})
	
	# Ensure all layers exist as mesh instances
	for layer_def in all_layers:
		var layer_name = layer_def.get("layer", layer_def.get("id", ""))
		if layer_name == "":
			continue
		
		# Create layer if it doesn't exist
		if not layer_name in actor.layers:
			_create_layer_mesh(actor, layer_name, layer_def)
	
	# Update all layers with resolved textures
	for layer_def in all_layers:
		var layer_name = layer_def.get("layer", layer_def.get("id", ""))
		if layer_name == "" or not layer_name in actor.layers:
			continue
		
		# Resolve template path
		var image_template = layer_def.get("image", "")
		var image_path = ResourceRepository.resolve_template_path(image_template, state)
		
		# Load and apply texture
		if image_path != "":
			var texture = _load_texture(actor, image_path)
			if texture:
				_apply_texture_to_layer(actor, layer_name, texture, layer_def)
			else:
				# Hide layer if texture not found
				_hide_layer(actor, layer_name)
		else:
			_hide_layer(actor, layer_name)


## Creates a mesh instance for a layer
func _create_layer_mesh(actor, layer_name: String, layer_def: Dictionary) -> void:
	if not actor.sprite_container:
		return
	
	var char_size = _get_character_size(actor)
	var mesh_instance = _create_quad_mesh(layer_name, char_size, layer_def)
	
	actor.sprite_container.add_child(mesh_instance)
	actor.layers[layer_name] = mesh_instance


## Applies a texture to a layer mesh and updates its size
func _apply_texture_to_layer(actor, layer_name: String, texture: Texture2D, layer_def: Dictionary) -> void:
	if not layer_name in actor.layers:
		return
	
	var mesh_instance = actor.layers[layer_name]
	if not mesh_instance is MeshInstance3D or not mesh_instance.material_override:
		return
	
	# Set texture
	mesh_instance.material_override.albedo_texture = texture
	mesh_instance.visible = true
	
	# Calculate and set quad size based on texture dimensions
	var char_size = _get_character_size(actor)
	var layer_size = _calculate_layer_size(texture, char_size, layer_name, actor)
	if mesh_instance.mesh is QuadMesh:
		mesh_instance.mesh.size = layer_size
	
	# Apply scaled anchor offset
	if mesh_instance.has_meta("anchor_offset"):
		var anchor = mesh_instance.get_meta("anchor_offset")
		var pixels_per_cm = texture.get_size().y / layer_size.y
		mesh_instance.position.x = anchor.get("x", 0.0) / pixels_per_cm
		mesh_instance.position.y = anchor.get("y", 0.0) / pixels_per_cm


## Hides a layer by clearing its texture
func _hide_layer(actor, layer_name: String) -> void:
	if not layer_name in actor.layers:
		return
	
	var mesh_instance = actor.layers[layer_name]
	if mesh_instance is MeshInstance3D and mesh_instance.material_override:
		mesh_instance.material_override.albedo_texture = null
		mesh_instance.visible = false


## Updates all layers based on current states (DEPRECATED - kept for compatibility)
func _update_layers(actor, act: Act, orientation: String, current_states: Dictionary) -> void:
	var variant = act.get_variant(orientation)
	if not "layers" in variant:
		return
	
	# Start with Act layers (body, face, etc.)
	var layers_data = variant.layers.duplicate(true)
	
	# Get clothing layers from Costumier and merge them
	var costumier = get_costumier(actor.actor_name)
	if costumier and actor.character:
		# Add plan to states for template substitution
		var states_with_plan = current_states.duplicate()
		if scene_model:
			states_with_plan["plan"] = scene_model.current_plan_id
		
		# Pass character's panoplie (current outfit items) and states
		var clothing_layers = costumier.get_layers(actor.character.panoplie, states_with_plan)
		# Merge clothing layers into layers_data
		for layer_name in clothing_layers.keys():
			layers_data[layer_name] = clothing_layers[layer_name]
	
	# Ensure all layer sprites exist
	for layer_name in layers_data.keys():
		if not layer_name in actor.layers:
			_create_layer_sprite(actor, layer_name, layers_data[layer_name])
	
	# Update all layers
	for layer_name in layers_data.keys():
		var layer_data = layers_data[layer_name]
		var images = layer_data.get("images", {})
		
		# Determine which state key to use for this layer
		var state_key = _get_state_key_for_layer(current_states, layer_name)
		
		# Get the image path for this state
		var image_path = ""
		
		# For clothing layers, use the direct image path
		if "image" in layer_data:
			image_path = layer_data.image
		else:
			# For Act layers, resolve from images dict
			image_path = images.get(state_key, "")
			if image_path == "":
				# Try "default" as fallback
				image_path = images.get("default", "")
			
			# If we still don't have an image, try the first available
			if image_path == "" and images.size() > 0:
				image_path = images.values()[0]
		
		# Load and set texture
		if image_path != "":
			var texture = _load_texture(actor, image_path)
			if texture and layer_name in actor.layers:
				var mesh_instance = actor.layers[layer_name]
				if mesh_instance is MeshInstance3D and mesh_instance.material_override:
					mesh_instance.material_override.albedo_texture = texture
					
					# Calculate quad size based on texture dimensions
					var char_size = _get_character_size(actor)
					var layer_size = _calculate_layer_size(texture, char_size, layer_name, actor)
					if mesh_instance.mesh is QuadMesh:
						mesh_instance.mesh.size = layer_size
					
					# Apply scaled anchor offset
					if mesh_instance.has_meta("anchor_offset"):
						var anchor = mesh_instance.get_meta("anchor_offset")
						var pixels_per_cm = texture.get_size().y / layer_size.y
						mesh_instance.position.x = anchor.get("x", 0.0) / pixels_per_cm
						mesh_instance.position.y = anchor.get("y", 0.0) / pixels_per_cm
		else:
			# No texture found, hide this layer
			if layer_name in actor.layers:
				var mesh_instance = actor.layers[layer_name]
				if mesh_instance is MeshInstance3D and mesh_instance.material_override:
					mesh_instance.material_override.albedo_texture = null


## Creates a new sprite layer dynamically (for clothing items)
func _create_layer_sprite(actor, layer_name: String, layer_data: Dictionary) -> void:
	if not actor.sprite_container:
		return
	
	# Get character size
	var char_size = _get_character_size(actor)
	
	# Create 3D quad mesh
	var mesh_instance = _create_quad_mesh(layer_name, char_size, layer_data)
	
	actor.sprite_container.add_child(mesh_instance)
	
	# Store layer reference in actor
	if not "layers" in actor:
		actor.layers = {}
	actor.layers[layer_name] = mesh_instance


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
	var base_dirs = get_character_base_dirs(actor.actor_name)
	
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
		push_warning("Texture not found: %s (character: %s, plan: %s)" % [image_path, actor.actor_name, plan_id])
		return _create_color_texture(Color(1.0, 0.0, 1.0))  # Magenta placeholder
	
	return texture


## Creates a simple colored texture
func _create_color_texture(color: Color, size: Vector2 = Vector2(150, 200)) -> Texture2D:
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Gets the character size in centimeters from metadata
func _get_character_size(actor) -> Vector2:
	if not actor.character:
		return Vector2(60, 170)  # Default size
	
	# Try to get size from character metadata
	var metadata = actor.character.metadata
	if metadata and "size_cm" in metadata:
		var size_cm = metadata.size_cm
		return Vector2(
			size_cm.get("width", 60),
			size_cm.get("height", 170)
		)
	
	return Vector2(60, 170)  # Default size


## Creates a 3D quad mesh for a character layer
func _create_quad_mesh(layer_name: String, char_size: Vector2, layer_data: Dictionary) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = layer_name
	
	# Create a quad mesh with default size (will be updated when texture loads)
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = char_size  # Initial size, will be recalculated based on texture
	mesh_instance.mesh = quad_mesh
	
	# Create material for the texture
	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y  # Always face camera
	mesh_instance.material_override = material
	
	# Set z-offset for layering (convert z-index to position offset)
	var z_index = layer_data.get("z", 0)
	mesh_instance.position.z = z_index * 0.1  # Small offset to prevent z-fighting
	
	# Store anchor data for later scaling (will be applied after texture loads)
	if "anchor" in layer_data:
		mesh_instance.set_meta("anchor_offset", layer_data.anchor)
	
	return mesh_instance


## Calculates the appropriate quad size for a layer based on its texture dimensions
## Uses the character size as reference for the body layer, and maintains pixel-to-cm ratio
func _calculate_layer_size(texture: Texture2D, char_size: Vector2, layer_name: String, actor) -> Vector2:
	if not texture:
		return char_size
	
	var texture_size = texture.get_size()
	
	# Establish pixel-to-cm ratio from body texture
	var pixels_per_cm: float
	
	if layer_name == "body":
		# Body layer defines the reference ratio
		# Assume body texture height matches character height
		pixels_per_cm = texture_size.y / char_size.y
		# Store for use by other layers
		if actor and actor.sprite_container:
			actor.sprite_container.set_meta("pixels_per_cm", pixels_per_cm)
		return char_size
	else:
		# Other layers use the stored ratio from body
		if actor and actor.sprite_container and actor.sprite_container.has_meta("pixels_per_cm"):
			pixels_per_cm = actor.sprite_container.get_meta("pixels_per_cm")
		else:
			# Fallback: estimate from texture size / char size
			# This shouldn't normally happen if body is loaded first
			pixels_per_cm = texture_size.y / char_size.y
	
	# Calculate layer size maintaining texture aspect ratio
	var layer_width = texture_size.x / pixels_per_cm
	var layer_height = texture_size.y / pixels_per_cm
	
	return Vector2(layer_width, layer_height)


## Loads the wardrobe (panoplie.yaml) for a character
func load_wardrobe(character_name: String) -> bool:
	# Check if already loaded
	if character_name in costumiers:
		return true
	
	# Get base directories for this character
	var base_dirs = get_character_base_dirs(character_name)
	
	if base_dirs.is_empty():
		push_warning("No base directories found for character: %s" % character_name)
		return false
	
	# Create TheaterCostumier and load wardrobe with merging support
	var costumier = TheaterCostumier.new(character_name)
	if costumier.load_wardrobe(base_dirs, true):
		costumiers[character_name] = costumier
		return true
	
	return false
