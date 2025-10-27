## Factory for creating TransformAnimation instances
class_name TransformAnimationFactory
extends AnimationFactoryBase

const TransformAnimation = preload("res://scripts/infra/animation/implementations/transform/transform_animation.gd")


## Check if this factory handles the animation type
func can_create(anim_type: String) -> bool:
	return anim_type == "transform"


## Create a TransformAnimation from definition
func create(definition: Dictionary) -> VNAnimationNode:
	var duration = _get_duration(definition)
	var params = _get_parameters(definition)
	
	# Parse easing
	var easing_str = params.get("easing", "linear")
	var easing = _parse_easing(easing_str)
	
	var anim = TransformAnimation.new(duration, easing)
	
	# Set shake parameters if present
	if params.has("shake_intensity"):
		var intensity = params.shake_intensity
		var frequency = params.get("shake_frequency", 20.0)
		anim.set_shake(intensity, frequency)
	
	return anim


## Parse easing string to EasingType enum
func _parse_easing(easing_str: String) -> int:
	match easing_str.to_lower():
		"linear":
			return TransformAnimation.EasingType.LINEAR
		"ease_in":
			return TransformAnimation.EasingType.EASE_IN
		"ease_out":
			return TransformAnimation.EasingType.EASE_OUT
		"ease_in_out":
			return TransformAnimation.EasingType.EASE_IN_OUT
		"elastic_in":
			return TransformAnimation.EasingType.ELASTIC_IN
		"elastic_out":
			return TransformAnimation.EasingType.ELASTIC_OUT
		"elastic_in_out":
			return TransformAnimation.EasingType.ELASTIC_IN_OUT
		"bounce_in":
			return TransformAnimation.EasingType.BOUNCE_IN
		"bounce_out":
			return TransformAnimation.EasingType.BOUNCE_OUT
		"bounce_in_out":
			return TransformAnimation.EasingType.BOUNCE_IN_OUT
		"back_in":
			return TransformAnimation.EasingType.BACK_IN
		"back_out":
			return TransformAnimation.EasingType.BACK_OUT
		"back_in_out":
			return TransformAnimation.EasingType.BACK_IN_OUT
		_:
			return TransformAnimation.EasingType.LINEAR

