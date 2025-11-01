class_name DisplayableModel
extends Transformable

## States of the displayable model
var current_states: Dictionary = {}

func _init(p_states: Dictionary = {}) -> void:
	super._init(Vector3.ZERO, false)  # Initialize Transformable
	current_states = p_states


## Sets a single state value and notifies observers
func set_state(key: String, value: Variant) -> void:
	if current_states.get(key) != value:
		current_states[key] = value
		_notify_observers()


## Gets a state value
func get_state(key: String, default_value: Variant = null) -> Variant:
	return current_states.get(key, default_value)

## Gets all states
func get_states() -> Dictionary:
	return current_states

## Updates multiple states at once and notifies observers
func update_states(new_states: Dictionary) -> void:
	var changed = false
	for key in new_states:
		if current_states.get(key) != new_states[key]:
			current_states[key] = new_states[key]
			changed = true
	
	if changed:
		_notify_observers()

