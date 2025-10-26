## ShowAction makes a resource visible with an optional fade-in effect
extends "res://scripts/controllers/actions/action_node.gd"
class_name ShowAction

## Fade-in duration (0 = instant)
var fade_duration: float = 0.3

## Starting alpha value
var start_alpha: float = 0.0


func _init(p_target = null, p_fade_duration: float = 0.3) -> void:
	super._init(p_target, p_fade_duration)
	fade_duration = p_fade_duration
	duration = fade_duration


## Start the show action
func execute() -> void:
	super.execute()
	
	if not target:
		push_error("ShowAction: no target resource")
		_is_complete = true
		return
	
	# Create the scene node if it doesn't exist
	if not target.scene_node and target.vn_scene:
		var acting_layer = target.vn_scene.get_node_or_null("ActingLayer")
		if acting_layer:
			target.create_scene_node(acting_layer)
	
	# Make visible
	target.visible = true
	
	if target.scene_node:
		# Set initial alpha for fade-in
		if fade_duration > 0:
			target.scene_node.modulate.a = start_alpha
		else:
			target.scene_node.modulate.a = 1.0
			_is_complete = true
		
		target.update_visibility()
		target.update_position()


## Process fade-in animation
func _process_action(_delta: float) -> void:
	if not target or not target.scene_node:
		return
	
	var progress = get_progress()
	target.scene_node.modulate.a = lerp(start_alpha, 1.0, progress)


## Ensure full opacity on completion
func on_complete() -> void:
	if target and target.scene_node:
		target.scene_node.modulate.a = 1.0


## Builder method to set fade duration
func with_fade(p_duration: float) -> ShowAction:
	fade_duration = p_duration
	duration = p_duration
	return self


## Builder method to show instantly
func instant() -> ShowAction:
	fade_duration = 0.0
	duration = 0.0
	return self
