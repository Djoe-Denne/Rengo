## SaveData - Interface/base class for game-specific save data
## Game developers extend this class to define their save data structure
## 
## Example Usage:
##   class_name GameSaveData extends SaveData
##   
##   var player_name: String = ""
##   var level: int = 1
##   var inventory: Array = []
##   
##   func serialize() -> Dictionary:
##       return {
##           "player_name": player_name,
##           "level": level,
##           "inventory": inventory
##       }
##   
##   static func deserialize(data: Dictionary) -> SaveData:
##       var save = GameSaveData.new()
##       save.player_name = data.get("player_name", "")
##       save.level = data.get("level", 1)
##       save.inventory = data.get("inventory", [])
##       return save
##   
##   func get_preview_data() -> Dictionary:
##       return {
##           "player": player_name,
##           "level": level
##       }
class_name SaveData
extends RefCounted


## Serializes the save data to a dictionary
## Game developers MUST implement this method
func serialize() -> Dictionary:
	push_error("SaveData.serialize() must be implemented by subclass")
	return {}


## Deserializes a dictionary back into a SaveData instance
## Game developers MUST implement this static method
## Returns null if deserialization fails
static func deserialize(data: Dictionary) -> SaveData:
	push_error("SaveData.deserialize() must be implemented by subclass")
	return null


## Returns preview data for displaying in save slot UI
## Optional - game developers can override to provide custom preview info
## Returns a dictionary with display-friendly information
func get_preview_data() -> Dictionary:
	return {}

