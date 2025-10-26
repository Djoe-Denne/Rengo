## StateChangeAnimation - Fade out → change state → fade in
## Used for smooth character state transitions (pose, expression, outfit)
class_name StateChangeAnimation
extends VNAnimationNode

## Fade duration as a fraction of total duration (0.0 to 0.5)
## 0.3 means 30% fade out, 40% middle, 30% fade in
var fade_fraction: float = 0.3

## Whether the state has been changed yet
var _state_changed: bool = false

## Original alpha value
var _original_alpha: float = 1.0

## Callback to trigger state change at midpoint
var state_change_callback: Callable


func _init(p_duration: float = 0.5, p_fade_fraction: float = 0.3) -> void:
	super._init(p_duration)
	fade_fraction = clamp(p_fade_fraction, 0.0, 0.5)


## Applies the animation to target
func apply_to(target: Variant, progress: float, delta: float) -> void:
	if not target or not target.scene_node:
		return
	
	# Store original alpha on first frame
	if progress <= 0.0:
		_original_alpha = target.scene_node.modulate.a
		_state_changed = false
	
	# Calculate which phase we're in
	var fade_in_start = 1.0 - fade_fraction
	var fade_out_end = fade_fraction
	
	if progress <= fade_out_end:
		# Phase 1: Fade out
		var fade_progress = progress / fade_out_end
		var alpha = lerp(_original_alpha, 0.0, fade_progress)
		target.scene_node.modulate.a = alpha
	
	elif progress >= fade_in_start:
		# Phase 3: Fade in
		var fade_progress = (progress - fade_in_start) / fade_fraction
		var alpha = lerp(0.0, _original_alpha, fade_progress)
		target.scene_node.modulate.a = alpha
	
	else:
		# Phase 2: Middle (fully faded out, state change happens here)
		target.scene_node.modulate.a = 0.0
		
		# Trigger state change callback at midpoint (once)
		if not _state_changed and state_change_callback.is_valid():
			state_change_callback.call()
			_state_changed = true


## Setup animation
func _setup_animation() -> void:
	_state_changed = false


## Builder method to set fade fraction
func set_fade_fraction(fraction: float) -> StateChangeAnimation:
	fade_fraction = clamp(fraction, 0.0, 0.5)
	return self


## Builder method to set state change callback
func with_state_change(callback: Callable) -> StateChangeAnimation:
	state_change_callback = callback
	return self

