## Director - Base class for managing displayable resources
## Directors handle how displayables are rendered and updated
class_name Director
extends RefCounted

## The scene path this director is working with
var scene_path: String = ""

## Reference to Scene model (for observing plan changes)
var scene_model: Scene = null


## Prepares the director with the scene path
func prepare(p_scene_path: String) -> void:
	scene_path = p_scene_path


## Sets the scene model and subscribes to changes
func set_scene_model(p_scene_model: Scene) -> void:
	scene_model = p_scene_model
	
	# Subscribe to scene changes
	if scene_model:
		scene_model.add_observer(_on_scene_changed)


## Observer callback - called when Scene model changes
func _on_scene_changed(scene_state: Dictionary) -> void:
	# Plan changed - subclasses can override to refresh displayables
	pass


## Instructs a displayable to change its appearance/state
## Must be implemented by subclasses
func instruct(displayable, new_states: Dictionary = {}) -> void:
	push_error("instruct() must be implemented by subclass")

