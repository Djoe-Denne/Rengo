## InteractAction - Activates an interaction for a controller
## When executed, this action tells InteractionHandler to activate the named interaction
extends "res://rengo/controllers/actions/action_node.gd"
class_name InteractAction

## Controller reference (ActorController or other ResourceNode controller)
var controller = null

## Name of the interaction to activate
var interaction_name: String = ""

## Target layer (null = root only, String = specific layer)
var target_layer = null


func _init(p_controller, p_interaction_name: String) -> void:
	super._init(p_controller, 0.0)  # Instant action (duration = 0)
	controller = p_controller
	interaction_name = p_interaction_name


## Specifies which layer to activate the interaction on
## Enables chaining: actor_ctrl.interact("poke").on("face")
func on(layer_name: String) -> InteractAction:
	target_layer = layer_name
	return self


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
	
	# Activate the interaction via InteractionHandler (with layer)
	InteractionHandler.activate(controller, interaction_name, target_layer)
	
	# Enable debug visualization for the target layer
	_enable_debug_visualization()
	
	_is_complete = true


## Enables debug visualization for the target layer (if specified)
func _enable_debug_visualization() -> void:
	# Only enable debug if a specific layer is targeted
	if target_layer == null or target_layer == "":
		return
	
	# Get the view from the controller
	var view = controller.view if controller else null
	if not view:
		return
	
	# Check if view has layers (DisplayableNode)
	if not view.has_method("get_layer"):
		return
	
	# Get the target layer
	var layer = view.get_layer(target_layer)
	if layer and layer.has_method("set_debug_enabled"):
		layer.set_debug_enabled(true)

