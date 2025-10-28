## SaveLoadScreenView - Complete view implementation for save/load screen
## Extends BaseScreenView and handles all save/load screen logic
## Game developers only need to create .tscn with UI layout
class_name SaveLoadScreenView
extends BaseScreenView

## Exported node paths for UI elements (set in editor)
@export var mode_label_path: NodePath = ^"VBoxContainer/ModeLabel"
@export var slots_container_path: NodePath = ^"VBoxContainer/SlotsContainer"
@export var confirm_button_path: NodePath = ^"VBoxContainer/ButtonsContainer/ConfirmButton"
@export var delete_button_path: NodePath = ^"VBoxContainer/ButtonsContainer/DeleteButton"
@export var back_button_path: NodePath = ^"VBoxContainer/ButtonsContainer/BackButton"
@export var slot_button_scene: PackedScene  # Optional: custom slot button scene

## UI element references
var mode_label: Label
var slots_container: Container
var confirm_button: Button
var delete_button: Button
var back_button: Button

## Store slot buttons for easy access
var slot_buttons: Array[Button] = []

## SaveData class reference (set by game code)
var save_data_class: GDScript = null

## Callback when save/load completes
var on_complete: Callable = func(): pass


func _ready() -> void:
	# Create model and controller
	var save_load_model = SaveLoadScreenModel.new("load")  # Default to load mode
	var save_load_controller = SaveLoadScreenController.new(save_load_model)
	
	# Get UI nodes FIRST (before setup, so initial model state can update them)
	_setup_ui_nodes()
	
	# Create slot buttons
	_create_slot_buttons()
	
	# Setup with BaseScreenView (triggers initial _on_model_changed with model's loaded values)
	setup(save_load_model, save_load_controller)
	
	# Find and set screen_manager reference on controller
	_find_and_set_screen_manager()
	
	# Set save data class in controller
	save_load_controller.save_data_class = save_data_class
	
	# Wire up controller callbacks
	_setup_controller_callbacks(save_load_controller)
	
	# Connect UI signals
	_connect_ui_elements(save_load_controller)


## Gets UI node references from the scene tree
func _setup_ui_nodes() -> void:
	if has_node(mode_label_path):
		mode_label = get_node(mode_label_path)
	
	if has_node(slots_container_path):
		slots_container = get_node(slots_container_path)
	
	if has_node(confirm_button_path):
		confirm_button = get_node(confirm_button_path)
	
	if has_node(delete_button_path):
		delete_button = get_node(delete_button_path)
	
	if has_node(back_button_path):
		back_button = get_node(back_button_path)


## Creates UI buttons for each save slot
func _create_slot_buttons() -> void:
	if not slots_container:
		return
	
	var save_load_model = model as SaveLoadScreenModel
	if not save_load_model:
		return
	
	for i in range(save_load_model.max_slots):
		var button: Button
		
		if slot_button_scene:
			button = slot_button_scene.instantiate()
		else:
			button = Button.new()
			button.custom_minimum_size = Vector2(400, 60)
		
		button.pressed.connect(func(): _on_slot_selected(i))
		slots_container.add_child(button)
		slot_buttons.append(button)


## Sets up controller callbacks
func _setup_controller_callbacks(save_load_controller: SaveLoadScreenController) -> void:
	# Complete callback
	save_load_controller.on_complete = func():
		if on_complete.is_valid():
			on_complete.call()
	
	# Cancel callback
	save_load_controller.on_cancel = func():
		if controller.screen_manager:
			controller.screen_manager.pop_screen("fade")


## Connects UI element signals to controller methods
func _connect_ui_elements(save_load_controller: SaveLoadScreenController) -> void:
	if confirm_button:
		confirm_button.pressed.connect(func(): _on_confirm_pressed(save_load_controller))
	
	if delete_button:
		delete_button.pressed.connect(save_load_controller.delete_selected_slot)
	
	if back_button:
		back_button.pressed.connect(save_load_controller.cancel)


