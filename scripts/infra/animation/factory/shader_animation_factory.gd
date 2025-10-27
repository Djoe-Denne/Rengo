## Factory for creating ShaderAnimation instances
class_name ShaderAnimationFactory
extends AnimationFactoryBase

const ShaderAnimation = preload("res://scripts/infra/animation/implementations/shader_animation.gd")


## Check if this factory handles the animation type
func can_create(anim_type: String) -> bool:
	return anim_type == "shader"


## Create a ShaderAnimation from definition
func create(definition: Dictionary) -> VNAnimationNode:
	var duration = _get_duration(definition)
	var params = _get_parameters(definition)
	
	var anim = ShaderAnimation.new(duration)
	
	# Set shader path if provided
	if params.has("shader_path"):
		anim.with_shader(params.shader_path)
	
	# Set shader parameters if provided
	if params.has("shader_params"):
		anim.set_shader_params(params.shader_params)
	
	return anim

