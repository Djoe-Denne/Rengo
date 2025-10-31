## Act class - represents a character pose/action with multiple variants and layers
class_name Act
extends RefCounted

## The act configuration data loaded from YAML
var config: Dictionary = {}

## The character name this act belongs to
var name: String = ""

## The act name/ID (e.g., "idle", "wave", "talk")
var act_name: String = ""


func _init(p_name: String = "", p_act_name: String = "", p_config: Dictionary = {}) -> void:
	name = p_name
	act_name = p_act_name
	config = p_config


## Gets a variant for a specific orientation
func get_variant(orientation: String) -> Dictionary:
	if "variants" in config:
		if orientation in config.variants:
			return config.variants[orientation]
		# Try "default" as fallback
		if "default" in config.variants:
			return config.variants["default"]
		# Return first variant if orientation not found
		if config.variants.size() > 0:
			return config.variants.values()[0]
	return {}


## Gets all layer names for a specific orientation
func get_layer_names(orientation: String) -> Array:
	var variant = get_variant(orientation)
	if "layers" in variant:
		return variant.layers.keys()
	return []


## Gets layer data for a specific layer in an orientation
func get_layer_data(orientation: String, layer_name: String) -> Dictionary:
	var variant = get_variant(orientation)
	if "layers" in variant and layer_name in variant.layers:
		return variant.layers[layer_name]
	return {}


## Gets all available orientations/variants
func get_orientations() -> Array:
	if "variants" in config:
		return config.variants.keys()
	return []

