## Base class for actor directors
## Directors manage how actors are displayed (theater vs movie style)
class_name ActorDirector
extends Director

## Dictionary of loaded character acts { name: { act_name: Act } }
var character_acts: Dictionary = {}

## Dictionary of loaded character metadata { name: Character }
var character_metadata: Dictionary = {}

## Dictionary of loaded character layers { layer_name: Layer } 
var character_layers: Dictionary = {}

## Dictionary of loaded character faces { face_name: Face }
var character_faces: Dictionary = {}

## character costumier
var costumier: Costumier = null

## Base asset paths for resolving character resources
const COMMON_CHARACTERS_PATH = "res://assets/scenes/common/characters/"
const SCENES_PATH = "res://assets/scenes/"

func _init(p_costumier: Costumier) -> void:
	super()
	costumier = p_costumier

## Loads a character's from their composition resource or YAML files
func load_character(character: Character) -> bool:
	var name = character.name
	# Check if already loaded
	if character_metadata:
		character.load_metadata(character_metadata)
		return true
	
	# Try loading from CharacterCompositionResource first
	var resource_path = _get_composition_resource_path(name)
	if ResourceLoader.exists(resource_path):
		print("Loading character '%s' from composition resource: %s" % [name, resource_path])
		return _load_from_composition_resource(character, resource_path)
	else:
		# Fallback to YAML loading
		push_error("Loading character '%s' from YAML files" % name)
		return _load_from_yaml(character)


## Gets the expected path for a CharacterCompositionResource
func _get_composition_resource_path(name: String) -> String:
	# Try scene-specific first
	if scene_model and scene_model.scene_name != "":
		var scene_path = SCENES_PATH + scene_model.scene_name + "/characters/" + name + "/" + name + "_composition.tres"
		if ResourceLoader.exists(scene_path):
			return scene_path
	
	# Try common path
	return COMMON_CHARACTERS_PATH + name + "/" + name + "_composition.tres"


## Loads a character from a CharacterCompositionResource
func _load_from_composition_resource(character: Character, resource_path: String) -> bool:
	var composition_resource = load(resource_path) as CharacterCompositionResource
	if not composition_resource:
		push_error("Failed to load CharacterCompositionResource: %s" % resource_path)
		return false
	
	# Set character name from resource if not already set
	if composition_resource.character_name != "":
		character.name = composition_resource.character_name
	
	# Load character metadata
	character_metadata = composition_resource.to_character_metadata()
	character.load_metadata(character_metadata)
	
	# Apply default states
	character.apply_defaults(composition_resource.default_states)
	
	# Extract layers
	for layer in composition_resource.get_base_layers():
		if layer.layer_type == CompositionLayer.LayerType.BODY:
			character_layers[layer.id] = layer.to_layer_definition()
		elif layer.layer_type == CompositionLayer.LayerType.FACE:
			character_faces[layer.id] = layer.to_layer_definition()
	
	# Create costumier with wardrobe from resource
	if not _load_wardrobe_from_resource(composition_resource):
		push_warning("Failed to create costumier from resource for: %s" % character.name)
	
	# Load acts (still from YAML for now)
	var base_dirs = get_character_base_dirs(character.name)
	if not base_dirs.is_empty():
		if not _load_character_acts(base_dirs, character.name):
			push_warning("Failed to load character acts for: %s" % character.name)
	
	# Create displayable layers
	_create_displayable_layers()
	
	# Set base size on actor view
	var actor = controller.get_view()
	if actor:
		actor.base_size = composition_resource.base_size
	
	return true


## Loads wardrobe from a CharacterCompositionResource
func _load_wardrobe_from_resource(composition_resource: CharacterCompositionResource) -> bool:
	# This should be overridden by subclasses (TheaterActorDirector)
	# For now, we'll create a basic wardrobe array
	var wardrobe_array = composition_resource.to_wardrobe_array()
	
	# Store wardrobe data for get_panoplie()
	if costumier:
		costumier.wardrobe = wardrobe_array
		return true
	
	return false


## Loads a character from YAML files (legacy method)
func _load_from_yaml(character: Character) -> bool:
	var name = character.name
	
	# Get base directories for this character
	var base_dirs = get_character_base_dirs(name)
	
	if base_dirs.is_empty():
		push_error("No base directories found for character: %s" % name)
		return false

	# Load character from character.yaml
	var character_data = ResourceRepository.load_yaml(base_dirs, "character", false)
	if character_data.is_empty():
		push_warning("No character found for: %s" % name)
		return false
	
	character_metadata = character_data.character
	character.load_metadata(character_metadata)
	
	for layer in character_data.layers:
		character_layers[layer.id] = layer

	# Load character faces from faces.yaml
	var faces_data = ResourceRepository.load_yaml(base_dirs, "faces", false)
	if faces_data.is_empty():
		push_warning("No faces found for: %s" % name)
		return false
	
	for face in faces_data.faces:
		character_faces[face.id] = face

	if not _load_character_acts(base_dirs, name):
		push_warning("Failed to load character acts for: %s" % name)
		return false

	if not load_wardrobe(name):
		push_warning("Failed to create costumier for: %s" % name)
		return false

	_create_displayable_layers()

	return true

