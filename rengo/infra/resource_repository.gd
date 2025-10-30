## ResourceRepository - Singleton for centralized resource loading with dual-folder virtualization
## Handles path resolution across scene-specific and common directories for all resource types
extends Node

## Base paths for resource resolution
const COMMON_PATH = "res://assets/scenes/common/"
const SCENES_PATH = "res://assets/scenes/"
const CAMERAS_PATH = "res://assets/scenes/common/cameras/"


## Generates base directory array for a scene context
## @param scene_path: Scene identifier (e.g., "demo_scene")
## @param sub_path: Subdirectory within the scene structure (e.g., "characters/me/")
## @return: Array of base directories [scene-specific, common] with priority order
func get_base_dirs(scene_path: String, sub_path: String) -> Array:
	var base_dirs = []
	
	# Scene-specific path (higher priority)
	if scene_path != "":
		var scene_specific_path = SCENES_PATH + scene_path + "/" + sub_path
		if DirAccess.dir_exists_absolute(scene_specific_path):
			base_dirs.append(scene_specific_path)
	
	# Common path (fallback)
	var common_path = COMMON_PATH + sub_path
	if DirAccess.dir_exists_absolute(common_path):
		base_dirs.append(common_path)
	
	return base_dirs


## Finds the first existing resource path from base directories
## @param base_dirs: List of base directories to search
## @param resource_path: Relative path to the resource
## @return: Full path to the resource or empty string if not found
func get_resource_path(base_dirs: Array, resource_path: String) -> String:
	if resource_path == "":
		return ""
	
	for base_dir in base_dirs:
		var full_path = base_dir + resource_path
		if ResourceLoader.exists(full_path) or FileAccess.file_exists(full_path):
			return full_path
	
	return ""


## Loads any Godot resource from base directories
## @param base_dirs: List of base directories to search
## @param resource_path: Relative path to the resource
## @return: Loaded resource or null if not found
func load_resource(base_dirs: Array, resource_path: String) -> Resource:
	var full_path = get_resource_path(base_dirs, resource_path)
	
	if full_path == "":
		push_warning("Resource not found in any base directory: %s (searched: %s)" % [resource_path, str(base_dirs)])
		return null
	
	if ResourceLoader.exists(full_path):
		return load(full_path)
	
	return null


## Loads and optionally merges YAML files from base directories
## @param base_dirs: List of base directories to search
## @param base_name: Base filename without extension (e.g., "panoplie")
## @param merge_scene: If true, loads base.yaml from common and merges with base-scene.yaml from scene folder
## @return: Dictionary with merged YAML data or empty dictionary on error
func load_yaml(base_dirs: Array, base_name: String, merge_scene: bool = true) -> Dictionary:
	if base_dirs.is_empty() or base_name == "":
		return {}
	
	var result_data = {}
	
	if merge_scene and base_dirs.size() >= 2:
		# Load base YAML from common folder (last in priority = common)
		var common_dir = base_dirs[-1]
		var common_path = common_dir + base_name + ".yaml"
		
		if FileAccess.file_exists(common_path):
			var common_data = _load_yaml_file(common_path)
			if not common_data.is_empty():
				result_data = common_data
		
		# Load and merge scene-specific YAML (first in priority = scene-specific)
		if base_dirs.size() > 1:
			var scene_dir = base_dirs[0]
			var scene_path = scene_dir + base_name + "-scene.yaml"
			
			if FileAccess.file_exists(scene_path):
				var scene_data = _load_yaml_file(scene_path)
				if not scene_data.is_empty():
					result_data = _deep_merge(result_data, scene_data)
	else:
		# No merging - just load the first available file
		var file_path = get_resource_path(base_dirs, base_name + ".yaml")
		if file_path != "":
			result_data = _load_yaml_file(file_path)
	
	return result_data


