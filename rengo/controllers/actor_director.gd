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

func _init() -> void:
	super()

## Loads a character's from their YAML files
func load_character(character: Character) -> bool:
	var name = character.name
	# Check if already loaded
	if character_metadata:
		character.load_metadata(character_metadata)
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
	
	character_metadata = character_data.character

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

	return true


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
		all_layers.append({
			"id": clothing_id,
			"layer": clothing_id,
			"image": clothing_layer.image,
			"z": clothing_layer.z,
			"anchor": clothing_layer.get("anchor", {"x": 0, "y": 0})
		})

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
