## Factory for creating InstantAnimation instances
class_name InstantAnimationFactory
extends AnimationFactoryBase

const InstantAnimation = preload("res://rengo/infra/animation/implementations/effects/instant_animation.gd")


## Check if this factory handles the animation type
func can_create(anim_type: String) -> bool:
	return anim_type == "instant" or anim_type == ""


## Create an InstantAnimation from definition
func create(definition: Dictionary) -> VNAnimationNode:
	return InstantAnimation.new()

