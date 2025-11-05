## Movie-style actor director for single-sprite characters
## Creates and manages single Sprite2D nodes (simpler than theater mode)
class_name MovieActorDirector
extends ActorDirector


func _init() -> void:
	super()

## Instructs an actor to change states
## Creates or updates single sprite setup
func instruct(displayable_model: DisplayableModel) -> void:
	if not controller:
		return
	
	# Ensure character is loaded
	if not character_acts:
		if not load_character(displayable_model.name):
			push_error("Failed to load character: %s" % displayable_model.name)
			return
	
	# new_states contains the current states from Character model
	var current_states = displayable_model.get_states()
	
	# Get the current pose/act
	var pose = current_states.get("pose", "idle")
	var orientation = current_states.get("orientation", "front")
	
	var act = get_act(displayable_model.name, pose)
	if not act:
		push_warning("Act '%s' not found for character '%s'" % [pose, displayable_model.name])
		return
	
	# Movie mode is currently not supported with new multi-pass architecture
	# This needs to be updated to use DisplayableNode's system
	push_warning("MovieActorDirector is not yet updated for the new multi-pass architecture")
	# TODO: Refactor to use DisplayableNode with single layer or create separate system


## Loads a texture using ImageRepository with base directory resolution
func _load_texture(image_path: String) -> Texture2D:
	# Check if it's a color specification (starts with #)
	if image_path.begins_with("#"):
		return _create_color_texture(Color(image_path))
	
	# Replace {plan} placeholder with current plan from scene model
	if "{plan}" in image_path:
		var plan_id = scene_model.current_plan_id if scene_model else ""
		image_path = image_path.replace("{plan}", plan_id)
	
	# Get base directories for this character
	var base_dirs = get_character_base_dirs(controller.get_model().name)
	
	# Use ImageRepository to load with base directory resolution
	var texture = ImageRepository.get_or_load(base_dirs, image_path)
	
	if not texture:
		# Create colored placeholder if image not found
		var plan_id = scene_model.current_plan_id if scene_model else "unknown"
		push_warning("Texture not found: %s (character: %s, plan: %s)" % [image_path, controller.get_model().name, plan_id])
		return _create_color_texture(Color(1.0, 0.0, 1.0))  # Magenta placeholder
	
	return texture


## Creates a simple colored texture
func _create_color_texture(color: Color, size: Vector2 = Vector2(150, 200)) -> Texture2D:
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

