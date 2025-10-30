## StopInteractAction - Deactivates an interaction for a controller
## When executed, this action tells InteractionHandler to deactivate the named interaction
extends "res://rengo/controllers/actions/action_node.gd"
class_name StopInteractAction

## Controller reference (ActorController or other ResourceNode controller)
var controller = null

## Name of the interaction to deactivate
var interaction_name: String = ""

## Target layer (null = all layers, String = specific layer only)
var target_layer = null


func _init(p_controller, p_interaction_name: String) -> void:
	super._init(p_controller, 0.0)  # Instant action (duration = 0)
	controller = p_controller
	interaction_name = p_interaction_name


## Specifies which layer to deactivate the interaction on
## Enables chaining: actor_ctrl.stop_interact("poke").on("face")
func on(layer_name: String) -> StopInteractAction:
	target_layer = layer_name
	return self


## Executes the action - deactivates the interaction
func execute() -> void:
	super.execute()
	
	if not controller:
		push_error("StopInteractAction: controller is null")
		_is_complete = true
		return
	
	if interaction_name.is_empty():
		push_error("StopInteractAction: interaction_name is empty")
		_is_complete = true
		return
	
	# Deactivate the interaction via InteractionHandler (with layer)
	InteractionHandler.deactivate(controller, interaction_name, target_layer)
	
	_is_complete = true

