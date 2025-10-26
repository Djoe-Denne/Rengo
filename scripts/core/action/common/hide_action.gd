## HideAction makes a resource invisible with an optional fade-out effect
extends "res://scripts/core/action/action_node.gd"
class_name HideAction

## Fade-out duration (0 = instant)
var fade_duration: float = 0.3

## Ending alpha value
var end_alpha: float = 0.0


func _init(p_target = null, p_fade_duration: float = 0.3) -> void:
	super._init(p_target, p_fade_duration)
	fade_duration = p_fade_duration
	duration = fade_duration


## Start the hide action
func execute() -> void:
	super.execute()
	
	if not target:
		push_error("HideAction: no target resource")
		_is_complete = true
		return
	
	if not target.scene_node:
		# Already hidden or never shown
		_is_complete = true
		return
	
	# Start fade-out
	if fade_duration <= 0:
		target.visible = false
		target.update_visibility()
		_is_complete = true


## Process fade-out animation
func _process_action(_delta: float) -> void:
	if not target or not target.scene_node:
		return
	
	var progress = get_progress()
	target.scene_node.modulate.a = lerp(1.0, end_alpha, progress)


## Hide the node on completion
func on_complete() -> void:
	if target:
		target.visible = false
		if target.scene_node:
			target.scene_node.modulate.a = end_alpha
		target.update_visibility()


## Builder method to set fade duration
func with_fade(p_duration: float) -> HideAction:
	fade_duration = p_duration
	duration = p_duration
	return self


## Builder method to hide instantly
func instant() -> HideAction:
	fade_duration = 0.0
	duration = 0.0
	return self

