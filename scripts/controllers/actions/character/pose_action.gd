## PoseAction - Changes a character's pose with optional animation
class_name PoseAction
extends AnimatedAction

var controller: ActorController
var pose_name: String


func _init(p_controller: ActorController, p_pose_name: String) -> void:
	super._init(p_controller)
	controller = p_controller
	pose_name = p_pose_name
	target_value = pose_name


## Get current pose from model via controller
func _get_current_value() -> Variant:
	if controller and controller.model:
		return controller.model.get_state("pose", "idle")
	return "idle"


## Apply pose to model via controller
func _apply_value(value: Variant) -> void:
	if controller:
		controller.update_model_state("pose", value)


## Create default animation for pose changes
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

