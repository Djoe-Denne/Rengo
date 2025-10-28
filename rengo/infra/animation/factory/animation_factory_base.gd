## Base class for animation factories
## Each factory is responsible for creating a specific type of animation
class_name AnimationFactoryBase
extends RefCounted

## Checks if this factory can create the given animation type
## @param anim_type: The animation type string (e.g., "transform", "state_change")
## @return: true if this factory can create this animation type
func can_create(anim_type: String) -> bool:
	push_error("AnimationFactoryBase.can_create() must be implemented by subclass")
	return false


## Creates an animation instance from a definition
## @param definition: Dictionary with type, duration, and parameters
## @return: VNAnimationNode instance or null
func create(definition: Dictionary) -> VNAnimationNode:
	push_error("AnimationFactoryBase.create() must be implemented by subclass")
	return null


## Helper to get duration from definition
func _get_duration(definition: Dictionary) -> float:
	return definition.get("duration", 0.0)


## Helper to get parameters from definition
func _get_parameters(definition: Dictionary) -> Dictionary:
	return definition.get("parameters", {})

