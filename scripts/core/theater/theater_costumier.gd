## TheaterCostumier - Theater-style wardrobe management
## Manages multi-layer clothing with tags, exclusions, and template substitution
class_name TheaterCostumier extends Costumier


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
		
		var variants = clothing.get("variants", [])
		var z = clothing.get("z", 1)
		var anchor = clothing.get("anchor", {"x": 0, "y": 0})
		
		# Find appropriate variant based on current state
		var variant = _find_best_variant(variants, state)
		if not variant:
			continue
		
		# Perform template substitution
		var image_path = variant.get("image", "")
		image_path = _substitute_templates(image_path, state)
		
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


## Finds the best variant for the current state
func _find_best_variant(variants: Array, state: Dictionary) -> Dictionary:
	var orientation = state.get("orientation", "front")
	# stage tags is the list of all state values
	var state_tags = state.values()
	
	var best_variant = null
	var best_score = -1
	
	for variant in variants:
		# Check if this variant supports the current orientation
		var orientations = variant.get("orientations", [])
		if not orientation in orientations:
			continue
		
		# Calculate match score based on tags
		var variant_tags = variant.get("tags", [])
		var score = 0
		
		for tag in variant_tags:
			if tag in state_tags:
				score += 1
		
		# Default variants have priority if no tags match
		if variant.get("default", false) and score == 0:
			score = 0.5
		
		if score > best_score:
			best_score = score
			best_variant = variant
	
	return best_variant if best_variant else {}


## Performs template substitution in image paths
func _substitute_templates(path: String, state: Dictionary) -> String:
	var result = path
	
	# Substitute {orientation}
	if "{orientation}" in result:
		result = result.replace("{orientation}", state.get("orientation", "front"))
	
	# Substitute {color}
	if "{color}" in result:
		result = result.replace("{color}", state.get("color", "default"))
	
	# Substitute {variant}
	if "{variant}" in result:
		result = result.replace("{variant}", state.get("variant", "default"))
	
	return result
