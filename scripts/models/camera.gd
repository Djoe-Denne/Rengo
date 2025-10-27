## Camera - Pure data model for camera configuration
## Holds camera parameters for cinematic rendering
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
		"sensor_size": sensor_size
	}

