## PoseAction - Changes a character's pose
class_name PoseAction
extends ActionNode

var actor: Actor
var pose_name: String


func _init(p_actor: Actor, p_pose_name: String) -> void:
	actor = p_actor
	pose_name = p_pose_name


## Executes the action - updates Character model
func execute() -> void:
	if actor and actor.character:
		actor.character.pose(pose_name)
	
	super.execute()

