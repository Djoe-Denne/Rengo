## Factory for creating animation instances based on transition type
class_name AnimationFactory
extends RefCounted

const TransitionTypes = preload("res://scripts/infra/animation/transition/transition_types.gd")

# Animation class preloads
const FadeAnimation = preload("res://scripts/infra/animation/implementations/alpha/fade_animation.gd")
const InstantAnimation = preload("res://scripts/infra/animation/implementations/effects/instant_animation.gd")


## Creates an animation instance based on the transition type
## Returns a VNAnimationNode subclass instance
static func create(type: String, target: ResourceNode = null, duration: float = 0.0) -> VNAnimationNode:
	match type:
		TransitionTypes.FADE:
			return FadeAnimation.new(target, duration)
		
		TransitionTypes.DISSOLVE:
			return DissolveAnimation.new(target, duration)
		
		TransitionTypes.INSTANT:
			return InstantAnimation.new(target)
		
		_:
			push_warning("AnimationFactory: Unknown animation type '%s', defaulting to INSTANT" % type)
			return InstantAnimation.new(target)

