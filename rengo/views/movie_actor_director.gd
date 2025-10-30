## Movie-style actor director for single-sprite characters
## Creates and manages single Sprite2D nodes (simpler than theater mode)
class_name MovieActorDirector
extends ActorDirector


## Instructs an actor to change states
## Creates or updates single sprite setup
func instruct(actor, new_states: Dictionary = {}) -> void:
	if not actor:
		return
	
	# Ensure character is loaded
	if not actor.actor_name in character_acts:
		if not load_character(actor.actor_name):
			push_error("Failed to load character: %s" % actor.actor_name)
			return
	
	# new_states contains the current states from Character model
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
		_create_sprite(actor)
	
	# Update the sprite texture
	_update_sprite(actor, act, orientation)


## Creates the sprite for the actor
func _create_sprite(actor) -> void:
	var sprite = Sprite2D.new()
	sprite.name = "Actor_" + actor.actor_name
	sprite.centered = true
	
	actor.sprite_container = sprite
	actor.scene_node = sprite
	
	# Initialize shader manager for this actor
	if not actor.shader_manager:
		actor.shader_manager = ShaderManager.new()
		var base_dirs = get_character_base_dirs(actor.actor_name)
		actor.shader_manager.load_config(base_dirs)


## Updates the sprite texture based on current state
func _update_sprite(actor, act: Act, orientation: String) -> void:
	var variant = act.get_variant(orientation)
	
	# Try to get image path from variant
	var image_path = ""
	
	# Try "image" key first
	if "image" in variant:
		image_path = variant.image
	# Try "images" key with default
	elif "images" in variant:
		var images = variant.images
		if "default" in images:
			image_path = images.default
		elif images.size() > 0:
			image_path = images.values()[0]
	
	# Load and set texture
	if image_path != "":
		var texture = _load_texture(actor, image_path)
		if texture and actor.sprite_container:
			actor.sprite_container.texture = texture
	else:
		push_warning("No image found for act %s orientation %s" % [act.act_name, orientation])


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

