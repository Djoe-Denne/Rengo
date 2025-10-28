## HideAction makes a resource invisible with an optional fade-out effect
extends "res://scripts/controllers/actions/action_node.gd"
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
		_set_model_visible(false)
		_is_complete = true
		return
	
	# Start fade-out
	if fade_duration <= 0:
		_set_model_visible(false)
		_is_complete = true


## Process fade-out animation
func _process_action(_delta: float) -> void:
	if not target or not target.scene_node:
		return
	
	var progress = get_progress()
	var alpha = lerp(1.0, end_alpha, progress)
	_set_alpha(target.scene_node, alpha)


## Hide the node on completion
func on_complete() -> void:
	if target:
		_set_model_visible(false)
		if target.scene_node:
			_set_alpha(target.scene_node, end_alpha)


## Helper to set alpha on both 2D and 3D nodes
func _set_alpha(node: Node, alpha: float) -> void:
	if node is Node2D:
		# 2D node - use modulate
		node.modulate.a = alpha
	elif node is Node3D:
		# 3D node - set alpha on all MeshInstance3D children's materials
		for child in node.get_children():
			if child is MeshInstance3D and child.material_override:
				child.material_override.albedo_color.a = alpha


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


## Helper to set model visible state (works with Transformable models)
func _set_model_visible(is_visible: bool) -> void:
	# For Actor: update character.visible
	if "character" in target and target.character and target.character is Transformable:
		target.character.set_visible(is_visible)
	# For other Transformable resources
	elif target is Transformable:
		target.set_visible(is_visible)
	else:
		push_warning("HideAction: target does not have a Transformable model")

