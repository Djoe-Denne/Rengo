## InputBuilder - Fluent API for building InputDefinitions
## Provides convenient methods for configuring input handling
class_name InputBuilder
extends RefCounted

var _input_type: String = ""
var _action_name: String = ""
var _requires_focus: bool = false
var _in_callback: Callable = Callable()
var _out_callback: Callable = Callable()
var _on_callback: Callable = Callable()


## Creates a hover input definition (mouse enter/exit)
static func hover() -> InputBuilder:
	var builder = InputBuilder.new()
	builder._input_type = "hover"
	return builder


## Creates a custom action input definition
static func custom(action_name: String) -> InputBuilder:
	var builder = InputBuilder.new()
	builder._input_type = "custom"
	builder._action_name = action_name
	return builder


## Sets whether this input requires the resource to be focused
func on_focus(required: bool) -> InputBuilder:
	_requires_focus = required
	return self


## Sets the "in" callback (hover enter, action pressed)
func in_callback(callback: Callable) -> InputBuilder:
	_in_callback = callback
	return self


## Sets the "out" callback (hover exit, action released)
func out_callback(callback: Callable) -> InputBuilder:
	_out_callback = callback
	return self


## Sets the single-fire callback (for immediate events)
func callback(callback: Callable) -> InputBuilder:
	_on_callback = callback
	return self


## Builds and returns the InputDefinition
func build() -> InputDefinition:
	return InputDefinition.new(
		_input_type,
		_action_name,
		_requires_focus,
		_in_callback,
		_out_callback,
		_on_callback
	)

