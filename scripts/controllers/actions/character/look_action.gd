## LookAction - Changes a character's orientation
class_name LookAction
extends ActionNode

var actor: Actor
var orientation: String


func _init(p_actor: Actor, p_orientation: String) -> void:
	actor = p_actor
	orientation = p_orientation


## Executes the action - updates Character model
func execute() -> void:
	if actor and actor.character:
		actor.character.look(orientation)
	
	super.execute()

