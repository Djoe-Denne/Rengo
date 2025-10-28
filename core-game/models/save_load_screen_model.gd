## SaveLoadScreenModel - Model for save/load screen state
## Extends ScreenModel with save slot management
class_name SaveLoadScreenModel
extends ScreenModel

## Mode of the screen ("save" or "load")
var mode: String = "save"

## Array of save slot metadata dictionaries
## Each slot: { slot_number: int, is_empty: bool, timestamp: String, preview_data: Dictionary }
var save_slots: Array[Dictionary] = []

## Maximum number of save slots
var max_slots: int = 10

## Currently selected slot index
var selected_slot: int = 0


func _init(p_mode: String = "save") -> void:
	super._init("save_load")
	mode = p_mode
	_initialize_slots()


## Initializes empty save slots
func _initialize_slots() -> void:
	save_slots.clear()
	for i in range(max_slots):
		save_slots.append({
			"slot_number": i,
			"is_empty": true,
			"timestamp": "",
			"preview_data": {}
		})


## Refreshes save slot metadata from disk
func refresh_slots() -> void:
	var SaveSystem = load("res://core-game/domain/save_system.gd")
	var slots_data = SaveSystem.list_save_slots(max_slots)
	
	for i in range(max_slots):
		if i < slots_data.size():
			save_slots[i] = slots_data[i]
		else:
			save_slots[i] = {
				"slot_number": i,
				"is_empty": true,
				"timestamp": "",
				"preview_data": {}
			}
	
	_notify_observers()


## Sets the selected slot and notifies observers
func set_selected_slot(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < max_slots and selected_slot != slot_index:
		selected_slot = slot_index
		_notify_observers()


## Sets the mode (save or load) and notifies observers
func set_mode(p_mode: String) -> void:
	if (p_mode == "save" or p_mode == "load") and mode != p_mode:
		mode = p_mode
		_notify_observers()


## Gets the currently selected slot data
func get_selected_slot_data() -> Dictionary:
	if selected_slot >= 0 and selected_slot < save_slots.size():
		return save_slots[selected_slot]
	return {}


## Checks if the selected slot is empty
func is_selected_slot_empty() -> bool:
	var slot_data = get_selected_slot_data()
	return slot_data.get("is_empty", true)


## Override to include save/load screen specific state
func _get_state() -> Dictionary:
	var state = super._get_state()
	state["mode"] = mode
	state["save_slots"] = save_slots
	state["max_slots"] = max_slots
	state["selected_slot"] = selected_slot
	return state

