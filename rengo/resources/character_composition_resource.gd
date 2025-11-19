@tool
## CharacterCompositionResource - Visual character composition template
## Replaces character.yaml, faces.yaml, and panoplie.yaml with a unified resource
## Allows visual editing of character layers in the Godot editor
class_name CharacterCompositionResource
extends Resource

## Character identifier (e.g., "alice", "bob")
@export var character_name: String = ""

## Display name shown in dialogue
@export var display_name: String = ""

## Color for dialogue text
@export var dialog_color: Color = Color.WHITE

## Color for inner thoughts/monologue
@export var inner_dialog_color: Color = Color(1.0, 1.0, 1.0, 0.5)

## Base size in centimeters (width, height)
## Replaces size_cm from character.yaml
@export var base_size: Vector2 = Vector2(80, 170)

## Default states for the character (orientation, pose, expression, outfit, body)
@export var default_states: Dictionary = {
	"orientation": "front",
	"pose": "idle",
	"expression": "neutral",
	"outfit": "default",
	"body": "default"
}

## All layers that make up this character (body, face, clothing, etc.)
@export var layers: Array[CompositionLayer] = []


## Converts this resource to the metadata format expected by Character model
func to_character_metadata() -> Dictionary:
	return {
		"display_name": display_name,
		"dialog_color": "#" + dialog_color.to_html(),
		"inner_dialog_color": "#" + inner_dialog_color.to_html(),
		"size_cm": {
			"width": base_size.x,
			"height": base_size.y
		}
	}


## Gets all body and face layers (non-wardrobe)
func get_base_layers() -> Array[CompositionLayer]:
	var base_layers: Array[CompositionLayer] = []
	for layer in layers:
		if layer.layer_type != CompositionLayer.LayerType.CLOTHING:
			base_layers.append(layer)
	return base_layers


## Gets all wardrobe (clothing) layers
func get_wardrobe_layers() -> Array[CompositionLayer]:
	var wardrobe_layers: Array[CompositionLayer] = []
	for layer in layers:
		if layer.layer_type == CompositionLayer.LayerType.CLOTHING:
			wardrobe_layers.append(layer)
	return wardrobe_layers


## Converts base layers to the format expected by ActorDirector
func to_character_layers() -> Dictionary:
	var character_layers = {}
	for layer in get_base_layers():
		character_layers[layer.id] = layer.to_layer_definition()
	return character_layers


## Converts face layers to the format expected by ActorDirector
func to_character_faces() -> Dictionary:
	var character_faces = {}
	for layer in get_base_layers():
		if layer.layer_type == CompositionLayer.LayerType.FACE:
			character_faces[layer.id] = layer.to_layer_definition()
	return character_faces


## Converts wardrobe layers to the format expected by Costumier
func to_wardrobe_array() -> Array:
	var wardrobe = []
	for layer in get_wardrobe_layers():
		wardrobe.append(layer.to_layer_definition())
	return wardrobe


## Gets a layer by ID
func get_layer_by_id(layer_id: String) -> CompositionLayer:
	for layer in layers:
		if layer.id == layer_id:
			return layer
	return null


## Adds a new layer to the composition
func add_layer(layer: CompositionLayer) -> void:
	layers.append(layer)
	emit_changed()


## Removes a layer from the composition
func remove_layer(layer: CompositionLayer) -> bool:
	var index = layers.find(layer)
	if index >= 0:
		layers.remove_at(index)
		emit_changed()
		return true
	return false


## Gets all root layers (layers without parent)
func get_root_layers() -> Array[CompositionLayer]:
	var root_layers: Array[CompositionLayer] = []
	for layer in layers:
		if layer.parent_layer_id == "":
			root_layers.append(layer)
	return root_layers


## Gets child layers of a specific parent
func get_child_layers(parent_id: String) -> Array[CompositionLayer]:
	var child_layers: Array[CompositionLayer] = []
	for layer in layers:
		if layer.parent_layer_id == parent_id:
			child_layers.append(layer)
	return child_layers


## Gets all unique layer_ids from all layers
func get_unique_layer_ids() -> Array[String]:
	var unique_ids: Array[String] = []
	for layer in layers:
		var lid = layer.layer_id if layer.layer_id != "" else layer.id
		if not lid in unique_ids:
			unique_ids.append(lid)
	return unique_ids


## Gets all layers that share the same layer_id
func get_layers_by_layer_id(layer_id: String) -> Array[CompositionLayer]:
	var matching_layers: Array[CompositionLayer] = []
	for layer in layers:
		var lid = layer.layer_id if layer.layer_id != "" else layer.id
		if lid == layer_id:
			matching_layers.append(layer)
	return matching_layers


## Validates the layer hierarchy (ensures no circular references, missing parents, etc.)
func validate_hierarchy() -> Dictionary:
	var errors = []
	var warnings = []
	
	# Check for duplicate IDs
	var id_counts = {}
	for layer in layers:
		if layer.id == "":
			errors.append("Layer with empty ID found")
			continue
		
		if layer.id in id_counts:
			id_counts[layer.id] += 1
		else:
			id_counts[layer.id] = 1
	
	for id in id_counts:
		if id_counts[id] > 1:
			errors.append("Duplicate layer ID: %s (found %d times)" % [id, id_counts[id]])
	
	# Check for missing parents
	var valid_ids = {}
	for layer in layers:
		valid_ids[layer.id] = true
	
	for layer in layers:
		if layer.parent_layer_id != "" and not layer.parent_layer_id in valid_ids:
			warnings.append("Layer '%s' references missing parent '%s'" % [layer.id, layer.parent_layer_id])
	
	# Check for circular references (simplified check)
	for layer in layers:
		if layer.parent_layer_id == layer.id:
			errors.append("Layer '%s' references itself as parent" % layer.id)
	
	return {
		"valid": errors.size() == 0,
		"errors": errors,
		"warnings": warnings
	}