func _create_displayable_layers() -> void:
	var actor = controller.get_view()
	if not actor:
		return
	
	var all_layers = get_character_layers()
	
	# Sort layers to ensure parent layers are created before child layers
	all_layers = _sort_layers_by_hierarchy(all_layers)
	
	for layer_def in all_layers:
		var layer_name = layer_def.get("layer", layer_def.get("id", ""))
		if layer_name == "":
			continue
		
		actor.add_layer(layer_name, layer_def)

## Sorts layers so that parent layers come before child layers
func _sort_layers_by_hierarchy(layers: Array) -> Array:
	var sorted_layers = []
	var remaining_layers = layers.duplicate()
	var max_iterations = layers.size() * 2  # Prevent infinite loops
	var iteration = 0
	
	while remaining_layers.size() > 0 and iteration < max_iterations:
		iteration += 1
		var added_this_iteration = []
		
		for layer_def in remaining_layers:
			var parent_name = layer_def.get("parent", "")
			
			# If no parent, it's a root layer - add it
			if parent_name == "":
				sorted_layers.append(layer_def)
				added_this_iteration.append(layer_def)
				continue
			
			# Check if parent has already been added
			var parent_added = false
			for sorted_layer in sorted_layers:
				var sorted_layer_name = sorted_layer.get("layer", sorted_layer.get("id", ""))
				if sorted_layer_name == parent_name:
					parent_added = true
					break
			
			# If parent is added, we can add this layer
			if parent_added:
				sorted_layers.append(layer_def)
				added_this_iteration.append(layer_def)
		
		# Remove added layers from remaining
		for added_layer in added_this_iteration:
			remaining_layers.erase(added_layer)
	
	# If any layers remain, they have missing parents - add them anyway
	if remaining_layers.size() > 0:
		push_warning("Some layers have missing parent references, adding them as root layers")
		sorted_layers.append_array(remaining_layers)
	
	return sorted_layers


func _load_character_acts(base_dirs: Array, name: String) -> bool:	
	# Load all act YAML files from the acts/ subdirectory
	var acts_data = ResourceRepository.load_yaml_directory(base_dirs, "acts/")
	
	if acts_data.is_empty():
		push_warning("No acts found for character: %s" % name)
		return false
	
	# Create Act objects from loaded data
	character_acts = {}
	
	for act_name in acts_data:
		var act_config = acts_data[act_name]
		if not act_config.is_empty():
			var act = Act.new(name, act_name, act_config)
			character_acts[act_name] = act
	
	return true


## Gets a specific act for a character
func get_act(name: String, act_name: String) -> Act:
	if character_acts:
		if act_name in character_acts:
			return character_acts[act_name]
	return null


func get_character_layers() -> Array:
	if not character_layers:
		push_warning("No character layers found")
		return []

	var all_layers = character_layers.values().duplicate()
	all_layers.append_array(get_character_faces())
	all_layers.append_array(get_panoplie())
	return all_layers

func get_character_faces() -> Array:
	if not character_faces:
		push_warning("No character faces found")
		return []

	return character_faces.values().duplicate()

func get_panoplie() -> Array:
	if not costumier:
		push_warning("No costumier found")
		return []

	var all_layers = []
	var state = controller.get_model().get_states().duplicate()
	if scene_model:
		state["plan"] = scene_model.current_plan_id

	var clothing_layers_dict = costumier.get_layers(controller.get_model().panoplie, state)
	
	# Convert clothing dictionary to array format
	for clothing_id in clothing_layers_dict.keys():
		var clothing_layer = clothing_layers_dict[clothing_id]
		var layer_dict = {
			"id": clothing_id,
			"layer": clothing_id,
			"image": clothing_layer.image,
			"z": clothing_layer.z,
			"anchor": clothing_layer.get("anchor", {"x": 0, "y": 0})
		}
		
		# Include parent field if specified
		if "parent" in clothing_layer:
			layer_dict["parent"] = clothing_layer.parent
		
		all_layers.append(layer_dict)

	return all_layers

## Gets the costumier for a character
func get_costumier() -> Costumier:
	return costumier


## Loads the wardrobe (panoplie.yaml) for a character
## Must be implemented by subclasses to create appropriate Costumier type
func load_wardrobe(name: String) -> bool:
	# Default implementation does nothing
	# Subclasses (TheaterActorDirector, MovieActorDirector) should override
	return false	

## Gets the base directories for a character's assets
## Returns scene-specific path first (if it exists), then common path
func get_character_base_dirs(name: String) -> Array:
	var base_dirs = []
	
	# Scene-specific character path (higher priority)
	if scene_model and scene_model.scene_name != "":
		var scene_char_path = SCENES_PATH + scene_model.scene_name + "/characters/" + name + "/"
		if DirAccess.dir_exists_absolute(scene_char_path):
			base_dirs.append(scene_char_path)
	
	# Common character path (fallback)
	var common_char_path = COMMON_CHARACTERS_PATH + name + "/"
	if DirAccess.dir_exists_absolute(common_char_path):
		base_dirs.append(common_char_path)
	
	return base_dirs

func instruct(displayable_model: DisplayableModel) -> void:
	pass
