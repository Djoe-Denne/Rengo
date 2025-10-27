## Camera3DHelper - Utility for 3D camera and optical calculations
## Converts photographic parameters to 3D engine values
class_name Camera3DHelper
extends RefCounted

## Sensor size constants in millimeters (horizontal dimension)
const SENSOR_SIZES = {
	"fullframe": 36.0,
	"apsc": 23.6,
	"micro43": 17.3,
	"super35": 24.89,
	"super16": 12.52
}


## Calculates vertical FOV in degrees from focal length and sensor size
## @param focal_mm: Focal length in millimeters
## @param sensor_size: Sensor size identifier (e.g., "fullframe")
## @param aspect_ratio: Camera aspect ratio (e.g., 1.777 for 16:9)
## @return: Vertical field of view in degrees
static func calculate_fov(focal_mm: float, sensor_size: String, aspect_ratio: float = 1.777) -> float:
	var sensor_width = SENSOR_SIZES.get(sensor_size, 36.0)
	var sensor_height = sensor_width / aspect_ratio
	
	# Calculate vertical FOV using the pinhole camera formula
	# FOV = 2 * arctan(sensor_height / (2 * focal_length))
	var fov_radians = 2.0 * atan(sensor_height / (2.0 * focal_mm))
	var fov_degrees = rad_to_deg(fov_radians)
	
	return fov_degrees


## Calculates the size of a quad needed to fill the camera frame at a given distance
## @param distance_cm: Distance from camera in centimeters
## @param fov_degrees: Vertical field of view in degrees
## @param aspect_ratio: Width/height ratio
## @return: Vector2 with width and height in centimeters
static func calculate_quad_size_at_distance(distance_cm: float, fov_degrees: float, aspect_ratio: float) -> Vector2:
	var fov_radians = deg_to_rad(fov_degrees)
	
	# Calculate height using FOV
	# height = 2 * distance * tan(FOV/2)
	var height = 2.0 * distance_cm * tan(fov_radians / 2.0)
	var width = height * aspect_ratio
	
	return Vector2(width, height)


## Converts rotation in degrees (pitch, yaw, roll) to Godot's rotation order
## @param rotation_deg: Vector3 with pitch, yaw, roll in degrees
## @return: Vector3 with rotation in radians (Godot format: x=pitch, y=yaw, z=roll)
static func rotation_to_radians(rotation_deg: Vector3) -> Vector3:
	return Vector3(
		deg_to_rad(rotation_deg.x),  # pitch
		deg_to_rad(rotation_deg.y),  # yaw
		deg_to_rad(rotation_deg.z)   # roll
	)


## Converts focal length range to zoom limits for a Camera3D
## @param focal_min: Minimum focal length in mm
## @param focal_max: Maximum focal length in mm
## @param sensor_size: Sensor size identifier
## @param aspect_ratio: Camera aspect ratio
## @return: Dictionary with "min_fov" and "max_fov" in degrees
static func focal_range_to_fov_range(focal_min: float, focal_max: float, sensor_size: String, aspect_ratio: float) -> Dictionary:
	return {
		"min_fov": calculate_fov(focal_max, sensor_size, aspect_ratio),  # max focal = min FOV (zoomed in)
		"max_fov": calculate_fov(focal_min, sensor_size, aspect_ratio)   # min focal = max FOV (zoomed out)
	}

