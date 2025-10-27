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
	
	# Process background image paths to be absolute
	_process_background_paths(scene_config, scene_path)
	
	# Create Scene model from configuration
	var scene_model = Scene.from_dict(scene_path, scene_config)
	
	# Create director based on scene type
	var director = _create_director(scene_model, scene_path)
	if not director:
		push_error("Failed to create director for scene: %s" % scene_path)
		return null
	
	# Create StageView
	var stage_view = StageView.new()
	
	# Load and instantiate VNScene
	var vn_scene_packed = load("res://scripts/scenes/game/vn_scene.tscn")
	var vn_scene = vn_scene_packed.instantiate()
	
	# Set scene model and director
	vn_scene.set_scene_model(scene_model)
	vn_scene.set_director(director)
	vn_scene.set_stage_view(stage_view)
	
	# Wire up observers
	# Director observes scene model for plan changes
	director.set_scene_model(scene_model)
	
	# StageView observes scene model for plan changes
	stage_view.set_scene_model(scene_model, vn_scene)
	
	# Setup controller with scene model
	# (Will be done in VNScene._ready via controller)
	
	return vn_scene


## Creates the appropriate director based on scene model
static func _create_director(scene_model: Scene, scene_path: String):
	var scene_type = scene_model.scene_type
	
	var director
	if scene_type == "theater":
		var TheaterActorDirector = load("res://scripts/views/theater_actor_director.gd")
		director = TheaterActorDirector.new()
	elif scene_type == "movie":
		var MovieActorDirector = load("res://scripts/views/movie_actor_director.gd")
		director = MovieActorDirector.new()
	else:
		push_error("Unknown scene type: %s" % scene_type)
		return null
	
	# Prepare the director with the scene path
	director.prepare(scene_path)
	
	return director


## Processes background image paths to be absolute
static func _process_background_paths(scene_config: Dictionary, scene_path: String) -> void:
	if "plans" in scene_config:
		for plan_config in scene_config.plans:
			if "backgrounds" in plan_config:
				for bg_config in plan_config.backgrounds:
					if "image" in bg_config:
						bg_config.image = "res://assets/scenes/" + scene_path + "/" + bg_config.image


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

