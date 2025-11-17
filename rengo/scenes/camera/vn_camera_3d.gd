## VNCamera3D - Custom Camera3D that observes Camera model
## Handles camera updates and mouse-based movement
class_name VNCamera3D
extends Camera3D

## Reference to the camera model being observed
var camera_model: Camera = null

## Mouse camera control settings
var mouse_camera_enabled: bool = true
var mouse_camera_max_offset: float = 30.0  # Max offset in cm on x and y

## Initial camera position for mouse control
var _initial_position: Vector3 = Vector3.ZERO

## Sets the camera model to observe
func observe_camera(p_camera_model: Camera) -> void:
	# Unsubscribe from previous camera if any
	if camera_model:
		camera_model.camera_changed.disconnect(_on_camera_changed)
	
	# Subscribe to new camera
	camera_model = p_camera_model
	if camera_model:
		camera_model.position = position
		camera_model.rotation = rotation
		_initial_position = camera_model.position
		camera_model.camera_changed.connect(_on_camera_changed)
		_update_from_model()


## Stops observing the current camera model
func stop_observing() -> void:
	if camera_model:
		camera_model.camera_changed.disconnect(_on_camera_changed)
		camera_model = null


## Called every frame
func _process(delta: float) -> void:
	if mouse_camera_enabled and camera_model:
		_update_camera_from_mouse()


## Observer callback for camera model changes
func _on_camera_changed(camera: Camera) -> void:
	_update_from_model()


## Updates Camera3D properties from the camera model
func _update_from_model() -> void:
	if not camera_model:
		return
	
	# Set camera position (convert cm to Godot units - 1 unit = 1 cm)
	position = camera_model.position
	
	# Set camera rotation (convert degrees to radians)
	rotation = Camera3DHelper.rotation_to_radians(camera_model.rotation)
	
	# Set FOV from focal length
	fov = camera_model.get_fov()
	
	# Set near and far clip planes (reasonable defaults for cm scale)
	near = 1.0  # 1 cm
	far = 1000000.0  # 100 meters
	
	# Make it the current camera
	current = true


## Updates camera position based on mouse position
func _update_camera_from_mouse() -> void:
	if not camera_model:
		return
	
	# Get viewport and mouse position
	var viewport = get_viewport()
	if not viewport:
		return
	
	var viewport_size = viewport.get_visible_rect().size
	var mouse_pos = viewport.get_mouse_position()
	
	# Calculate offset from center (normalized to -1..1 range)
	var center = viewport_size / 2.0
	var offset = (mouse_pos - center) / center
	
	# Clamp to -1..1 range
	offset.x = clamp(offset.x, -1.0, 1.0)
	offset.y = clamp(offset.y, -1.0, 1.0)
	
	# Apply max offset and invert y (screen space to world space)
	var position_offset = Vector3(
		offset.x * mouse_camera_max_offset,
		-offset.y * mouse_camera_max_offset,  # Invert Y for screen to world
		0.0
	)
	
	# Calculate new position
	var new_position = _initial_position + position_offset
	
	# Update camera model (observer will handle Camera3D update)
	camera_model.set_position(new_position)


## Enables or disables mouse camera control
func set_mouse_camera_enabled(enabled: bool) -> void:
	mouse_camera_enabled = enabled
	# Reset to initial position when disabling
	if not enabled and camera_model:
		camera_model.set_position(_initial_position)


## Updates the initial position (useful when plan changes)
func update_initial_position() -> void:
	if camera_model:
		_initial_position = camera_model.position


## Cleanup when node is removed from tree
func _exit_tree() -> void:
	stop_observing()
