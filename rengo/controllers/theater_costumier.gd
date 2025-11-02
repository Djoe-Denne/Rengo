## TheaterCostumier - Theater-style wardrobe management
## Manages multi-layer clothing with tags, exclusions, and template substitution
class_name TheaterCostumier extends Costumier

func _init(p_controller: ActorController) -> void:
	super(p_controller)

## Selects a clothing item and returns updated outfit with exclusions applied
func select(panoplie: Array, clothing_id: String) -> Array:
	# Create a copy to avoid modifying the original
	var new_panoplie = panoplie.duplicate()
	
	# Find the clothing item
	var clothing = _find_clothing(clothing_id)
	if not clothing:
		push_warning("Clothing item not found: %s" % clothing_id)
		return new_panoplie
	
	# Get excluding tags
	var excluding_tags = clothing.get("excluding_tags", [])
	
	# If this clothing excludes others, remove conflicting items
	if excluding_tags.size() > 0:
		var items_to_remove = []
		for item_id in new_panoplie:
			var item = _find_clothing(item_id)
			if item:
				var item_tags = item.get("tags", [])
				# Check if this item has any excluded tags
				for tag in excluding_tags:
					if tag in item_tags:
						# Mark this item for removal
						items_to_remove.append(item_id)
						break
		
		# Remove conflicting items
		for item_id in items_to_remove:
			new_panoplie.erase(item_id)
	
	# Add the new clothing item (if not already present)
	if not clothing_id in new_panoplie:
		new_panoplie.append(clothing_id)
	
	return new_panoplie

## Returns clothing layers for the current panoplie
## Performs template substitution and z-ordering
func get_layers(panoplie: Array, state: Dictionary) -> Dictionary:
	var layers = {}
	
	# Get all active clothing items
	for clothing_id in panoplie:
		var clothing = _find_clothing(clothing_id)
		if not clothing:
			continue
		
		var image_path = clothing.get("image", "")
		var z = clothing.get("z", 1)
		var anchor = clothing.get("anchor", {"x": 0, "y": 0})
		
		# Use ResourceRepository for unified template resolution
		image_path = ResourceRepository.resolve_template_path(image_path, state)
		
		# Add layer data
		layers[clothing_id] = {
			"image": image_path,
			"z": z,
			"anchor": anchor
		}
	
	return layers


## Finds a clothing item by ID
func _find_clothing(clothing_id: String) -> Dictionary:
	for clothing in wardrobe:
		if clothing.get("id", "") == clothing_id:
			return clothing
	return {}
