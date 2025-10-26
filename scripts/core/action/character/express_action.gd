## ExpressAction - Changes a character's expression
class_name ExpressAction
extends ActionNode

var actor: Actor
var emotion: String


func _init(p_actor: Actor, p_emotion: String) -> void:
	actor = p_actor
	emotion = p_emotion


## Executes the action - updates Character model
func execute() -> void:
	if actor and actor.character:
		actor.character.express(emotion)
	
	super.execute()
