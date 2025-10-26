## Costumier - Base class/interface for wardrobe management
## Manages character clothing and layering system
class_name Costumier extends RefCounted

## Character name this costumier manages
var character_name: String = ""

## Wardrobe configuration loaded from panoplie.yaml
var wardrobe: Array = []

func _init(p_character_name: String = "") -> void:
	character_name = p_character_name


## Selects a clothing item and returns updated panoplie
## Handles tag-based exclusions
func select(panoplie: Array, clothing_id: String) -> Array:
	push_error("Costumier.select() must be implemented by subclass")
	return []

## Returns clothing layers for the current panoplie
## Merges with act layers and resolves z-ordering
func get_layers(panoplie: Array, state: Dictionary) -> Dictionary:
	push_error("Costumier.get_layers_for_outfit() must be implemented by subclass")
	return {}


## Loads wardrobe from panoplie.yaml
func load_wardrobe(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("Panoplie file not found: %s" % path)
		return false
	
	# Parse YAML using the addon
	var result = YAML.load_file(path)
	
	if result.has_error():
		push_error("Failed to parse panoplie file: %s - Error: %s" % [path, result.get_error()])
		return false
	
	var data = result.get_data()
	if not data is Dictionary or not "wardrobe" in data:
		push_warning("Panoplie file does not contain 'wardrobe' key: %s" % path)
		return false
	
	wardrobe = data.wardrobe
	return true
