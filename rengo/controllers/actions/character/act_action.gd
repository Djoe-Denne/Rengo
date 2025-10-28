## ActAction changes character/resource states with optional animation
extends "res://rengo/controllers/actions/action_node.gd"
class_name ActAction

const TransitionTypes = preload("res://rengo/infra/animation/transition/transition_types.gd")
const AnimationFactory = preload("res://rengo/infra/animation/animation_factory.gd")

## Controller reference
var controller: ActorController = null

## New states to apply
var new_states: Dictionary = {}

## Optional animation node for transition
var animation_node = null  # VNAnimationNode

## Transition type (if animation is used)
var transition_type: String = TransitionTypes.INSTANT

## Transition duration
var transition_duration: float = 0.0


func _init(p_controller: ActorController, states: Dictionary = {}) -> void:
	super._init(p_controller, 0.0)
	controller = p_controller
	
	# Parse states parameter
	if states:
		new_states = states.duplicate()


## Builder method to set transition type
func transition(type: String) -> ActAction:
	transition_type = type
	return self


## Builder method to set transition duration (using "over" instead of "in")
func over(duration_sec: float) -> ActAction:
	transition_duration = duration_sec
	duration = duration_sec
	return self


## Execute the action
func execute() -> void:
	super.execute()
	
	if not controller:
		push_error("ActAction: no controller")
		_is_complete = true
		return
	
	# Use controller to update model states
	if controller.has_method("update_model_states"):
		# If we have a transition, create and setup animation
		if transition_type != TransitionTypes.INSTANT and transition_duration > 0.0:
			_setup_animation()
		else:
			# Instant state change via controller
			controller.update_model_states(new_states)
			_is_complete = true
	else:
		push_error("ActAction: controller does not have update_model_states method")
		_is_complete = true


## Sets up the animation for the transition
func _setup_animation() -> void:
	if not controller:
		return
	
	# Create animation node using factory
	animation_node = AnimationFactory.create(transition_type, transition_duration)
	
	if animation_node:
		animation_node.play()
		# Animation now receives controller and uses apply_view_effect for visual changes
		
## Called when action completes
func on_complete() -> void:
	# Ensure state is set on the model via controller
	if controller and controller.has_method("update_model_states"):
		controller.update_model_states(new_states)
		
