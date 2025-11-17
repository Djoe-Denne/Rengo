## Plan - Configuration model for a cinematic plan/shot
## Each plan has its own camera settings and backgrounds
class_name Plan
extends RefCounted

## Plan identifier (e.g., "medium_shot", "close_up")
var plan_id: String = ""

## Camera configuration for this plan
var camera: Camera = null

## Background configurations { bg_id: config_dict }
var backgrounds: Dictionary = {}


func _init(p_plan_id: String = "") -> void:
	plan_id = p_plan_id
	camera = Camera.new()


## Gets a specific background configuration
func get_background(bg_id: String) -> Dictionary:
	return backgrounds.get(bg_id, {})


## Gets the first available background (used as default)
func get_default_background() -> Dictionary:
	if backgrounds.is_empty():
		return {}
	return backgrounds.values()[0]


## Gets the default background ID
func get_default_background_id() -> String:
	if backgrounds.is_empty():
		return ""
	return backgrounds.keys()[0]


## Adds a background configuration
func add_background(bg_id: String, config: Dictionary) -> void:
	backgrounds[bg_id] = config


## Creates a Plan from a VNCamera3D node
static func from_vn_camera(camera_node) -> Plan:  # VNCamera3D
	var plan = Plan.new(camera_node.plan_id)
	
	# Create camera from node
	plan.camera = Camera.from_vn_camera(camera_node)
	
	# Add background configuration from node's @export properties
	var bg_config = {}
	bg_config["id"] = "default"
	
	# Check if background image is set
	if camera_node.background_image:
		# Store reference to the texture directly
		bg_config["texture"] = camera_node.background_image
	elif camera_node.background_image_path != "":
		bg_config["image"] = camera_node.background_image_path
	else:
		# Use background color
		bg_config["color"] = camera_node.background_color
	
	plan.add_background("default", bg_config)
	
	return plan


## Creates a Plan from a dictionary configuration
static func from_dict(config: Dictionary) -> Plan:
	var plan = Plan.new(config.get("id", ""))
	
	# Parse camera configuration
	if "camera" in config:
		plan.camera = Camera.from_dict(config.camera)
	
	# Parse backgrounds
	if "backgrounds" in config:
		for bg_config in config.backgrounds:
			var bg_id = bg_config.get("id", "")
			if bg_id != "":
				plan.add_background(bg_id, bg_config)
	
	return plan

