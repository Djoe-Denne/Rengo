## InteractionHandler - Singleton that manages active interactions and routes input events
## Autoload as "InteractionHandler"
extends Node

## Map of active interactions per controller
## Structure: { controller_instance: { interaction_name: InteractionDefinition } }
var _active_interactions: Dictionary = {}

## Map of registered interactions per controller (even if not active)
## Structure: { controller_instance: { interaction_name: InteractionDefinition } }
var _registered_interactions: Dictionary = {}

## Map tracking which resources are currently focused
## Structure: { controller_instance: bool }
var _focused_resources: Dictionary = {}


func _ready() -> void:
	# Set process mode to always active
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	# Process custom action inputs for all active interactions
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		_process_custom_inputs(event)


## Registers an interaction for a controller (doesn't activate it)
func register_interaction(controller, interaction: InteractionDefinition) -> void:
	if not controller:
		push_error("InteractionHandler: Cannot register interaction - controller is null")
		return
	
	if not interaction or not interaction.is_valid():
		push_error("InteractionHandler: Cannot register invalid interaction")
		return
	
	# Ensure controller has a dictionary
	if not controller in _registered_interactions:
		_registered_interactions[controller] = {}
	
	# Store the interaction
	_registered_interactions[controller][interaction.name] = interaction
	
	# Also ensure the controller has an active interactions dictionary (for later)
	if not controller in _active_interactions:
		_active_interactions[controller] = {}


## Activates a registered interaction
func activate(controller, interaction_name: String) -> void:
	if not controller:
		push_error("InteractionHandler: Cannot activate interaction - controller is null")
		return
	
	# Check if interaction is registered
	if not controller in _registered_interactions or not interaction_name in _registered_interactions[controller]:
		push_error("InteractionHandler: Interaction '%s' not registered for controller" % interaction_name)
		return
	
	# Get the interaction definition
	var interaction = _registered_interactions[controller][interaction_name]
	
	# Mark as active
	interaction.is_active = true
	
	# Add to active interactions
	if not controller in _active_interactions:
		_active_interactions[controller] = {}
	_active_interactions[controller][interaction_name] = interaction


## Deactivates an active interaction
func deactivate(controller, interaction_name: String) -> void:
	if not controller:
		push_error("InteractionHandler: Cannot deactivate interaction - controller is null")
		return
	
	# Check if controller has active interactions
	if not controller in _active_interactions:
		return
	
	# Check if interaction is active
	if not interaction_name in _active_interactions[controller]:
		return
	
	# Mark as inactive
	var interaction = _active_interactions[controller][interaction_name]
	interaction.is_active = false
	
	# Remove from active interactions
	_active_interactions[controller].erase(interaction_name)


## Called by Area3D/Area2D when mouse enters
func on_hover_enter(controller) -> void:
	if not controller:
		return
	
	# Mark as focused
	_focused_resources[controller] = true
	
	# Get all active interactions for this controller
	if not controller in _active_interactions:
		return
	
	for interaction_name in _active_interactions[controller]:
		var interaction = _active_interactions[controller][interaction_name]
		
		# Find all hover inputs
		var hover_inputs = interaction.get_inputs_by_type("hover")
		for input in hover_inputs:
			# Call in_callback
			if input.in_callback.is_valid():
				input.in_callback.call(controller)


## Called by Area3D/Area2D when mouse exits
func on_hover_exit(controller) -> void:
	if not controller:
		return
	
	# Mark as not focused
	_focused_resources[controller] = false
	
	# Get all active interactions for this controller
	if not controller in _active_interactions:
		return
	
	for interaction_name in _active_interactions[controller]:
		var interaction = _active_interactions[controller][interaction_name]
		
		# Find all hover inputs
		var hover_inputs = interaction.get_inputs_by_type("hover")
		for input in hover_inputs:
			# Call out_callback
			if input.out_callback.is_valid():
				input.out_callback.call(controller)


## Processes custom action inputs
func _process_custom_inputs(event: InputEvent) -> void:
	# Check all active interactions for matching actions
	for controller in _active_interactions:
		var interactions = _active_interactions[controller]
		
		for interaction_name in interactions:
			var interaction = interactions[interaction_name]
			
			# Get all custom inputs
			for input in interaction.inputs:
				if input.input_type != "custom":
					continue
				
				# Check if this event matches the action
				if not event.is_action(input.action_name):
					continue
				
				# Check focus requirement
				if input.requires_focus and not _is_focused(controller):
					continue
				
				# Handle pressed/released
				if event.is_action_pressed(input.action_name):
					# Call on_callback for just pressed
					if input.on_callback.is_valid():
						input.on_callback.call(controller)
					# Call in_callback for pressed
					elif input.in_callback.is_valid():
						input.in_callback.call(controller)
				
				elif event.is_action_released(input.action_name):
					# Call out_callback for released
					if input.out_callback.is_valid():
						input.out_callback.call(controller)


## Returns whether a controller's resource is currently focused
func _is_focused(controller) -> bool:
	return _focused_resources.get(controller, false)


## Cleans up references to a controller (call when controller is freed)
func unregister_controller(controller) -> void:
	_active_interactions.erase(controller)
	_registered_interactions.erase(controller)
	_focused_resources.erase(controller)
