## LookAction - Changes a character's orientation with optional animation
class_name LookAction
extends AnimatedAction

var actor: Actor
var orientation: String


func _init(p_actor: Actor, p_orientation: String) -> void:
	super._init(p_actor)
	actor = p_actor
	orientation = p_orientation
	target_value = orientation


## Get current orientation
func _get_current_value() -> Variant:
	if actor and actor.character:
		return actor.character.get_state("orientation", "front")
	return "front"


## Apply orientation to character
func _apply_value(value: Variant) -> void:
	if actor and actor.character:
		actor.character.look(value)


## Create default animation for orientation changes
func _create_default_animation() -> VNAnimationNode:
	var StateChangeAnimation = load("res://scripts/infra/animation/implementations/state_change_animation.gd")
	var anim = StateChangeAnimation.new(duration if duration > 0.0 else 0.3)
	
	# Set callback to change state at midpoint
	anim.with_state_change(func(): _apply_value(target_value))
	
	return anim


## Override execute to handle animation or instant change
func execute() -> void:
	if duration > 0.0:
		# Animated state change
		super.execute()
	else:
		# Instant state change
		_apply_value(target_value)
		_is_complete = true

