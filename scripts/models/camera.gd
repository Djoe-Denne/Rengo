## Camera - Pure data model for camera configuration
## Holds camera parameters for cinematic rendering
## Notifies observers when camera properties change
class_name Camera
extends RefCounted

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

## List of observers (Callables) watching this camera
var _observers: Array = []


func _init(p_ratio: float = 1.777) -> void:
	ratio = p_ratio


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
	
	# Parse position (in centimeters)
	if "position" in config:
		var pos = config.position
		if pos is Array and pos.size() >= 3:
			camera.position = Vector3(pos[0], pos[1], pos[2])
		elif pos is Dictionary:
			camera.position = Vector3(
				pos.get("x", 0.0),
				pos.get("y", 0.0),
				pos.get("z", 0.0)
			)
	
	# Parse rotation (in degrees)
	if "rotation" in config:
		var rot = config.rotation
		if rot is Array and rot.size() >= 3:
			camera.rotation = Vector3(rot[0], rot[1], rot[2])
		elif rot is Dictionary:
			camera.rotation = Vector3(
				rot.get("pitch", 0.0),
				rot.get("yaw", 0.0),
				rot.get("roll", 0.0)
			)
	
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


## Adds an observer to be notified of camera changes
func add_observer(observer: Callable) -> void:
	if not _observers.has(observer):
		_observers.append(observer)


## Removes an observer
func remove_observer(observer: Callable) -> void:
	var idx = _observers.find(observer)
	if idx >= 0:
		_observers.remove_at(idx)


## Notifies all observers of camera changes
func _notify_observers() -> void:
	var camera_state = {
		"position": position,
		"rotation": rotation,
		"focal_default": focal_default,
		"ratio": ratio
	}
	
	for observer in _observers:
		if observer.is_valid():
			observer.call(camera_state)


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

