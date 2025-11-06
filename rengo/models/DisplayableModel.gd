class_name DisplayableModel
extends Transformable

## The controller (pure display)
var controller: Controller = null

## signals for model changes
signal state_changed(model: DisplayableModel)
## States of the displayable model
var current_states: Dictionary = {}


## Annotations for the displayable model { annotation_name: Annotation }
var annotations: Dictionary = {}


func _init(p_states: Dictionary = {}) -> void:
	super._init(Vector3.ZERO, false)  # Initialize Transformable
	current_states = p_states


## Sets a single state value and notifies observers
func set_state(key: String, value: Variant) -> void:
	if current_states.get(key) != value:
		current_states[key] = value
		state_changed.emit(self)

func remove_state(key: String) -> void:
	if current_states.has(key):
		current_states.erase(key)
		state_changed.emit(self)

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
		state_changed.emit(self)


func add_layer_state(p_layer_name: String, p_state: String) -> void:
	var annotation_name = "layer_" + p_layer_name
	if not annotation_name in annotations:
		annotations[annotation_name] = Annotation.new(annotation_name)
	annotations[annotation_name].add_note(p_state)
	state_changed.emit(self)

func remove_layer_state(p_layer_name: String, p_state: String) -> void:
	var annotation_name = "layer_" + p_layer_name
	if not annotation_name in annotations:
		return
	annotations[annotation_name].remove_note(p_state)
	state_changed.emit(self)

func on_plan_changed(p_plan_id: String) -> void: state_changed.emit(self)

func get_controller() -> Controller:
	return controller

func set_controller(p_controller: Controller) -> void:
	controller = p_controller
