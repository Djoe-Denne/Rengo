## StageView - Pure view component for rendering backgrounds
## Observes Scene model and updates display when plan changes
class_name StageView
extends Node3D

## The actual background mesh in the scene (3D)
var background_sprite: MeshInstance3D = null

@export var scaling_mode: String = "letterbox"
@export var default_plan_id: String = ""

## Reference to the Scene model (for observing)
@onready var scene_model: Scene = Scene.get_instance()

## Distance of background from camera (in centimeters)
const BACKGROUND_DISTANCE = 1000.0

static var instance: StageView = null

static func get_instance() -> StageView:
	if not instance:
		StageView.new()
	return instance

func _init() -> void:
	instance = self

## Creates the initial background mesh (3D quad)
func _ready() -> void:
	
	# Create 3D quad mesh for background
	background_sprite = MeshInstance3D.new()
	background_sprite.name = "Background"
	
	var quad_mesh = QuadMesh.new()
	background_sprite.mesh = quad_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_BACK
	background_sprite.material_override = material
	
	add_child(background_sprite)

## Updates the background texture based on configuration (DEPRECATED - use update_background_from_camera)
func update_background(bg_config: Dictionary) -> void:
	if not background_sprite or not background_sprite.material_override:
		return
	
	if "image" in bg_config:
		var image_path = bg_config.image
		if ResourceLoader.exists(image_path):
			var texture = load(image_path)
			background_sprite.material_override.albedo_texture = texture
		else:
			push_error("StageView: Background image not found: %s" % image_path)
	elif "color" in bg_config:
		# Create colored background
		var color_data = bg_config.color
		var color = Color(color_data[0], color_data[1], color_data[2])
		background_sprite.material_override.albedo_color = color
	
	
	# Update background size for new camera FOV
	_update_background_size()


## Scales the background (deprecated for 3D - camera handles projection)
func scale_to_viewport() -> void:
	# In 3D mode, the camera's perspective projection handles sizing
	# No manual scaling needed
	pass


## Observer callback - called when Scene model changes
## camera_node: VNCamera3D node for the new plan
func on_scene_changed(plan_id: String) -> void:  # camera_node: VNCamera3D
	# Update background from plan
	update_background(scene_model.get_current_plan().get_default_background())
		


## Updates background size based on current camera FOV
func _update_background_size() -> void:
	if not background_sprite or not scene_model:
		push_error("StageView: No background sprite or scene model")
		return
	
	var camera = scene_model.get_current_camera()
	if not camera:
		push_error("StageView: No camera in scene model")
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


## Gets an actor controller by name from child actors
func get_actor_controller(actor_name: String):  # -> ActorController
	for child in get_children():
		if child.get_script() and child.get_script().get_global_name() == "Actor":
			if child.actor_name == actor_name:
				return child.get_controller()
	return null


## Calculates the overscan factors for width and height based on VNCamera3D's maximum offset
func _calculate_overscan_factors(quad_size: Vector2, camera: Camera) -> Vector2:
	var default_overscan = Vector2(1.15, 1.15)
	
	
	# Get the maximum camera offset (default is 30cm)
	var max_offset = 30.0
	
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
