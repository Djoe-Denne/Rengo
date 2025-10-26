## ExpressAction - Changes a character's expression with optional animation
class_name ExpressAction
extends AnimatedAction

var actor: Actor
var emotion: String


func _init(p_actor: Actor, p_emotion: String) -> void:
	super._init(p_actor)
	actor = p_actor
	emotion = p_emotion
	target_value = emotion


## Get current expression
func _get_current_value() -> Variant:
	if actor and actor.character:
		return actor.character.get_state("expression", "neutral")
	return "neutral"


## Apply expression to character
func _apply_value(value: Variant) -> void:
	if actor and actor.character:
		actor.character.express(value)


## Create default animation for expression changes
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
