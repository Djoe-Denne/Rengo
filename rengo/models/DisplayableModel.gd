class_name DisplayableModel
extends Transformable

## The controller (pure display)
var controller: Controller = null

## signals for model changes
signal state_changed(new_states: Dictionary)
## States of the displayable model
var current_states: Dictionary = {}

func _init(p_states: Dictionary = {}) -> void:
	super._init(Vector3.ZERO, false)  # Initialize Transformable
	current_states = p_states


## Sets a single state value and notifies observers
func set_state(key: String, value: Variant) -> void:
	if current_states.get(key) != value:
		current_states[key] = value
		state_changed.emit(current_states)

func remove_state(key: String) -> void:
	if current_states.has(key):
		current_states.erase(key)
		state_changed.emit(current_states)

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
		state_changed.emit(new_states)

func on_plan_changed() -> void: state_changed.emit(current_states)

func get_controller() -> Controller:
	return controller

func set_controller(p_controller: Controller) -> void:
	controller = p_controller