## Loads and parses a single YAML file
## @param path: Full path to the YAML file
## @return: Parsed dictionary or empty dictionary on error
func _load_yaml_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	
	var result = YAML.load_file(path)
	
	if result.has_error():
		push_error("Failed to parse YAML file: %s - Error: %s" % [path, result.get_error()])
		return {}
	
	var data = result.get_data()
	if data is Dictionary:
		return data
	
	push_warning("YAML file did not contain a dictionary: %s" % path)
	return {}


## Deep merges two dictionaries, concatenating arrays
## @param base: Base dictionary
## @param override: Dictionary to merge into base
## @return: Merged dictionary
func _deep_merge(base: Dictionary, override: Dictionary) -> Dictionary:
	var result = base.duplicate(true)
	
	for key in override:
		if key in result:
			# Both have the same key
			if result[key] is Dictionary and override[key] is Dictionary:
				# Both are dictionaries - recursively merge
				result[key] = _deep_merge(result[key], override[key])
			elif result[key] is Array and override[key] is Array:
				# Both are arrays - concatenate
				result[key] = result[key] + override[key]
			else:
				# Different types or primitives - override wins
				result[key] = override[key]
		else:
			# New key from override
			result[key] = override[key]
	
	return result


## Loads a camera definition from the common cameras directory
## @param camera_name: Name of the camera (e.g., "standard", "cinemascope")
## @return: Dictionary with camera data or empty dictionary on error
func load_camera(camera_name: String) -> Dictionary:
	var camera_path = CAMERAS_PATH + camera_name + ".yaml"
	
	if not FileAccess.file_exists(camera_path):
		push_warning("Camera definition not found: %s" % camera_path)
		return {}
	
	var data = _load_yaml_file(camera_path)
	
	# Return the camera data directly (should have a "camera" key)
	if "camera" in data:
		return data.camera
	
	return data


## Resolves template placeholders in a path string using state values
## Auto-detects {placeholder} patterns and replaces them with values from state dictionary
## @param template: Template string with {placeholder} patterns (e.g., "images/{plan}/{orientation}/body.png")
## @param state: Dictionary containing state values to substitute (e.g., {"plan": "medium_shot", "orientation": "front"})
## @return: Resolved path string with all placeholders replaced
func resolve_template_path(template: String, state: Dictionary) -> String:
	if template == "":
		return ""
	
	var result = template
	
	# Use regex to find all {placeholder} patterns
	var regex = RegEx.new()
	regex.compile("\\{([^}]+)\\}")
	
	var matches = regex.search_all(result)
	
	# Replace each placeholder with its state value
	for match_obj in matches:
		var placeholder = match_obj.get_string(1)  # Get the text inside {}
		var replacement = state.get(placeholder, "")
		
		if not null and replacement != "" and replacement != "default":
			# Replace {placeholder} with the actual value
			result = result.replace("{" + placeholder + "}", str(replacement))
		else:
			result = result.replace("_{" + placeholder + "}", "")
	
	return result


## Loads all YAML files from a directory
## @param base_dirs: List of base directories to search
## @param sub_dir: Subdirectory to scan (e.g., "acts/")
## @return: Dictionary of { filename_without_ext: parsed_data }
func load_yaml_directory(base_dirs: Array, sub_dir: String) -> Dictionary:
	var result = {}
	
	# Process directories in reverse order (common first, then scene-specific overrides)
	for i in range(base_dirs.size() - 1, -1, -1):
		var dir_path = base_dirs[i] + sub_dir
		
		if not DirAccess.dir_exists_absolute(dir_path):
			continue
		
		var dir = DirAccess.open(dir_path)
		if not dir:
			push_warning("Failed to open directory: %s" % dir_path)
			continue
		
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".yaml"):
				var base_name = file_name.get_basename()
				var file_path = dir_path + file_name
				
				var file_data = _load_yaml_file(file_path)
				if not file_data.is_empty():
					# Override if already exists (scene-specific wins)
					result[base_name] = file_data
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return result
