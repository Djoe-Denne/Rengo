## StageView - Pure view component for rendering backgrounds
## Observes Scene model and updates display when plan changes
class_name StageView
extends RefCounted

## The actual background sprite in the scene
var background_sprite: Sprite2D = null

## Reference to the Scene model (for observing)
var scene_model: Scene = null

## Reference to the parent VNScene node
var vn_scene: Node = null


func _init() -> void:
	pass


## Sets the scene model and subscribes to changes
func set_scene_model(p_scene_model: Scene, p_vn_scene: Node) -> void:
	scene_model = p_scene_model
	vn_scene = p_vn_scene
	
	# Subscribe to scene changes
	if scene_model:
		scene_model.add_observer(_on_scene_changed)


## Creates the initial background sprite
func create_background_node(parent: Node) -> Sprite2D:
	if not scene_model:
		push_error("StageView: Scene model not set")
		return null
	
	var plan = scene_model.get_current_plan()
	if not plan:
		push_warning("StageView: No current plan available")
		return null
	
	# Get default background from plan
	var bg_config = plan.get_default_background()
	if bg_config.is_empty():
		push_warning("StageView: No backgrounds in plan '%s'" % scene_model.current_plan_id)
		return null
	
	# Create sprite
	background_sprite = Sprite2D.new()
	background_sprite.name = "Background"
	background_sprite.centered = false
	background_sprite.z_index = -100  # Backgrounds are behind everything
	
	parent.add_child(background_sprite)
	
	# Set initial background
	update_background(bg_config)
	
	# Scale to viewport
	if vn_scene and vn_scene.is_inside_tree():
		scale_to_viewport()
	
	return background_sprite


## Updates the background texture based on configuration
func update_background(bg_config: Dictionary) -> void:
	if not background_sprite:
		return
	
	# Set texture based on config
	if "image" in bg_config:
		var image_path = bg_config.image
		if ResourceLoader.exists(image_path):
			background_sprite.texture = load(image_path)
		else:
			push_warning("StageView: Background image not found: %s" % image_path)
	elif "color" in bg_config:
		# Create colored background
		var color_data = bg_config.color
		var color = Color(color_data[0], color_data[1], color_data[2])
		background_sprite.texture = _create_color_texture(color)
	
	# Re-scale after texture change
	if vn_scene and vn_scene.is_inside_tree():
		scale_to_viewport()


## Scales the background to fill the viewport based on camera ratio and scaling mode
func scale_to_viewport() -> void:
	if not background_sprite or not background_sprite.texture:
		return
	
	if not vn_scene or not vn_scene.is_inside_tree():
		return
	
	if not scene_model:
		return
	
	var viewport_size = vn_scene.get_viewport().get_visible_rect().size
	var texture_size = background_sprite.texture.get_size()
	
	# Get camera and scaling mode from scene model
	var camera = scene_model.get_current_camera()
	var scaling_mode = scene_model.stage.scaling_mode
	
	var target_ratio = camera.ratio if camera else (viewport_size.x / viewport_size.y)
	
	# Calculate scale based on scaling mode
	var scale_x: float
	var scale_y: float
	
	match scaling_mode:
		"letterbox":
			# Maintain aspect ratio, add letterboxing if needed
			var viewport_ratio = viewport_size.x / viewport_size.y
			if viewport_ratio > target_ratio:
				# Viewport is wider, fit to height
				scale_y = viewport_size.y / texture_size.y
				scale_x = scale_y
			else:
				# Viewport is taller, fit to width
				scale_x = viewport_size.x / texture_size.x
				scale_y = scale_x
		
		"fit":
			# Stretch to fill viewport while maintaining plan ratio
			var target_height = viewport_size.x / target_ratio
			scale_x = viewport_size.x / texture_size.x
			scale_y = target_height / texture_size.y
		
		"stretch":
			# Stretch to fill entire viewport (ignore ratio)
			scale_x = viewport_size.x / texture_size.x
			scale_y = viewport_size.y / texture_size.y
		
		_:
			# Default to letterbox
			scale_x = viewport_size.x / texture_size.x
			scale_y = viewport_size.y / texture_size.y
	
	background_sprite.scale = Vector2(scale_x, scale_y)


## Observer callback - called when Scene model changes
func _on_scene_changed(scene_state: Dictionary) -> void:
	if not scene_model:
		return
	
	# Plan changed - update background
	var plan = scene_model.get_current_plan()
	if plan:
		var bg_config = plan.get_default_background()
		if not bg_config.is_empty():
			update_background(bg_config)


## Creates a simple colored texture
func _create_color_texture(color: Color, size: Vector2 = Vector2(800, 600)) -> Texture2D:
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

