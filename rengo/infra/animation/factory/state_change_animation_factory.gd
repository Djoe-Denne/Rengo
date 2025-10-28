## Factory for creating StateChangeAnimation instances
class_name StateChangeAnimationFactory
extends AnimationFactoryBase

const StateChangeAnimation = preload("res://rengo/infra/animation/implementations/state_change_animation.gd")


## Check if this factory handles the animation type
func can_create(anim_type: String) -> bool:
	return anim_type == "state_change"


## Create a StateChangeAnimation from definition
func create(definition: Dictionary) -> VNAnimationNode:
	var duration = _get_duration(definition)
	var params = _get_parameters(definition)
	
	var fade_fraction = params.get("fade_fraction", 0.3)
	
	# Parse target mode
	var target_mode_str = params.get("target_mode", "whole_node")
	var target_mode = _parse_target_mode(target_mode_str)
	
	var anim = StateChangeAnimation.new(duration, fade_fraction, target_mode)
	
	# Set specific target layers if provided
	if params.has("target_layers") and params.target_layers is Array:
		anim.set_target_layers(params.target_layers)
	
	return anim


## Parse target mode string to TargetMode enum
func _parse_target_mode(target_mode_str: String) -> int:
	match target_mode_str.to_lower():
		"whole_node":
			return StateChangeAnimation.TargetMode.WHOLE_NODE
		"individual_layers":
			return StateChangeAnimation.TargetMode.INDIVIDUAL_LAYERS
		"specific_layers":
			return StateChangeAnimation.TargetMode.SPECIFIC_LAYERS
		_:
			return StateChangeAnimation.TargetMode.WHOLE_NODE

