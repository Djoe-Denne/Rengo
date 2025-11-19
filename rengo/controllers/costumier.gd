## Costumier - Base class/interface for wardrobe management
## Manages character clothing and layering system
class_name Costumier extends RefCounted

## Wardrobe configuration loaded from panoplie.yaml
var wardrobe: Array = []


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


## Loads wardrobe from panoplie.yaml with optional scene-specific merging
## @param base_dirs: List of base directories to search (scene-specific first, then common)
## @param merge_scene: If true, merges panoplie.yaml from common with panoplie-scene.yaml from scene folder
func load_wardrobe(base_dirs: Array, merge_scene: bool = true) -> bool:
	if base_dirs.is_empty():
		push_warning("No base directories provided for loading wardrobe")
		return false
	
	# Use ResourceRepository to load and merge YAML files
	var data = ResourceRepository.load_yaml(base_dirs, "panoplie", merge_scene)
	
	if data.is_empty():
		push_warning("Failed to load panoplie from directories: %s" % str(base_dirs))
		return false
	
	if not "wardrobe" in data:
		push_warning("Panoplie file does not contain 'wardrobe' key in directories: %s" % str(base_dirs))
		return false
	
	wardrobe = data.wardrobe
	return true
