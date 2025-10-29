## InteractionBuilder - Fluent API for building InteractionDefinitions
## Provides convenient methods for configuring complete interactions
class_name InteractionBuilder
extends RefCounted

var _name: String = ""
var _inputs: Array = []


## Static constructor for the builder
static func builder() -> InteractionBuilder:
	return InteractionBuilder.new()


## Sets the interaction name
func name(interaction_name: String) -> InteractionBuilder:
	_name = interaction_name
	return self


## Adds an input definition to this interaction
func add(input: InputDefinition) -> InteractionBuilder:
	if input and input.is_valid():
		_inputs.append(input)
	else:
		push_warning("InteractionBuilder: Attempted to add invalid InputDefinition")
	return self


## Builds and returns the InteractionDefinition
func build() -> InteractionDefinition:
	var definition = InteractionDefinition.new(_name, _inputs)
	
	if not definition.is_valid():
		push_error("InteractionBuilder: Built invalid InteractionDefinition")
	
	return definition

