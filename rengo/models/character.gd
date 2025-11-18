## Character class - Pure data model for character state
## Holds all character data independently of visual representation
## Notifies observers (Actors) when state changes
## Extends Transformable to include position, rotation, scale, visible properties
class_name Character extends DisplayableModel

## Signals for character changes
signal pose_changed(new_pose: String)
signal expression_changed(new_expression: String)
signal orientation_changed(new_orientation: String)
signal outfit_changed(model: Character)

## Character identifier (e.g., "alice", "bob")
var name: String = ""

## Display name shown in dialogue
var display_name: String = ""

## Color for dialogue text
var dialog_color: Color = Color.WHITE

## Color for inner thoughts/monologue
var inner_dialog_color: Color = Color(1.0, 1.0, 1.0, 0.5)

## Full metadata dictionary (includes size_cm, etc.)
var metadata: Dictionary = {}

## Current outfit items
var panoplie: Array = []

## Game stats and RPG attributes (health, stats, inventory, etc.)
var stats: Dictionary = {}


func _init(p_name: String = "") -> void:
	super._init({
		"pose": "idle",
		"orientation": "front",
		"expression": "neutral",
		"body": "default"
	})
	name = p_name


## Convenience method: Sets expression state
func express(emotion: String) -> void:
	set_state("expression", emotion)
	expression_changed.emit(emotion)

## Convenience method: Sets pose state
func pose(pose_name: String) -> void:
	set_state("pose", pose_name)
	pose_changed.emit(pose_name)

## Convenience method: Sets orientation state
func look(orientation: String) -> void:
	set_state("orientation", orientation)
	orientation_changed.emit(orientation)

## Convenience method: Updates outfit state
func wear(outfit_items: Array) -> void:
	panoplie = outfit_items
	outfit_changed.emit(self)

## Override _get_transform_state to include character-specific state
func _get_transform_state() -> Dictionary:
	# Get base transform state from Transformable
	var state = super._get_transform_state()
	
	# Add character-specific state
	state["current_states"] = current_states
	state["panoplie"] = panoplie
	state["name"] = name
	
	return state


## Loads character metadata from YAML
func load_metadata(p_metadata: Dictionary) -> void:
	# Store full metadata for access to all properties (like size_cm)
	metadata = p_metadata
	
	if "display_name" in p_metadata:
		display_name = p_metadata.display_name
	
	if "dialog_color" in p_metadata:
		dialog_color = Color(p_metadata.dialog_color)
	
	if "inner_dialog_color" in p_metadata:
		inner_dialog_color = Color(p_metadata.inner_dialog_color)


## Applies default states from configuration
func apply_defaults(defaults: Dictionary) -> void:
	for key in defaults:
		if not key in current_states:
			current_states[key] = defaults[key]
	state_changed.emit(self)
