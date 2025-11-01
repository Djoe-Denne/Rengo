## Base class for actor directors
## Directors manage how actors are displayed (theater vs movie style)
class_name ActorDirector
extends Director

## Dictionary of loaded character acts { name: { act_name: Act } }
var character_acts: Dictionary = {}

## Dictionary of loaded character metadata { name: Character }
var character_metadata: Dictionary = {}

## Dictionary of loaded character layers { name: { layer_name: Layer } }
var character_layers: Dictionary = {}

## Dictionary of loaded character faces { name: { face_name: Face } }
var character_faces: Dictionary = {}

## Dictionary of costumiers per character { name: Costumier }
var costumiers: Dictionary = {}

## Base asset paths for resolving character resources
const COMMON_CHARACTERS_PATH = "res://assets/scenes/common/characters/"
const SCENES_PATH = "res://assets/scenes/"

## Loads a character's from their YAML files
func load_character(character: Character) -> bool:
	var name = character.name
	# Check if already loaded
	if name in character_metadata:
		character.load_metadata(character_metadata[name])
		return true
	
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
	
	character_metadata[name] = character_data.character

	character_layers[name] = character_data.layers

	# Load character faces from faces.yaml
	var faces_data = ResourceRepository.load_yaml(base_dirs, "faces", false)
	if faces_data.is_empty():
		push_warning("No faces found for: %s" % name)
		return false
	
	character_faces[name] = faces_data.faces

	if not _load_character_acts(base_dirs, name):
		push_warning("Failed to load character acts for: %s" % name)
		return false

	if not load_wardrobe(name):
		push_warning("Failed to create costumier for: %s" % name)
		return false

	return true


func _load_character_acts(base_dirs: Array, name: String) -> bool:	
	# Load all act YAML files from the acts/ subdirectory
	var acts_data = ResourceRepository.load_yaml_directory(base_dirs, "acts/")
	
	if acts_data.is_empty():
		push_warning("No acts found for character: %s" % name)
		return false
	
	# Create Act objects from loaded data
	character_acts[name] = {}
	
	for act_name in acts_data:
		var act_config = acts_data[act_name]
		if not act_config.is_empty():
			var act = Act.new(name, act_name, act_config)
			character_acts[name][act_name] = act
	
	return true


## Gets a specific act for a character
func get_act(name: String, act_name: String) -> Act:
	if name in character_acts:
		if act_name in character_acts[name]:
			return character_acts[name][act_name]
	return null


func get_character_metadata(name: String) -> Character:
	if name in character_metadata:
		return character_metadata[name]
	return null

func get_character_layers(character: Character) -> Array:
	if  not character.name in character_layers:
		push_warning("No character layers found for: %s" % character.name)
		return []

	var all_layers = []
	all_layers.append_array(character_layers[character.name])
	all_layers.append_array(get_character_faces(character))
	all_layers.append_array(get_panoplie(character))
	return all_layers

func get_character_faces(character: Character) -> Array:
	if not character.name in character_faces:
		push_warning("No character faces found for: %s" % character.name)
		return []

	return character_faces[character.name]

func get_panoplie(character: Character) -> Array:
	if not character.name in costumiers:
		return []

	var all_layers = []
	var state = character.get_states().duplicate()
	if scene_model:
		state["plan"] = scene_model.current_plan_id

	var costumier = costumiers[character.name]
	var clothing_layers_dict = costumier.get_layers(character.panoplie, state)
	
	# Convert clothing dictionary to array format
	for clothing_id in clothing_layers_dict.keys():
		var clothing_layer = clothing_layers_dict[clothing_id]
		all_layers.append({
			"id": clothing_id,
			"layer": clothing_id,
			"image": clothing_layer.image,
			"z": clothing_layer.z,
			"anchor": clothing_layer.get("anchor", {"x": 0, "y": 0})
		})

	return all_layers

## Gets the costumier for a character
func get_costumier(name: String) -> Costumier:
	if name in costumiers:
		return costumiers[name]
	return null


## Loads the wardrobe (panoplie.yaml) for a character
## Must be implemented by subclasses to create appropriate Costumier type
func load_wardrobe(name: String) -> bool:
	# Default implementation does nothing
	# Subclasses (TheaterActorDirector, MovieActorDirector) should override
	return false


## Loads shader configuration for a character
## @param name: Name of the character
## @return: Dictionary with shader configurations or empty dictionary
func load_shader_config(name: String) -> Dictionary:
	var base_dirs = get_character_base_dirs(name)
	
	if base_dirs.is_empty():
		return {}
	
	# Load shader config using ShaderRepository
	return ShaderRepository.load_shader_config(base_dirs)
	

## Gets the base directories for a character's assets
## Returns scene-specific path first (if it exists), then common path
func get_character_base_dirs(name: String) -> Array:
	var base_dirs = []
	
	# Scene-specific character path (higher priority)
	if scene_path != "":
		var scene_char_path = SCENES_PATH + scene_path + "/characters/" + name + "/"
		if DirAccess.dir_exists_absolute(scene_char_path):
			base_dirs.append(scene_char_path)
	
	# Common character path (fallback)
	var common_char_path = COMMON_CHARACTERS_PATH + name + "/"
	if DirAccess.dir_exists_absolute(common_char_path):
		base_dirs.append(common_char_path)
	
	return base_dirs
