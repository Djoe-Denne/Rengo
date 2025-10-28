## Animatable - Interface marker for entities that can be animated
## Provides common interface for animation system integration
## Can be extended later with animation state properties
class_name Animatable
extends RefCounted

## Animation state tracking (can be extended)
var is_animating: bool = false

## Current animation name (if any)
var current_animation: String = ""


func _init() -> void:
	pass


## Called when animation starts (override in subclasses if needed)
func on_animation_start(animation_name: String) -> void:
	is_animating = true
	current_animation = animation_name


## Called when animation ends (override in subclasses if needed)
func on_animation_end() -> void:
	is_animating = false
	current_animation = ""


## Check if entity is currently animating
func is_currently_animating() -> bool:
	return is_animating

