## Factory for creating VNScenes from YAML configuration
class_name SceneFactory
extends RefCounted


## Creates a VNScene from a scene configuration
static func create(scene_path: String) -> Node:
	
	# Load scene configuration
	var scene_config_path = "res://assets/scenes/" + scene_path + "/scene.yaml"
	var scene_config = _load_yaml_file(scene_config_path)
	
	if scene_config.is_empty():
		push_error("Failed to load scene config: %s" % scene_config_path)
		return null
	
	# Create director based on scene type
	var director = _create_director(scene_config, scene_path)
	if not director:
		push_error("Failed to create director for scene: %s" % scene_path)
		return null
	
	# Create stage
	var stage = _create_stage(scene_config, scene_path)
	
	# Load and instantiate VNScene
	var vn_scene_packed = load("res://scripts/scenes/game/vn_scene.tscn")
	var vn_scene = vn_scene_packed.instantiate()
	
	# Set director and stage
	vn_scene.set_director(director)
	vn_scene.set_stage(stage)
	
	# Setup default background
	if stage and "stage" in scene_config and "default_background" in scene_config.stage:
		var default_bg = scene_config.stage.default_background
		# Access ActingLayer directly since @onready vars aren't initialized yet
		var acting_layer = vn_scene.get_node("ActingLayer")
		stage.create_background_node(acting_layer, default_bg)
	
	return vn_scene


## Creates the appropriate director based on scene configuration
static func _create_director(scene_config: Dictionary, scene_path: String):
	var scene_type = "theater"  # Default
	if "scene" in scene_config and "type" in scene_config.scene:
		scene_type = scene_config.scene.type
	
	var director
	if scene_type == "theater":
		var TheaterActorDirector = load("res://scripts/core/theater/theater_actor_director.gd")
		director = TheaterActorDirector.new()
	elif scene_type == "movie":
		var MovieActorDirector = load("res://scripts/core/theater/movie_actor_director.gd")
		director = MovieActorDirector.new()
	else:
		push_error("Unknown scene type: %s" % scene_type)
		return null
	
	# Prepare the director with the scene path
	director.prepare(scene_path)
	
	return director


## Creates the stage with background configurations
static func _create_stage(scene_config: Dictionary, scene_path: String) -> Stage:
	var stage = Stage.new()
	
	# Load background configurations
	if "backgrounds" in scene_config:
		for bg_config in scene_config.backgrounds:
			var bg_id = bg_config.get("id", "")
			if bg_id == "":
				continue
			
			# Process image path to be absolute if present
			if "image" in bg_config:
				bg_config.image = "res://assets/scenes/" + scene_path + "/" + bg_config.image
			
			stage.add_background(bg_id, bg_config)
	
	# Set default background
	if "stage" in scene_config and "default_background" in scene_config.stage:
		stage.current_background_id = scene_config.stage.default_background
	
	return stage


## Loads and parses a YAML file
static func _load_yaml_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("YAML file not found: %s" % path)
		return {}
	
	# Parse YAML using the addon (YAML is a static class)
	var result = YAML.load_file(path)
	
	if result.has_error():
		push_error("Failed to parse YAML file: %s - Error: %s" % [path, result.get_error()])
		return {}
	
	var data = result.get_data()
	if data is Dictionary:
		return data
	
	push_warning("YAML file did not contain a dictionary: %s" % path)
	return {}

