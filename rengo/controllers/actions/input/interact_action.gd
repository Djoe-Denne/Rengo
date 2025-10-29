## InteractAction - Activates an interaction for a controller
## When executed, this action tells InteractionHandler to activate the named interaction
extends "res://rengo/controllers/actions/action_node.gd"
class_name InteractAction

## Controller reference (ActorController or other ResourceNode controller)
var controller = null

## Name of the interaction to activate
var interaction_name: String = ""


func _init(p_controller, p_interaction_name: String) -> void:
	super._init(p_controller, 0.0)  # Instant action (duration = 0)
	controller = p_controller
	interaction_name = p_interaction_name


## Executes the action - activates the interaction
func execute() -> void:
	super.execute()
	
	if not controller:
		push_error("InteractAction: controller is null")
		_is_complete = true
		return
	
	if interaction_name.is_empty():
		push_error("InteractAction: interaction_name is empty")
		_is_complete = true
		return
	
	# Activate the interaction via InteractionHandler
	InteractionHandler.activate(controller, interaction_name)
	
	_is_complete = true

