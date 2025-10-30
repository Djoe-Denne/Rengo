## Base class for actor directors
## Directors manage how actors are displayed (theater vs movie style)
class_name ActorDirector
extends RefCounted

## Dictionary of loaded character acts { character_name: { act_name: Act } }
var character_acts: Dictionary = {}

## Dictionary of costumiers per character { character_name: Costumier }
var costumiers: Dictionary = {}

## The scene path this director is working with
var scene_path: String = ""

## Reference to Scene model (for observing plan changes)
var scene_model: Scene = null

## Base asset paths for resolving character resources
const COMMON_CHARACTERS_PATH = "res://assets/scenes/common/characters/"
const SCENES_PATH = "res://assets/scenes/"


## Prepares the director with the scene path
func prepare(p_scene_path: String) -> void:
	scene_path = p_scene_path


## Sets the scene model and subscribes to changes
func set_scene_model(p_scene_model: Scene) -> void:
	scene_model = p_scene_model
	
	# Subscribe to scene changes
	if scene_model:
		scene_model.add_observer(_on_scene_changed)


## Observer callback - called when Scene model changes
func _on_scene_changed(scene_state: Dictionary) -> void:
	# Plan changed - subclasses can override to refresh actors
	pass


## Loads character metadata (display name, colors, defaults) into Character model
func load_character_metadata(character: Character) -> bool:
	# Get base directories for this character
	var base_dirs = get_character_base_dirs(character.character_name)
	
	if base_dirs.is_empty():
		push_warning("No base directories found for character: %s" % character.character_name)
		return false
	
	# Load character.yaml using ResourceRepository (no merging for character metadata)
	var metadata = ResourceRepository.load_yaml(base_dirs, "character", false)
	if metadata.is_empty():
		push_warning("Failed to load character metadata for: %s" % character.character_name)
		return false
	
	# Apply metadata to character
	if "character" in metadata:
		character.load_metadata(metadata.character)
	
	# Apply default states
	if "defaults" in metadata:
		character.apply_defaults(metadata.defaults)
	
	return true


## Instructs an actor to change their appearance/state
## Must be implemented by subclasses
func instruct(actor, new_states: Dictionary = {}) -> void:
	push_error("instruct() must be implemented by subclass")


## Loads a character's acts from their YAML files
func load_character(character_name: String) -> bool:
	# Check if already loaded
	if character_name in character_acts:
		return true
	
	# Get base directories for this character
	var base_dirs = get_character_base_dirs(character_name)
	
	if base_dirs.is_empty():
		push_error("No base directories found for character: %s" % character_name)
		return false
	
	# Load all act YAML files from the acts/ subdirectory
	var acts_data = ResourceRepository.load_yaml_directory(base_dirs, "acts/")
	
	if acts_data.is_empty():
		push_warning("No acts found for character: %s" % character_name)
		return false
	
	# Create Act objects from loaded data
	character_acts[character_name] = {}
	
	for act_name in acts_data:
		var act_config = acts_data[act_name]
		if not act_config.is_empty():
			var act = Act.new(character_name, act_name, act_config)
			character_acts[character_name][act_name] = act
	
	return true


## Gets a specific act for a character
func get_act(character_name: String, act_name: String) -> Act:
	if character_name in character_acts:
		if act_name in character_acts[character_name]:
			return character_acts[character_name][act_name]
	return null


## Gets the costumier for a character
func get_costumier(character_name: String) -> Costumier:
	if character_name in costumiers:
		return costumiers[character_name]
	return null


## Loads the wardrobe (panoplie.yaml) for a character
## Must be implemented by subclasses to create appropriate Costumier type
func load_wardrobe(character_name: String) -> bool:
	# Default implementation does nothing
	# Subclasses (TheaterActorDirector, MovieActorDirector) should override
	return false


## Loads shader configuration for a character
## @param character_name: Name of the character
## @return: Dictionary with shader configurations or empty dictionary
func load_shader_config(character_name: String) -> Dictionary:
	var base_dirs = get_character_base_dirs(character_name)
	
	if base_dirs.is_empty():
		return {}
	
	# Load shader config using ShaderRepository
	return ShaderRepository.load_shader_config(base_dirs)


## Loads character layers from character.yaml
## @param character_name: Name of the character
## @return: Array of layer definitions or empty array on error
func load_character_layers(character_name: String) -> Array:
	var base_dirs = get_character_base_dirs(character_name)
	
	if base_dirs.is_empty():
		push_warning("No base directories found for character: %s" % character_name)
		return []
	
	# Load character.yaml
	var metadata = ResourceRepository.load_yaml(base_dirs, "character", false)
	if metadata.is_empty():
		push_warning("Failed to load character metadata for: %s" % character_name)
		return []
	
	# Extract layers array
	if "layers" in metadata:
		return metadata.layers
	
	return []


## Loads face layers from faces.yaml
## @param character_name: Name of the character
## @return: Array of face layer definitions or empty array on error
func load_face_layers(character_name: String) -> Array:
	var base_dirs = get_character_base_dirs(character_name)
	
	if base_dirs.is_empty():
		push_warning("No base directories found for character: %s" % character_name)
		return []
	
	# Load faces.yaml
	var faces_data = ResourceRepository.load_yaml(base_dirs, "faces", false)
	if faces_data.is_empty():
		push_warning("Failed to load faces for: %s" % character_name)
		return []
	
	# Extract faces array
	if "faces" in faces_data:
		return faces_data.faces
	
	return []


## Gets the base directories for a character's assets
## Returns scene-specific path first (if it exists), then common path
func get_character_base_dirs(character_name: String) -> Array:
	var base_dirs = []
	
	# Scene-specific character path (higher priority)
	if scene_path != "":
		var scene_char_path = SCENES_PATH + scene_path + "/characters/" + character_name + "/"
		if DirAccess.dir_exists_absolute(scene_char_path):
			base_dirs.append(scene_char_path)
	
	# Common character path (fallback)
	var common_char_path = COMMON_CHARACTERS_PATH + character_name + "/"
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