## Called when the model changes
func _on_model_changed(state: Dictionary) -> void:
	# Update mode label
	if mode_label:
		var mode = state.get("mode", "save")
		mode_label.text = mode.capitalize() + " Game"
	
	# Update slot buttons
	var save_slots = state.get("save_slots", [])
	var selected_slot = state.get("selected_slot", 0)
	
	for i in range(slot_buttons.size()):
		if i < save_slots.size():
			_update_slot_button(slot_buttons[i], save_slots[i], i == selected_slot)
	
	# Update confirm button text
	if confirm_button:
		var mode = state.get("mode", "save")
		confirm_button.text = mode.capitalize()
	
	# Update delete button visibility
	if delete_button:
		var is_empty = save_slots[selected_slot].get("is_empty", true) if selected_slot < save_slots.size() else true
		delete_button.visible = not is_empty


## Updates a single slot button's appearance
func _update_slot_button(button: Button, slot_data: Dictionary, is_selected: bool) -> void:
	var slot_num = slot_data.get("slot_number", 0)
	var is_empty = slot_data.get("is_empty", true)
	
	if is_empty:
		button.text = "Slot %d: Empty" % (slot_num + 1)
	else:
		var timestamp = slot_data.get("timestamp", "")
		var preview = slot_data.get("preview_data", {})
		
		# Format preview data (customize based on your game's SaveData)
		var preview_text = _format_preview_data(preview)
		
		button.text = "Slot %d: %s\n%s" % [
			slot_num + 1,
			preview_text,
			timestamp
		]
	
	# Visual feedback for selection
	if is_selected:
		button.grab_focus()


## Formats preview data for display (override in game-specific code if needed)
func _format_preview_data(preview: Dictionary) -> String:
	# Default formatting - game devs can customize
	if preview.is_empty():
		return "No data"
	
	# Try common preview fields
	var parts: Array[String] = []
	
	if "player" in preview:
		parts.append(str(preview.player))
	
	if "level" in preview:
		parts.append("Lvl " + str(preview.level))
	
	if "playtime" in preview:
		parts.append(str(preview.playtime))
	
	if parts.is_empty():
		return "Saved game"
	
	return " - ".join(parts)


## Called when a slot is selected
func _on_slot_selected(slot_index: int) -> void:
	var save_load_controller = controller as SaveLoadScreenController
	if save_load_controller:
		save_load_controller.select_slot(slot_index)


## Called when confirm button is pressed
func _on_confirm_pressed(save_load_controller: SaveLoadScreenController) -> void:
	var save_load_model = model as SaveLoadScreenModel
	if not save_load_model:
		return
	
	if save_load_model.mode == "save":
		# Need to get save data from game - emit signal or call callback
		_request_save_data(save_load_controller)
	else:  # load
		var loaded_data = save_load_controller.load_from_selected_slot()
		if loaded_data:
			# Notify that data was loaded
			_on_data_loaded(loaded_data)


## Virtual method - override to provide save data
func _request_save_data(save_load_controller: SaveLoadScreenController) -> void:
	push_warning("SaveLoadScreenView: _request_save_data not implemented - cannot save")
	# Game-specific code should override this or set a callback


## Virtual method - override to handle loaded data
func _on_data_loaded(save_data: SaveData) -> void:
	print("Data loaded: ", save_data.serialize())
	# Game-specific code should override this or set a callback


## Finds ScreenManager in parent tree and sets it on controller
func _find_and_set_screen_manager() -> void:
	var current = get_parent()
	while current:
		if current is ScreenManager:
			if controller:
				controller.set_screen_manager(current)
			return
		current = current.get_parent()


## Handles keyboard navigation
func _input(event: InputEvent) -> void:
	if not model or not model.is_active:
		return
	
	var save_load_controller = controller as SaveLoadScreenController
	if not save_load_controller:
		return
	
	if event.is_action_pressed("ui_up"):
		save_load_controller.select_previous_slot()
		accept_event()
	elif event.is_action_pressed("ui_down"):
		save_load_controller.select_next_slot()
		accept_event()

