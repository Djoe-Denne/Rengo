## SceneObject Interface
## Provides auto-registration of ActionNodes to the scene controller
## Classes that implement this can automatically register actions without manual ctrl.action() calls
class_name SceneObject
extends Node3D


## Registers an ActionNode to the scene controller and returns it for chaining
## This allows: actor.show().with_fade(0.5) instead of ctrl.action(actor.show().with_fade(0.5))
func register_action(action_node) -> ActionNode:	
	# Register the action to the controller's queue
	VNScene.get_instance().controller.action(action_node)
	
	# Return the same ActionNode for optional chaining/fine-tuning
	return action_node
