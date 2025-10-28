## Base class for all visual novel scene resources
## ResourceNodes represent VIEW objects in the scene (characters, backgrounds, etc.)
## State properties (position, visible, etc.) now live in MODEL classes
## This class provides view coordination and scene node management
class_name ResourceNode
extends SceneObject

## Unique identifier for this resource
var resource_name: String = ""

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


## Updates the visual position in 3D space
## Subclasses should override this to read from their model
func update_position() -> void:
	push_warning("ResourceNode.update_position should be overridden by subclass")


## Updates the visibility of the scene node
## Subclasses should override this to read from their model
func update_visibility() -> void:
	push_warning("ResourceNode.update_visibility should be overridden by subclass")

