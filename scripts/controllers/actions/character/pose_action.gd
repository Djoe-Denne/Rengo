## PoseAction - Changes a character's pose with optional animation
class_name PoseAction
extends AnimatedAction

var actor: Actor
var pose_name: String


func _init(p_actor: Actor, p_pose_name: String) -> void:
	super._init(p_actor)
	actor = p_actor
	pose_name = p_pose_name
	target_value = pose_name


## Get current pose
func _get_current_value() -> Variant:
	if actor and actor.character:
		return actor.character.get_state("pose", "idle")
	return "idle"


## Apply pose to character
func _apply_value(value: Variant) -> void:
	if actor and actor.character:
		actor.character.pose(value)


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

