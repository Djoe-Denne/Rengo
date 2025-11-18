## Camera - Pure data model for camera configuration
## Holds camera parameters for cinematic rendering
## Notifies observers when camera properties change
class_name Camera
extends RefCounted

signal camera_changed(Camera: Camera)

## Aspect ratio (e.g., 1.777 for 16:9, 2.35 for cinemascope)
var ratio: float = 1.777

## Focal length range in millimeters
var focal_min: float = 24.0
var focal_max: float = 200.0
var focal_default: float = 50.0

## Aperture (f-stop value)
var aperture: float = 2.8

## Shutter speed
var shutter_speed: float = 50.0

## Sensor size identifier (e.g., "fullframe", "micro43", "apsc")
var sensor_size: String = "fullframe"

## Camera position in centimeters (3D world space)
var position: Vector3 = Vector3.ZERO

## Camera rotation in degrees (pitch, yaw, roll)
var rotation: Vector3 = Vector3.ZERO

func _init(p_ratio: float = 1.777) -> void:
	ratio = p_ratio


## Creates a Camera from a VNCamera3D node
static func from_vn_camera(camera_node) -> Camera:  # VNCamera3D
	var camera = Camera.new(camera_node.ratio)
	camera.focal_min = camera_node.focal_min
	camera.focal_max = camera_node.focal_max
	camera.focal_default = camera_node.focal_default
	camera.aperture = camera_node.aperture
	camera.shutter_speed = camera_node.shutter_speed
	camera.sensor_size = camera_node.sensor_size
	
	# Set position and rotation from node's transform
	camera.position = camera_node.position
	# Convert radians to degrees (Camera model stores rotation in degrees)
	camera.rotation = Vector3(
		rad_to_deg(camera_node.rotation.x),
		rad_to_deg(camera_node.rotation.y),
		rad_to_deg(camera_node.rotation.z)
	)
	
	return camera


## Creates a Camera from a dictionary configuration
static func from_dict(config: Dictionary) -> Camera:
	var camera = Camera.new(config.get("ratio", 1.777))
	
	# Parse focal settings
	if "focal" in config:
		var focal = config.focal
		camera.focal_min = focal.get("min", 24.0)
		camera.focal_max = focal.get("max", 200.0)
		camera.focal_default = focal.get("default", 50.0)
	
	camera.aperture = config.get("aperture", 2.8)
	camera.shutter_speed = config.get("shutter_speed", 50.0)
	camera.sensor_size = config.get("sensor_size", "fullframe")
	
	return camera


## Returns camera configuration as a dictionary
func to_dict() -> Dictionary:
	return {
		"ratio": ratio,
		"focal": {
			"min": focal_min,
			"max": focal_max,
			"default": focal_default
		},
		"aperture": aperture,
		"shutter_speed": shutter_speed,
		"sensor_size": sensor_size,
		"position": {
			"x": position.x,
			"y": position.y,
			"z": position.z
		},
		"rotation": {
			"pitch": rotation.x,
			"yaw": rotation.y,
			"roll": rotation.z
		}
	}


## Calculates the current FOV based on focal length and sensor size
func get_fov() -> float:
	return Camera3DHelper.calculate_fov(focal_default, sensor_size, ratio)


## Gets the FOV range based on min/max focal lengths
func get_fov_range() -> Dictionary:
	return Camera3DHelper.focal_range_to_fov_range(focal_min, focal_max, sensor_size, ratio)

## Notifies all observers of camera changes
func _notify_observers() -> void:
	camera_changed.emit(self)


## Sets camera position and notifies observers
func set_position(new_position: Vector3) -> void:
	if position != new_position:
		position = new_position
		_notify_observers()


## Sets camera rotation and notifies observers
func set_rotation(new_rotation: Vector3) -> void:
	if rotation != new_rotation:
		rotation = new_rotation
		_notify_observers()


## Sets focal length and notifies observers
func set_focal_default(new_focal: float) -> void:
	if focal_default != new_focal:
		focal_default = new_focal
		_notify_observers()


## Sets aspect ratio and notifies observers
func set_ratio(new_ratio: float) -> void:
	if ratio != new_ratio:
		ratio = new_ratio
		_notify_observers()
