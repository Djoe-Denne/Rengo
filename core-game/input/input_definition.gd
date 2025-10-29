## InputDefinition - Data class representing a single input configuration
## Defines how an interaction responds to a specific input type
class_name InputDefinition
extends RefCounted

## Type of input: "hover", "custom"
var input_type: String = ""

## For custom inputs: the Godot action name (e.g., "ui_accept", "ok_confirm")
var action_name: String = ""

## Whether this input requires the resource to be focused
var requires_focus: bool = false

## Callback for "in" events (hover enter, action pressed)
var in_callback: Callable = Callable()

## Callback for "out" events (hover exit, action released)
var out_callback: Callable = Callable()

## Callback for single-fire events (click, action just pressed)
var on_callback: Callable = Callable()


func _init(
	p_input_type: String = "",
	p_action_name: String = "",
	p_requires_focus: bool = false,
	p_in_callback: Callable = Callable(),
	p_out_callback: Callable = Callable(),
	p_on_callback: Callable = Callable()
) -> void:
	input_type = p_input_type
	action_name = p_action_name
	requires_focus = p_requires_focus
	in_callback = p_in_callback
	out_callback = p_out_callback
	on_callback = p_on_callback


## Returns true if this input definition is valid
func is_valid() -> bool:
	if input_type.is_empty():
		return false
	
	if input_type == "custom" and action_name.is_empty():
		return false
	
	# At least one callback should be set
	return in_callback.is_valid() or out_callback.is_valid() or on_callback.is_valid()

