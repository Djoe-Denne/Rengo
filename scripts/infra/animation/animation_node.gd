## Base class for animation system
## Abstract class that provides common animation functionality
## Subclasses implement specific animation types (easing, effects, shaders, etc.)
## AnimationNodes are composed by AnimatedActions, not directly tied to targets
class_name VNAnimationNode
extends RefCounted

## Emitted when the animation completes
signal animation_complete()

## Duration of the animation in seconds
var duration: float = 0.0

## Whether the animation is currently playing
var is_playing: bool = false

## Whether the animation should loop
var loop: bool = false

## Starting value for the animation
var from_value: Variant = null

## Ending value for the animation
var to_value: Variant = null

## Internal elapsed time
var _elapsed_time: float = 0.0


func _init(p_duration: float = 0.0) -> void:
	duration = p_duration


## Starts the animation
func play() -> void:
	is_playing = true
	_elapsed_time = 0.0
	_setup_animation()


## Stops the animation
func stop() -> void:
	is_playing = false
	_elapsed_time = 0.0


## Processes the animation for one frame
## Returns true when the animation is complete
func process(delta: float) -> bool:
	if not is_playing:
		return true
	
	_elapsed_time += delta
	
	# Handle instant animations
	if duration <= 0.0:
		_finish_animation()
		return true
	
	# Calculate progress
	var progress = clamp(_elapsed_time / duration, 0.0, 1.0)
	
	# Check if complete
	if _elapsed_time >= duration:
		if loop:
			_elapsed_time = 0.0
			_on_loop()
			return false
		else:
			_finish_animation()
			return true
	
	return false


## Gets the current progress of the animation (0.0 to 1.0)
func get_progress() -> float:
	if duration <= 0.0:
		return 1.0
	return clamp(_elapsed_time / duration, 0.0, 1.0)


## Applies animation to a target for the current frame
## Override this in subclasses to implement specific animation behavior
## target: The object to animate (ResourceNode, Node, etc.)
## progress: 0.0 to 1.0 normalized time
## delta: time elapsed since last frame
func apply_to(target: Variant, progress: float, delta: float) -> void:
	push_error("VNAnimationNode: apply_to() must be implemented by subclass")


## Setup animation - override in subclasses if needed
func _setup_animation() -> void:
	pass


## Called when animation loops - override in subclasses if needed
func _on_loop() -> void:
	pass


## Finishes the animation
func _finish_animation() -> void:
	is_playing = false
	animation_complete.emit()


## Builder method to set loop
func set_loop(should_loop: bool) -> VNAnimationNode:
	loop = should_loop
	return self


## Builder method to set duration
func set_duration(p_duration: float) -> VNAnimationNode:
	duration = p_duration
	return self


## Builder method to set values
func set_values(p_from: Variant, p_to: Variant) -> VNAnimationNode:
	from_value = p_from
	to_value = p_to
	return self

