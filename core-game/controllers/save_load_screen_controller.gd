## SaveLoadScreenController - Controller for save/load screen
## Provides public API for save/load operations
class_name SaveLoadScreenController
extends ScreenController

## Callback when save/load is complete
var on_complete: Callable = func(): pass

## Callback when cancelled/back is pressed
var on_cancel: Callable = func(): pass

## The SaveData class to use for deserialization (game-specific)
var save_data_class: GDScript = null


func _init(p_model: SaveLoadScreenModel = null) -> void:
	if p_model == null:
		p_model = SaveLoadScreenModel.new()
	super._init(p_model)


## Gets the save/load screen model (typed accessor)
func get_save_load_model() -> SaveLoadScreenModel:
	return model as SaveLoadScreenModel


## Called when entering the screen
func on_enter() -> void:
	super.on_enter()
	
	# Refresh save slots from disk
	get_save_load_model().refresh_slots()


## Sets the mode (save or load)
func set_mode(mode: String) -> void:
	get_save_load_model().set_mode(mode)


## Selects a save slot by index
func select_slot(slot_index: int) -> void:
	get_save_load_model().set_selected_slot(slot_index)


## Moves selection up
func select_previous_slot() -> void:
	var save_load_model = get_save_load_model()
	var new_index = save_load_model.selected_slot - 1
	if new_index < 0:
		new_index = 0
	select_slot(new_index)


## Moves selection down
func select_next_slot() -> void:
	var save_load_model = get_save_load_model()
	var new_index = save_load_model.selected_slot + 1
	if new_index >= save_load_model.max_slots:
		new_index = save_load_model.max_slots - 1
	select_slot(new_index)


## Saves game data to the selected slot
func save_to_selected_slot(save_data: SaveData) -> Error:
	var save_load_model = get_save_load_model()
	
	if save_load_model.mode != "save":
		push_error("SaveLoadScreenController: Cannot save in load mode")
		return ERR_INVALID_PARAMETER
	
	if save_data == null:
		push_error("SaveLoadScreenController: Cannot save null data")
		return ERR_INVALID_PARAMETER
	
	var SaveSystem = load("res://core-game/domain/save_system.gd")
	var err = SaveSystem.save_game(save_load_model.selected_slot, save_data)
	
	if err == OK:
		# Refresh slots to show updated data
		save_load_model.refresh_slots()
		
		if on_complete.is_valid():
			on_complete.call()
	
	return err


## Loads game data from the selected slot
func load_from_selected_slot() -> SaveData:
	var save_load_model = get_save_load_model()
	
	if save_load_model.mode != "load":
		push_error("SaveLoadScreenController: Cannot load in save mode")
		return null
	
	if save_data_class == null:
		push_error("SaveLoadScreenController: save_data_class not set. Must provide SaveData class for deserialization")
		return null
	
	if save_load_model.is_selected_slot_empty():
		push_warning("SaveLoadScreenController: Selected slot is empty")
		return null
	
	var SaveSystem = load("res://core-game/domain/save_system.gd")
	var save_data = SaveSystem.load_game(save_load_model.selected_slot, save_data_class)
	
	if save_data != null:
		if on_complete.is_valid():
			on_complete.call()
	
	return save_data


## Deletes the selected save slot
func delete_selected_slot() -> Error:
	var save_load_model = get_save_load_model()
	
	if save_load_model.is_selected_slot_empty():
		return OK  # Already empty
	
	var SaveSystem = load("res://core-game/domain/save_system.gd")
	var err = SaveSystem.delete_save(save_load_model.selected_slot)
	
	if err == OK:
		# Refresh slots to show updated data
		save_load_model.refresh_slots()
	
	return err


## Confirms the selection (save or load based on mode)
func confirm_selection(save_data: SaveData = null) -> Variant:
	var save_load_model = get_save_load_model()
	
	if save_load_model.mode == "save":
		if save_data == null:
			push_error("SaveLoadScreenController: save_data required for save mode")
			return ERR_INVALID_PARAMETER
		return save_to_selected_slot(save_data)
	else:  # load mode
		return load_from_selected_slot()


## Cancels and goes back
func cancel() -> void:
	if on_cancel.is_valid():
		on_cancel.call()
	elif screen_manager:
		screen_manager.pop_screen()


## Refreshes the save slot list
func refresh_slots() -> void:
	get_save_load_model().refresh_slots()

