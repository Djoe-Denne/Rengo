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

