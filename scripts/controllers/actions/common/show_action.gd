## ShowAction makes a resource visible with an optional fade-in effect
extends "res://scripts/controllers/actions/action_node.gd"
class_name ShowAction

## Controller reference
var controller: ActorController = null

## Fade-in duration (0 = instant)
var fade_duration: float = 0.3

## Starting alpha value
var start_alpha: float = 0.0


func _init(p_controller: ActorController, p_fade_duration: float = 0.3) -> void:
	super._init(p_controller, p_fade_duration)
	controller = p_controller
	fade_duration = p_fade_duration
	duration = fade_duration


## Start the show action
func execute() -> void:
	super.execute()
	
	if not controller:
		push_error("ShowAction: no controller")
		_is_complete = true
		return
	
	# Use controller to update model visibility
	if controller.has_method("update_model_visible"):
		controller.update_model_visible(true)
	elif controller.model and controller.model.has_method("set_visible"):
		controller.model.set_visible(true)
	else:
		push_error("ShowAction: controller cannot update visibility")
		_is_complete = true
		return
	
	# For fade animations, we need to manipulate view alpha
	# The model visibility is already set, view will update through observer
	# For now, instant show
	if fade_duration <= 0:
		_is_complete = true


## Process fade-in animation
## TODO: Implement fade animations via controller.apply_view_effect()
func _process_action(_delta: float) -> void:
	# Fade animations would use controller.apply_view_effect() to manipulate alpha
	# For now, instant show
	pass


## Ensure visibility is set on completion
func on_complete() -> void:
	if controller and controller.has_method("update_model_visible"):
		controller.update_model_visible(true)
