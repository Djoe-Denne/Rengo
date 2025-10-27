## Theater-style actor director for multi-layer character sprites
## Creates and manages Node2D with multiple Sprite2D children (layers)
class_name TheaterActorDirector
extends ActorDirector

const TheaterCostumier = preload("res://scripts/domain/theater_costumier.gd")


## Instructs an actor to change states (pose, expression, outfit, etc.)
## Creates or updates multi-layer sprite setup
func instruct(actor, new_states: Dictionary = {}) -> void:
	if not actor:
		return
	
	# Ensure character is loaded
	if not actor.actor_name in character_acts:
		if not load_character(actor.actor_name):
			push_error("Failed to load character: %s" % actor.actor_name)
			return
	
	# new_states contains the current states from Character model
	# We use them directly without storing in actor
	var current_states = new_states
	
	# Get the current pose/act
	var pose = current_states.get("pose", "idle")
	var orientation = current_states.get("orientation", "front")
	
	var act = get_act(actor.actor_name, pose)
	if not act:
		push_warning("Act '%s' not found for character '%s'" % [pose, actor.actor_name])
		return
	
	# If sprite_container doesn't exist, create it
	if not actor.sprite_container:
		_create_sprite_container(actor, current_states)
	
	# Update all layers based on current states
	_update_layers(actor, act, orientation, current_states)


## Creates the sprite container with initial layer setup
func _create_sprite_container(actor, current_states: Dictionary) -> void:
	var container = Node3D.new()
	container.name = "Actor_" + actor.actor_name
	actor.sprite_container = container
	
	# Get default pose and orientation
	var pose = current_states.get("pose", "idle")
	var orientation = current_states.get("orientation", "front")
	
	var act = get_act(actor.actor_name, pose)
	if not act:
		push_warning("Default act not found for character: %s" % actor.actor_name)
		return
	
	# Get character size from metadata
	var char_size = _get_character_size(actor)
	
	# Create mesh layers (3D quads)
	var layer_names = act.get_layer_names(orientation)
	for layer_name in layer_names:
		var layer_data = act.get_layer_data(orientation, layer_name)
		var mesh_instance = _create_quad_mesh(layer_name, char_size, layer_data)
		
		container.add_child(mesh_instance)
		
		# Store layer reference in actor
		if not "layers" in actor:
			actor.layers = {}
		actor.layers[layer_name] = mesh_instance


## Updates all layers based on current states
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
func _load_texture(actor, image_path: String) -> Texture2D:
	# Check if it's a color specification (starts with #)
	if image_path.begins_with("#"):
		return _create_color_texture(Color(image_path))
	
	# Replace {plan} placeholder with current plan from scene model
	if "{plan}" in image_path:
		var plan_id = scene_model.current_plan_id if scene_model else ""
		image_path = image_path.replace("{plan}", plan_id)
	
	# Get base directories for this character
	var base_dirs = get_character_base_dirs(actor.actor_name)
	
	# Use ImageRepository to load with base directory resolution
	var texture = ImageRepository.get_or_load(base_dirs, image_path)
	
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
	
	# Create a quad mesh
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = char_size  # Size in centimeters
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
	
	# Handle anchor offset
	if "anchor" in layer_data:
		var anchor = layer_data.anchor
		mesh_instance.position.x += anchor.get("x", 0.0)
		mesh_instance.position.y += anchor.get("y", 0.0)
	
	return mesh_instance


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
