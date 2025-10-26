## Factory for creating animation instances based on transition type
## DEPRECATED: Use AnimationRepository instead for new code
## This factory is kept for backward compatibility with legacy code
class_name AnimationFactory
extends RefCounted

const TransitionTypes = preload("res://scripts/infra/animation/transition/transition_types.gd")

# Animation class preloads
const FadeAnimation = preload("res://scripts/infra/animation/implementations/alpha/fade_animation.gd")
const InstantAnimation = preload("res://scripts/infra/animation/implementations/effects/instant_animation.gd")
const TransformAnimation = preload("res://scripts/infra/animation/implementations/transform/transform_animation.gd")
const StateChangeAnimation = preload("res://scripts/infra/animation/implementations/state_change_animation.gd")


## Creates an animation instance based on the transition type
## Returns a VNAnimationNode subclass instance
## NOTE: This is legacy API - new code should use AnimationRepository
static func create(type: String, duration: float = 0.0) -> VNAnimationNode:
	match type:
		TransitionTypes.FADE:
			# Legacy fade - now uses StateChangeAnimation
			return StateChangeAnimation.new(duration if duration > 0.0 else 0.5)
		
		TransitionTypes.DISSOLVE:
			# Legacy dissolve - uses StateChangeAnimation with longer fade
			return StateChangeAnimation.new(duration if duration > 0.0 else 0.8, 0.4)
		
		TransitionTypes.INSTANT:
			return InstantAnimation.new()
		
		"transform":
			return TransformAnimation.new(duration)
		
		"state_change":
			return StateChangeAnimation.new(duration)
		
		_:
			push_warning("AnimationFactory: Unknown animation type '%s', defaulting to INSTANT" % type)
			return InstantAnimation.new()

