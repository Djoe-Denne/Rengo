## SaveSystem - Static utility class for save/load functionality
## Handles file I/O, serialization, and save slot management
## Uses JSON for serialization and stores saves in user://saves/
class_name SaveSystem
extends RefCounted

## Directory where save files are stored
const SAVE_DIR = "user://saves/"

## File extension for save files
const SAVE_EXTENSION = ".json"


## Saves game data to the specified slot
## Returns OK on success, or an Error code on failure
static func save_game(slot: int, save_data: SaveData) -> Error:
	if save_data == null:
		push_error("SaveSystem: Cannot save null SaveData")
		return ERR_INVALID_PARAMETER
	
	# Ensure save directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	
	# Serialize the save data
	var data_dict = save_data.serialize()
	
	# Add metadata
	var save_container = {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"slot": slot,
		"preview_data": save_data.get_preview_data(),
		"data": data_dict,
		"data_class": save_data.get_script().get_global_name()
	}
	
	# Convert to JSON
	var json_string = JSON.stringify(save_container, "\t")
	
	# Write to file
	var file_path = _get_save_path(slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		push_error("SaveSystem: Failed to open file for writing: %s" % file_path)
		return FileAccess.get_open_error()
	
	file.store_string(json_string)
	file.close()
	
	return OK


## Loads game data from the specified slot
## Returns a SaveData instance on success, or null on failure
static func load_game(slot: int, save_data_class: GDScript) -> SaveData:
	var file_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(file_path):
		push_warning("SaveSystem: Save file does not exist: %s" % file_path)
		return null
	
	# Read file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: Failed to open file for reading: %s" % file_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("SaveSystem: Failed to parse JSON from file: %s" % file_path)
		return null
	
	var save_container = json.data
	
	if not save_container is Dictionary:
		push_error("SaveSystem: Invalid save file format: %s" % file_path)
		return null
	
	# Extract data
	var data_dict = save_container.get("data", {})
	
	# Deserialize using the provided class
	var save_data = save_data_class.deserialize(data_dict)
	
	return save_data


## Gets metadata for a specific save slot without loading the full save
## Returns a dictionary with slot info, or an empty slot dictionary if file doesn't exist
static func get_slot_metadata(slot: int) -> Dictionary:
	var file_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(file_path):
		return {
			"slot_number": slot,
			"is_empty": true,
			"timestamp": "",
			"preview_data": {}
		}
	
	# Read file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {
			"slot_number": slot,
			"is_empty": true,
			"timestamp": "",
			"preview_data": {}
		}
	
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {
			"slot_number": slot,
			"is_empty": true,
			"timestamp": "",
			"preview_data": {}
		}
	
	var save_container = json.data
	
	return {
		"slot_number": slot,
		"is_empty": false,
		"timestamp": save_container.get("timestamp", ""),
		"preview_data": save_container.get("preview_data", {}),
		"version": save_container.get("version", 1)
	}


## Lists all save slots with their metadata
## Returns an array of slot metadata dictionaries
static func list_save_slots(max_slots: int = 10) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	
	for i in range(max_slots):
		slots.append(get_slot_metadata(i))
	
	return slots


## Deletes a save file from the specified slot
## Returns OK on success, or an Error code on failure
static func delete_save(slot: int) -> Error:
	var file_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(file_path):
		return OK  # Already deleted
	
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		return ERR_CANT_OPEN
	
	var err = dir.remove(file_path)
	return err


## Checks if a save exists in the specified slot
static func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))


## Checks if any save file exists (for "Continue" button availability)
static func has_any_save() -> bool:
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		return false
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(SAVE_EXTENSION):
			dir.list_dir_end()
			return true
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return false


## Gets the most recent save slot number
## Returns -1 if no saves exist
static func get_most_recent_save_slot(max_slots: int = 10) -> int:
	var most_recent_slot = -1
	var most_recent_time = ""
	
	for i in range(max_slots):
		var metadata = get_slot_metadata(i)
		if not metadata.is_empty and metadata.timestamp > most_recent_time:
			most_recent_time = metadata.timestamp
			most_recent_slot = i
	
	return most_recent_slot


## Gets the file path for a save slot
static func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION

