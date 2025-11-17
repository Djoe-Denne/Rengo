## Base class for all visual novel scene resources
## ResourceNodes represent VIEW objects in the scene (characters, backgrounds, etc.)
## State properties (position, visible, etc.) now live in MODEL classes
## This class provides view coordination and scene node management
class_name ResourceNode
extends SceneObject

## Dictionary of registered interactions
var registered_interactions: Dictionary = {}



## Creates and auto-registers a ShowAction to make this resource visible
## Returns the ActionNode for optional chaining
func show():
	var ShowAction = load("res://rengo/controllers/actions/common/show_action.gd")
	var action = ShowAction.new(self)
	return register_action(action)


## Creates and auto-registers a HideAction to make this resource invisible
## Returns the ActionNode for optional chaining
func hide():
	var HideAction = load("res://rengo/controllers/actions/common/hide_action.gd")
	var action = HideAction.new(self)
	return register_action(action)

## Updates the visual position in 3D space
## Subclasses should override this to read from their model
func update_position() -> void:
	push_warning("ResourceNode.update_position should be overridden by subclass")


## Updates the visibility of the scene node
## Subclasses should override this to read from their model
func update_visibility() -> void:
	push_warning("ResourceNode.update_visibility should be overridden by subclass")


## Registers an interaction for this resource
## The interaction will be stored but not activated
func register_interaction(interaction) -> void:  # InteractionDefinition
	if not interaction:
		push_error("ResourceNode.register_interaction: interaction is null")
		return
	
	# Store the interaction
	registered_interactions[interaction.name] = interaction

