## Base class for all visual novel scene resources
## ResourceNodes represent objects in the scene (characters, backgrounds, etc.)
class_name ResourceNode
extends SceneObject

## Unique identifier for this resource
var resource_name: String = ""

## Normalized position (x, y in [0.0-1.0], z for depth)
var position: Vector3 = Vector3.ZERO

## Whether this resource is currently visible
var visible: bool = false

## Reference to the actual Godot node in the scene tree
var scene_node: Node = null


func _init(p_name: String = "") -> void:
	resource_name = p_name


## Creates and auto-registers a ShowAction to make this resource visible
## Returns the ActionNode for optional chaining
func show():
	var ShowAction = load("res://scripts/controllers/actions/common/show_action.gd")
	var action = ShowAction.new(self)
	return register_action(action)


## Creates and auto-registers a HideAction to make this resource invisible
## Returns the ActionNode for optional chaining
func hide():
	var HideAction = load("res://scripts/controllers/actions/common/hide_action.gd")
	var action = HideAction.new(self)
	return register_action(action)


## Called when the resource is added to the scene
## Should be overridden by subclasses to create their visual representation
func create_scene_node(_parent: Node) -> Node:
	push_error("create_scene_node must be implemented by subclass")
	return null


## Updates the visual position based on normalized coordinates
func update_position() -> void:
	if scene_node and vn_scene:
		var screen_size = vn_scene.get_viewport().get_visible_rect().size
		var pixel_pos = Vector2(position.x * screen_size.x, position.y * screen_size.y)
		scene_node.position = pixel_pos
		
		# Handle z-depth for 3D nodes
		if scene_node is Node3D:
			scene_node.position.z = position.z


## Updates the visibility of the scene node
func update_visibility() -> void:
	if scene_node:
		scene_node.visible = visible

