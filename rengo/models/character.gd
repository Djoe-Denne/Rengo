## Character class - Pure data model for character state
## Holds all character data independently of visual representation
## Notifies observers (Actors) when state changes
## Extends Transformable to include position, rotation, scale, visible properties
class_name Character extends Transformable

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

## Current visual states (pose, expression, orientation, etc.)
var current_states: Dictionary = {}

## Current outfit items
var panoplie: Array = []

## Game stats and RPG attributes (health, stats, inventory, etc.)
var stats: Dictionary = {}


func _init(p_name: String = "") -> void:
	super._init(Vector3.ZERO, false)  # Initialize Transformable
	name = p_name
	
	# Initialize default states
	current_states = {
		"pose": "idle",
		"orientation": "front",
		"expression": "neutral",
		"body": "default"
	}


## Sets a single state value and notifies observers
func set_state(key: String, value: Variant) -> void:
	if current_states.get(key) != value:
		current_states[key] = value
		_notify_observers()


## Gets a state value
func get_state(key: String, default_value: Variant = null) -> Variant:
	return current_states.get(key, default_value)


## Updates multiple states at once and notifies observers
func update_states(new_states: Dictionary) -> void:
	var changed = false
	for key in new_states:
		if current_states.get(key) != new_states[key]:
			current_states[key] = new_states[key]
			changed = true
	
	if changed:
		_notify_observers()


## Convenience method: Sets expression state
func express(emotion: String) -> void:
	set_state("expression", emotion)


## Convenience method: Sets pose state
func pose(pose_name: String) -> void:
	set_state("pose", pose_name)


## Convenience method: Sets orientation state
func look(orientation: String) -> void:
	set_state("orientation", orientation)


## Convenience method: Updates outfit state
func wear(outfit_items: Array) -> void:
	panoplie = outfit_items
	_notify_observers()


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
