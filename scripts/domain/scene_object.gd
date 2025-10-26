## SceneObject Interface
## Provides auto-registration of ActionNodes to the scene controller
## Classes that implement this can automatically register actions without manual ctrl.action() calls
class_name SceneObject
extends RefCounted

## Reference to the parent VNScene (should be set by subclasses)
var vn_scene: Node = null


## Registers an ActionNode to the scene controller and returns it for chaining
## This allows: actor.show().with_fade(0.5) instead of ctrl.action(actor.show().with_fade(0.5))
func register_action(action_node) -> ActionNode:
	if not vn_scene:
		push_error("SceneObject.register_action: vn_scene is not set")
		return action_node
	
	if not vn_scene.controller:
		push_error("SceneObject.register_action: controller not found in vn_scene")
		return action_node
	
	# Register the action to the controller's queue
	vn_scene.controller.action(action_node)
	
	# Return the same ActionNode for optional chaining/fine-tuning
	return action_node

