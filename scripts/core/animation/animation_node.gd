## Base class for animation system
## Abstract class that provides common animation functionality
## Subclasses implement specific animation types
class_name VNAnimationNode
extends RefCounted

## Emitted when the animation completes
signal animation_complete()

## The scene node to animate
var target_node: ResourceNode = null

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


func _init(p_target: ResourceNode = null, p_duration: float = 0.0) -> void:
	target_node = p_target
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
	print("VNAnimationNode process")
	if not is_playing or not target_node:
		return true
	
	_elapsed_time += delta
	
	# Handle instant animations
	if duration <= 0.0:
		_apply_final_value()
		_finish_animation()
		return true
	
	# Calculate progress
	var progress = clamp(_elapsed_time / duration, 0.0, 1.0)
	
	# Let subclass handle the animation
	_process_animation(progress, delta)
	
	# Check if complete
	if _elapsed_time >= duration:
		if loop:
			_elapsed_time = 0.0
			_on_loop()
			return false
		else:
			_apply_final_value()
			_finish_animation()
			return true
	
	return false


## Setup animation - override in subclasses if needed
func _setup_animation() -> void:
	pass


## Abstract method - subclasses must implement
## progress: 0.0 to 1.0 normalized time
## delta: time elapsed since last frame
func _process_animation(_progress: float, _delta: float) -> void:
	push_error("VNAnimationNode: _process_animation() must be implemented by subclass")


## Applies the final value - override in subclasses
func _apply_final_value() -> void:
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

