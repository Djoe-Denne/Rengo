## Camera resource for visual novel scenes
## Controls the viewport camera position and zoom
extends "res://scripts/domain/resource_node.gd"
class_name VNCamera

## Zoom level (1.0 = default, >1.0 = zoomed in, <1.0 = zoomed out)
var zoom: float = 1.0

## Target to follow (can be a ResourceNode)
var follow_target = null


func _init(p_name: String = "camera") -> void:
	super._init(p_name)
	var NormalizedPosition = load("res://scripts/infra/normalized_position.gd")
	position = NormalizedPosition.center()


## Creates a Camera2D node
func create_scene_node(parent: Node) -> Node:
	var camera = Camera2D.new()
	camera.name = "VNCamera_" + resource_name
	camera.enabled = true
	
	parent.add_child(camera)
	scene_node = camera
	
	update_zoom()
	return camera


## Updates the camera's zoom level
func update_zoom() -> void:
	if scene_node and scene_node is Camera2D:
		scene_node.zoom = Vector2(zoom, zoom)


## Sets the zoom level
func set_zoom(new_zoom: float) -> void:
	zoom = new_zoom
	update_zoom()


## Sets a target for the camera to follow
func set_follow_target(target) -> void:
	follow_target = target


## Updates camera position, optionally following a target
func update_position() -> void:
	if not scene_node or not vn_scene:
		return
	
	var NormalizedPosition = load("res://scripts/infra/normalized_position.gd")
	var target_pos: Vector3
	var screen_size = vn_scene.get_viewport().get_visible_rect().size
	
	if follow_target and follow_target.scene_node:
		# Follow the target
		target_pos = NormalizedPosition.from_pixels(follow_target.scene_node.position, screen_size)
	else:
		# Use own position
		target_pos = position
	
	var pixel_pos = Vector2(target_pos.x * screen_size.x, target_pos.y * screen_size.y)
	scene_node.position = pixel_pos

