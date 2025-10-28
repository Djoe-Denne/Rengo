## HideAction makes a resource invisible with an optional fade-out effect
extends "res://scripts/controllers/actions/action_node.gd"
class_name HideAction

## Controller reference
var controller: ActorController = null

## Fade-out duration (0 = instant)
var fade_duration: float = 0.3

## Ending alpha value
var end_alpha: float = 0.0


func _init(p_controller: ActorController, p_fade_duration: float = 0.3) -> void:
	super._init(p_controller, p_fade_duration)
	controller = p_controller
	fade_duration = p_fade_duration
	duration = fade_duration


## Start the hide action
func execute() -> void:
	super.execute()
	
	if not controller:
		push_error("HideAction: no controller")
		_is_complete = true
		return
	
	# Use controller to update model visibility
	if controller.has_method("update_model_visible"):
		controller.update_model_visible(false)
		_is_complete = true
	elif controller.model and controller.model.has_method("set_visible"):
		controller.model.set_visible(false)
		_is_complete = true
	else:
		push_error("HideAction: controller cannot update visibility")
		_is_complete = true


## Process fade-out animation
## TODO: Implement fade animations via controller.apply_view_effect()
func _process_action(_delta: float) -> void:
	# Fade animations would use controller.apply_view_effect() to manipulate alpha
	# For now, instant hide
	pass


## Hide on completion
func on_complete() -> void:
	if controller and controller.has_method("update_model_visible"):
		controller.update_model_visible(false)

