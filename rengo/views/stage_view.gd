## StageView - Pure view component for rendering backgrounds
## Observes Scene model and updates display when plan changes
class_name StageView
extends RefCounted

## The actual background mesh in the scene (3D)
var background_sprite: MeshInstance3D = null

## Reference to the Scene model (for observing)
var scene_model: Scene = null

## Reference to the parent VNScene node
var vn_scene: Node = null

## Reference to a controller (MVC: view knows its controller)
## Currently StageView doesn't have a dedicated controller, but this is here
## for future extensibility if background interactions are needed
var controller = null

## Distance of background from camera (in centimeters)
const BACKGROUND_DISTANCE = 1000.0


func _init() -> void:
	pass


## Sets the scene model and subscribes to changes
func set_scene_model(p_scene_model: Scene, p_vn_scene: Node) -> void:
	scene_model = p_scene_model
	vn_scene = p_vn_scene
	
	# Subscribe to scene changes
	if scene_model:
		scene_model.add_observer(_on_scene_changed)


## Creates the initial background mesh (3D quad)
func create_background_node(parent: Node) -> MeshInstance3D:
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
	
	# Get camera for calculating background size
	var camera = scene_model.get_current_camera()
	if not camera:
		push_error("StageView: No camera in scene model")
		return null
	
	# Calculate the size needed to fill the frame at the background distance
	var fov = camera.get_fov()
	var quad_size = Camera3DHelper.calculate_quad_size_at_distance(BACKGROUND_DISTANCE, fov, camera.ratio)
	
	# Apply overscan to account for camera movement (mouse control)
	# Calculate separate overscan for width and height based on FOV coverage
	var overscan_factors = _calculate_overscan_factors(quad_size, camera)
	quad_size.x *= overscan_factors.x
	quad_size.y *= overscan_factors.y
	
	# Create 3D quad mesh for background
	background_sprite = MeshInstance3D.new()
	background_sprite.name = "Background"
	
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = quad_size
	background_sprite.mesh = quad_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_BACK
	background_sprite.material_override = material
	
	# Position background behind the action (relative to camera position)
	var camera_pos = camera.position
	background_sprite.position = Vector3(camera_pos.x, camera_pos.y, camera_pos.z - BACKGROUND_DISTANCE)
	
	parent.add_child(background_sprite)
	
	# Set initial background texture
	update_background(bg_config)
	
	return background_sprite


## Updates the background texture based on configuration
func update_background(bg_config: Dictionary) -> void:
	if not background_sprite or not background_sprite.material_override:
		return
	
	# Set texture based on config
	if "image" in bg_config:
		var image_path = bg_config.image
		if ResourceLoader.exists(image_path):
			var texture = load(image_path)
			background_sprite.material_override.albedo_texture = texture
		else:
			push_warning("StageView: Background image not found: %s" % image_path)
	elif "color" in bg_config:
		# Create colored background
		var color_data = bg_config.color
		var color = Color(color_data[0], color_data[1], color_data[2])
		background_sprite.material_override.albedo_color = color


## Scales the background (deprecated for 3D - camera handles projection)
func scale_to_viewport() -> void:
	# In 3D mode, the camera's perspective projection handles sizing
	# No manual scaling needed
	pass


## Observer callback - called when Scene model changes
func _on_scene_changed(scene_state: Dictionary) -> void:
	if not scene_model:
		return
	
	# Plan changed - update background and reposition/resize if needed
	var plan = scene_model.get_current_plan()
	if plan:
		var bg_config = plan.get_default_background()
		if not bg_config.is_empty():
			update_background(bg_config)
		
		# Update background size for new camera FOV
		_update_background_size()


## Updates background size based on current camera FOV
func _update_background_size() -> void:
	if not background_sprite or not scene_model:
		return
	
	var camera = scene_model.get_current_camera()
	if not camera:
		return
	
	# Recalculate size for new FOV
	var fov = camera.get_fov()
	var quad_size = Camera3DHelper.calculate_quad_size_at_distance(BACKGROUND_DISTANCE, fov, camera.ratio)
	
	# Apply overscan to account for camera movement (mouse control)
	var overscan_factors = _calculate_overscan_factors(quad_size, camera)
	quad_size.x *= overscan_factors.x
	quad_size.y *= overscan_factors.y
	
	# Update mesh size
	if background_sprite.mesh is QuadMesh:
		background_sprite.mesh.size = quad_size
	
	# Update position relative to camera
	var camera_pos = camera.position
	background_sprite.position = Vector3(camera_pos.x, camera_pos.y, camera_pos.z - BACKGROUND_DISTANCE)


## Calculates the overscan factors for width and height based on VNCamera3D's maximum offset
func _calculate_overscan_factors(quad_size: Vector2, camera: Camera) -> Vector2:
	var default_overscan = Vector2(1.15, 1.15)
	
	if not vn_scene:
		return default_overscan
	
	# Try to get the VNCamera3D from the scene
	var camera_3d = vn_scene.get_node_or_null("ActingLayer/Camera3D")
	if not camera_3d:
		return default_overscan
	
	# Get the maximum camera offset (default is 30cm)
	var max_offset = camera_3d.mouse_camera_max_offset if "mouse_camera_max_offset" in camera_3d else 30.0
	
	# Calculate how much extra background is needed based on camera movement
	# When camera moves 30cm, the background at 1000cm appears to shift
	# The shift amount relative to the visible frame size determines overscan needed
	
	# The visible frame size at the background distance is the quad_size
	# Camera movement of max_offset means we need extra coverage of max_offset on each side
	# But scaled by the perspective: movement at camera = movement * (distance_ratio) at background
	
	# Since both camera and background are considered, the actual shift at background plane
	# relative to camera position is approximately: max_offset
	var extra_coverage_needed = max_offset * 2.0  # Both directions
	
	# Calculate overscan as ratio of extra coverage to current coverage
	var overscan_x = 1.0 + (extra_coverage_needed / quad_size.x)
	var overscan_y = 1.0 + (extra_coverage_needed / quad_size.y)
	
	# Clamp to reasonable range (5% to 100% overscan)
	overscan_x = clamp(overscan_x, 1.05, 2.0)
	overscan_y = clamp(overscan_y, 1.05, 2.0)
	
	return Vector2(overscan_x, overscan_y)
