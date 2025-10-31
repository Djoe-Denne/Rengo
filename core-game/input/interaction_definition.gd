## InteractionDefinition - Data class representing a complete interaction
## Contains multiple input configurations and activation state
class_name InteractionDefinition
extends RefCounted

## Unique name for this interaction (e.g., "poke", "examine")
var name: String = ""

## Array of InputDefinition objects
var inputs: Array = []

## Whether this interaction is currently active
var is_active: bool = false

## Whether this interaction is currently active on the root layer
var is_root_active: bool = true

## Dictionary tracking which layers this interaction is active on
## { layer_name: bool } where layer_name can be null for root
## null key means root (merged collision area)
var active_layers: Dictionary = {}


func _init(p_name: String = "", p_inputs: Array = []) -> void:
	name = p_name
	inputs = p_inputs


## Returns true if this interaction definition is valid
func is_valid() -> bool:
	if name.is_empty():
		return false
	
	if inputs.is_empty():
		return false
	
	# Check that all inputs are valid
	for input in inputs:
		if not (input is InputDefinition) or not input.is_valid():
			return false
	
	return true


## Gets all inputs of a specific type
func get_inputs_by_type(input_type: String) -> Array:
	var result = []
	for input in inputs:
		if input.input_type == input_type:
			result.append(input)
	return result


## Gets input by action name (for custom inputs)
func get_input_by_action(action_name: String) -> InputDefinition:
	for input in inputs:
		if input.input_type == "custom" and input.action_name == action_name:
			return input
	return null


## ============================================================================
## LAYER ACTIVATION METHODS
## ============================================================================

## Returns true if this interaction is active on the specified layer
## layer_name: String or null (null = root)
func is_active_on_layer(layer_name) -> bool:
	return active_layers.get(layer_name, false)


## Activates this interaction for a specific layer
## layer_name: String or null (null = root only)
func activate_on_layer(layer_name) -> void:
	active_layers[layer_name] = true
	is_active = true  # Mark as active if any layer is active


## Deactivates this interaction for a specific layer
## layer_name: String or null (null = root)
func deactivate_on_layer(layer_name) -> void:
	active_layers.erase(layer_name)
	
	# If no layers are active, mark as inactive
	if active_layers.is_empty():
		is_active = false
		is_root_active = false

## Deactivates this interaction for all layers
func deactivate_all_layers() -> void:
	active_layers.clear()
	is_active = false
	is_root_active = false


## Gets all active layers for this interaction
func get_active_layers() -> Array:
	return active_layers.keys()

func is_root_active_on() -> bool:
	return is_root_active

func set_root_active_on(value: bool) -> void:
	is_root_active = value