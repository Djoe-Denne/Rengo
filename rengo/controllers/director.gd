## Director - Base class for managing displayable resources
## Directors handle how displayables are rendered and updated
class_name Director
extends RefCounted

## Reference to Scene model (for observing plan changes)
var scene_model: Scene = null

## Reference to controller
var controller: Controller = null

func _init() -> void:
	pass

## Sets the controller
func set_controller(p_controller: Controller) -> void:
	controller = p_controller

## Sets the scene model and subscribes to changes
func set_scene_model(p_scene_model: Scene) -> void:
	scene_model = p_scene_model
	

## Observer callback - called when Scene model changes
func on_scene_changed() -> void:
	instruct(controller.get_model().get_states())

## Instructs a displayable to change its appearance/state
## Must be implemented by subclasses
func instruct(new_states: Dictionary = {}) -> void:
	push_error("instruct() must be implemented by subclass")
