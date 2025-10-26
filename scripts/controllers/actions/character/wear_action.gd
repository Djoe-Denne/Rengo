## WearAction - Changes a character's outfit using Costumier system
class_name WearAction
extends ActionNode

var actor: Actor
var clothing_id: String


func _init(p_actor: Actor, p_clothing_id: String) -> void:
	actor = p_actor
	clothing_id = p_clothing_id


## Executes the action - updates Character model using Costumier
func execute() -> void:
	# Get the Costumier for this character
	var costumier = actor.director.get_costumier(actor.actor_name)
	
	if costumier:
		# Use Costumier.select() to handle exclusions properly
		var new_panoplie = costumier.select(actor.character.panoplie, clothing_id)
		# Update character with new outfit (includes exclusions)
		actor.character.wear(new_panoplie)
	
	super.execute()
