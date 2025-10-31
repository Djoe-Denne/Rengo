## Base class for actor directors
## Directors manage how actors are displayed (theater vs movie style)
class_name ActorDirector
extends Director

## Dictionary of loaded character acts { name: { act_name: Act } }
var character_acts: Dictionary = {}

## Dictionary of costumiers per character { name: Costumier }
var costumiers: Dictionary = {}

## Base asset paths for resolving character resources
const COMMON_CHARACTERS_PATH = "res://assets/scenes/common/characters/"
const SCENES_PATH = "res://assets/scenes/"


## Loads character metadata (display name, colors, defaults) into Character model
func load_character_metadata(character: Character) -> bool:
	# Get base directories for this character
	var base_dirs = get_character_base_dirs(character.name)
	
	if base_dirs.is_empty():
		push_warning("No base directories found for character: %s" % character.name)
		return false
	
	# Load character.yaml using ResourceRepository (no merging for character metadata)
	var metadata = ResourceRepository.load_yaml(base_dirs, "character", false)
	if metadata.is_empty():
		push_warning("Failed to load character metadata for: %s" % character.name)
		return false
	
	# Apply metadata to character
	if "character" in metadata:
		character.load_metadata(metadata.character)
	
	# Apply default states
	if "defaults" in metadata:
		character.apply_defaults(metadata.defaults)
	
	return true


## Loads a character's acts from their YAML files
func load_character(name: String) -> bool:
	# Check if already loaded
	if name in character_acts:
		return true
	
	# Get base directories for this character
	var base_dirs = get_character_base_dirs(name)
	
	if base_dirs.is_empty():
		push_error("No base directories found for character: %s" % name)
		return false
	
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


## Loads character layers from character.yaml
## @param name: Name of the character
## @return: Array of layer definitions or empty array on error
func load_character_layers(name: String) -> Array:
	var base_dirs = get_character_base_dirs(name)
	
	if base_dirs.is_empty():
		push_warning("No base directories found for character: %s" % name)
		return []
	
	# Load character.yaml
	var metadata = ResourceRepository.load_yaml(base_dirs, "character", false)
	if metadata.is_empty():
		push_warning("Failed to load character metadata for: %s" % name)
		return []
	
	# Extract layers array
	if "layers" in metadata:
		return metadata.layers
	
	return []


## Loads face layers from faces.yaml
## @param name: Name of the character
## @return: Array of face layer definitions or empty array on error
func load_face_layers(name: String) -> Array:
	var base_dirs = get_character_base_dirs(name)
	
	if base_dirs.is_empty():
		push_warning("No base directories found for character: %s" % name)
		return []
	
	# Load faces.yaml
	var faces_data = ResourceRepository.load_yaml(base_dirs, "faces", false)
	if faces_data.is_empty():
		push_warning("Failed to load faces for: %s" % name)
		return []
	
	# Extract faces array
	if "faces" in faces_data:
		return faces_data.faces
	
	return []


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


## Loads and parses a YAML file
func _load_yaml_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("YAML file not found: %s" % path)
		return {}
	
	# Parse YAML using the addon
	var result = YAML.load_file(path)
	
	if result.has_error():
		push_error("Failed to parse YAML file: %s - Error: %s" % [path, result.get_error()])
		return {}
	
	var data = result.get_data()
	if data is Dictionary:
		return data
	
	push_warning("YAML file did not contain a dictionary: %s" % path)
	return {}
