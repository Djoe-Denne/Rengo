@tool
## CompositionLayer - Sub-resource representing a single character layer
## Used in CharacterCompositionResource for visual character composition
class_name CompositionLayer
extends Resource

## Layer type enum - determines how the layer is used
enum LayerType { 
	BODY,      # Base body layer
	FACE,      # Facial expressions
	CLOTHING   # Wardrobe items
}

## Unique identifier for this layer
@export var id: String = ""

## Layer ID for grouping variants (e.g., "cloth_bottom" for both chinos and jeans)
## If empty, defaults to id
@export var layer_id: String = ""

## Template path with placeholders (e.g., "images/{plan}/{orientation}/body/{pose}_{body}.png")
## Placeholders are replaced at runtime based on character state
@export var template_path: String = ""

## Position offset relative to parent (or absolute if root layer)
@export var position: Vector2 = Vector2.ZERO

## Z-index for layer ordering (higher = rendered on top)
@export var z_index: int = 0

## Parent layer ID (empty string = root layer)
@export var parent_layer_id: String = ""

## Tags for wardrobe system (e.g., ["casual", "top"])
@export var tags: Array[String] = []

## Excluding tags - items with these tags will be removed when this layer is worn
@export var excluding_tags: Array[String] = []

## Layer type classification
@export var layer_type: LayerType = LayerType.BODY

## Preview image path (for visual editor preview)
@export var preview_image_path: String = ""

## Whether this layer is shown in the preview
@export var preview_active: bool = false


## Converts this layer to the dictionary format expected by the runtime system
func to_layer_definition() -> Dictionary:
	var layer_def = {
		"id": id,
		"image": template_path,
		"z": z_index,
		"anchor": {"x": position.x, "y": position.y},
		"layer_id": layer_id if layer_id != "" else id
	}
	
	# Add parent if specified
	if parent_layer_id != "":
		layer_def["parent"] = parent_layer_id
	
	# Add tags for wardrobe items
	if layer_type == LayerType.CLOTHING:
		if tags.size() > 0:
			layer_def["tags"] = tags.duplicate()
		if excluding_tags.size() > 0:
			layer_def["excluding_tags"] = excluding_tags.duplicate()
	
	return layer_def


## Creates a CompositionLayer from a layer definition dictionary (for YAML import)
static func from_layer_definition(layer_def: Dictionary) -> CompositionLayer:
	var layer = CompositionLayer.new()
	
	layer.id = layer_def.get("id", "")
	layer.layer_name = layer_def.get("layer", layer.id)
	layer.template_path = layer_def.get("image", "")
	layer.z_index = layer_def.get("z", 0)
	layer.parent_layer_id = layer_def.get("parent", "")
	layer.layer_id = layer_def.get("layer_id", layer.id)  # Default to id if not specified
	
	# Parse anchor/position
	if "anchor" in layer_def:
		var anchor = layer_def.anchor
		if anchor is Dictionary:
			layer.position = Vector2(
				anchor.get("x", 0.0),
				anchor.get("y", 0.0)
			)
	
	# Parse tags for wardrobe items
	if "tags" in layer_def:
		var tags_data = layer_def.tags
		if tags_data is Array:
			layer.tags.clear()
			for tag in tags_data:
				layer.tags.append(str(tag))
	
	if "excluding_tags" in layer_def:
		var excluding_data = layer_def.excluding_tags
		if excluding_data is Array:
			layer.excluding_tags.clear()
			for tag in excluding_data:
				layer.excluding_tags.append(str(tag))
	
	# Determine layer type based on tags or layer name
	if layer.tags.size() > 0 or layer.excluding_tags.size() > 0:
		layer.layer_type = LayerType.CLOTHING
	elif "face" in layer.layer_name.to_lower():
		layer.layer_type = LayerType.FACE
	else:
		layer.layer_type = LayerType.BODY
	
	return layer

