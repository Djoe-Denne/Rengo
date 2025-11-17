## VNCamera3D - Custom Camera3D that observes Camera model
## Handles camera updates and mouse-based movement
class_name VNCamera3D
extends Camera3D

## Plan identifier for this camera (e.g., "medium_shot", "close_up")
@export var plan_id: String = ""

## Camera Properties
@export_group("Camera Properties")
@export var ratio: float = 1.777
@export var focal_min: float = 24.0
@export var focal_max: float = 200.0
@export var focal_default: float = 50.0
@export var aperture: float = 2.8
@export var shutter_speed: float = 50.0
@export var sensor_size: String = "fullframe"  # "fullframe", "apsc", "micro43", "super35", "super16"

## Background Configuration
@export_group("Background")
@export var background_image: Texture2D
@export_file("*.png","*.jpg","*.jpeg") var background_image_path: String = ""
@export var background_color: Color = Color(0.2, 0.2, 0.3)

## Reference to the camera model being observed
var camera_model: Camera = null

## Mouse camera control settings
@export var mouse_camera_enabled: bool = true
@export var mouse_camera_max_offset: float = 30.0  # Max offset in cm on x and y

## Initial camera position for mouse control
var _initial_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	# Create camera model from @export properties if plan_id is set
	if plan_id != "":
		camera_model = create_camera_model()
		_initial_position = camera_model.position
		camera_model.camera_changed.connect(_on_camera_changed)
		_update_from_model()


## Creates a Camera model from this node's @export properties
func create_camera_model() -> Camera:
	var camera = Camera.new(ratio)
	camera.focal_min = focal_min
	camera.focal_max = focal_max
	camera.focal_default = focal_default
	camera.aperture = aperture
	camera.shutter_speed = shutter_speed
	camera.sensor_size = sensor_size
	
	# Set position and rotation from node's transform
	camera.position = position
	# Convert radians to degrees (Camera model stores rotation in degrees)
	camera.rotation = Vector3(
		rad_to_deg(rotation.x),
		rad_to_deg(rotation.y),
		rad_to_deg(rotation.z)
	)
	
	return camera


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

func update_from_editor() -> void:
	var t_fov = Camera3DHelper.calculate_fov(focal_default, sensor_size, ratio)


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

func _notification(what):
	print(Engine.is_editor_hint())
	if what == NOTIFICATION_READY and Engine.is_editor_hint():
		update_from_editor()
	elif what == NOTIFICATION_EDITOR_PROPERTY_CHANGED and Engine.is_editor_hint():
		update_from_editor()
