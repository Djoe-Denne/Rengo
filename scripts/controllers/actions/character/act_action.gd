## ActAction changes character/resource states with optional animation
extends "res://scripts/controllers/actions/action_node.gd"
class_name ActAction

const TransitionTypes = preload("res://scripts/infra/animation/transition/transition_types.gd")
const AnimationFactory = preload("res://scripts/infra/animation/animation_factory.gd")

## New states to apply
var new_states: Dictionary = {}

## Optional animation node for transition
var animation_node = null  # VNAnimationNode

## Transition type (if animation is used)
var transition_type: String = TransitionTypes.INSTANT

## Transition duration
var transition_duration: float = 0.0


func _init(p_target = null, states: Dictionary = {}) -> void:
	super._init(p_target, 0.0)
	
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
	
	if not target:
		push_error("ActAction: no target resource")
		_is_complete = true
		return
	
	# For Actors, update the Character model
	if "character" in target and target.character:
		# If we have a transition, create and setup animation
		if transition_type != TransitionTypes.INSTANT and transition_duration > 0.0:
			_setup_animation()
		else:
			# Instant state change via Character model
			target.character.update_states(new_states)
			_is_complete = true
	# Fallback for legacy resources
	elif target.has_method("set_states"):
		if transition_type != TransitionTypes.INSTANT and transition_duration > 0.0:
			_setup_animation()
		else:
			target.set_states(new_states)
			_is_complete = true
	else:
		push_warning("ActAction: target does not support states")
		_is_complete = true


## Sets up the animation for the transition
func _setup_animation() -> void:
	if not target or not target.scene_node:
		return
	
	# Create animation node using factory
	animation_node = AnimationFactory.create(transition_type, target, transition_duration)
	
	animation_node.play()
	# Change state at halfway point (will be handled in process)
	target.add_animation(animation_node)
		
## Called when action completes
func on_complete() -> void:
	# Ensure state is set
	if target:
		if "character" in target and target.character:
			target.character.update_states(new_states)
		elif target.has_method("set_states"):
			target.set_states(new_states)
		
