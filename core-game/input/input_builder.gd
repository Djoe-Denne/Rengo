## InputBuilder - Fluent API for building InputDefinitions
## Provides convenient methods for configuring input handling
##
## CALLBACK SIGNATURE: All callbacks receive (controller, layer_name) parameters
##   - controller: The ActorController or ResourceNode controller
##   - layer_name: String for specific layer, null for root (merged) collision area
##
## Example:
##   InputBuilder.hover()
##     .in_callback(func(ctrl, layer):
##       print("Hovering ", layer if layer else "root")
##       ctrl.model.set_state("status", "focused"))
##     .out_callback(func(ctrl, layer):
##       ctrl.model.set_state("status", ""))
##     .build()
class_name InputBuilder
extends RefCounted

var _input_type: String = ""
var _action_name: String = ""
var _requires_focus: bool = false
var _in_callback: Callable = Callable()
var _out_callback: Callable = Callable()
var _on_callback: Callable = Callable()


## Creates a hover input definition (mouse enter/exit)
## Callbacks receive (controller, layer_name) where layer_name can be null for root
static func hover() -> InputBuilder:
	var builder = InputBuilder.new()
	builder._input_type = "hover"
	return builder


## Creates a custom action input definition
## Callbacks receive (controller, layer_name) where layer_name can be null for root
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
## Callback signature: func(controller, layer_name)
func in_callback(callback: Callable) -> InputBuilder:
	_in_callback = callback
	return self


## Sets the "out" callback (hover exit, action released)
## Callback signature: func(controller, layer_name)
func out_callback(callback: Callable) -> InputBuilder:
	_out_callback = callback
	return self


## Sets the single-fire callback (for immediate events)
## Callback signature: func(controller, layer_name)
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

