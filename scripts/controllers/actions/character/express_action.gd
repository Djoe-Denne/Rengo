## ExpressAction - Changes a character's expression with optional animation
class_name ExpressAction
extends AnimatedAction

var controller: ActorController
var emotion: String


func _init(p_controller: ActorController, p_emotion: String) -> void:
	super._init(p_controller)
	controller = p_controller
	emotion = p_emotion
	target_value = emotion


## Get current expression from model via controller
func _get_current_value() -> Variant:
	if controller and controller.model:
		return controller.model.get_state("expression", "neutral")
	return "neutral"


## Apply expression to model via controller
func _apply_value(value: Variant) -> void:
	if controller:
		controller.update_model_state("expression", value)


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
