## AnimationRepository - Singleton for centralized animation loading
## Similar to ResourceRepository but for animations
## Supports YAML-based animation definitions and programmatic registration
## Delegates instance creation to AnimationFactoryRegistry
extends Node

## Base paths for animation resolution
const COMMON_PATH = "res://assets/scenes/common/"
const SCENES_PATH = "res://assets/scenes/"
const ANIMATIONS_PATH = "animations/"

## Factory registry for creating animation instances
var _factory_registry: AnimationFactoryRegistry = null

## Programmatically registered animations
var _registered_animations: Dictionary = {}

## Cached animation definitions
var _animation_cache: Dictionary = {}


func _init() -> void:
	# Initialize factory registry
	_factory_registry = AnimationFactoryRegistry.new()


## Generates base directory array for animation context
## @param scene_path: Scene identifier (e.g., "demo_scene")
## @param character_path: Character subdirectory (e.g., "characters/me/")
## @return: Array of base directories with priority order [scene-specific, common]
func get_base_dirs(scene_path: String, character_path: String = "") -> Array:
	var base_dirs = []
	
	# Scene-specific character path (highest priority)
	if scene_path != "" and character_path != "":
		var scene_char_path = SCENES_PATH + scene_path + "/" + character_path + ANIMATIONS_PATH
		if DirAccess.dir_exists_absolute(scene_char_path):
			base_dirs.append(scene_char_path)
	
	# Common character path
	if character_path != "":
		var common_char_path = COMMON_PATH + character_path + ANIMATIONS_PATH
		if DirAccess.dir_exists_absolute(common_char_path):
			base_dirs.append(common_char_path)
	
	# Scene-specific animations path
	if scene_path != "":
		var scene_anim_path = SCENES_PATH + scene_path + "/" + ANIMATIONS_PATH
		if DirAccess.dir_exists_absolute(scene_anim_path):
			base_dirs.append(scene_anim_path)
	
	# Common animations path
	var common_anim_path = COMMON_PATH + ANIMATIONS_PATH
	if DirAccess.dir_exists_absolute(common_anim_path):
		base_dirs.append(common_anim_path)
	
	return base_dirs


## Loads an animation by name
## @param name: Animation name
## @param context: Dictionary with optional keys: scene_path, character_path
## @return: VNAnimationNode instance or null
func load_animation(name: String, context: Dictionary = {}) -> VNAnimationNode:
	# Check if animation is programmatically registered
	if name in _registered_animations:
		return _registered_animations[name].duplicate() if _registered_animations[name] else null
	
	# Build cache key
	var scene_path = context.get("scene_path", "")
	var character_path = context.get("character_path", "")
	var cache_key = "%s|%s|%s|%s" % [scene_path, character_path, name]
	
	# Check cache
	if cache_key in _animation_cache:
		return _create_from_definition(_animation_cache[cache_key])
	
	# Load from YAML
	var base_dirs = get_base_dirs(scene_path, character_path)
	var anim_def = _load_animation_yaml(base_dirs, name)
	
	if anim_def.is_empty():
		push_warning("AnimationRepository: Animation '%s' not found" % name)
		return null

	if context.has("parameters"):
		var params = context.get("parameters", {})
		# Merge parameters with animation definition
		anim_def.parameters = _merge_dicts(anim_def.parameters, params)
	# Cache the definition
	_animation_cache[cache_key] = anim_def
	
	return _create_from_definition(anim_def)


## Loads default animation settings for an action type
## @param action_type: Type of action (e.g., "move", "express", "pose")
## @param context: Dictionary with scene_path, character_path
## @return: Dictionary with animation settings
func load_default_animation(action_type: String, context: Dictionary = {}) -> Dictionary:
	var scene_path = context.get("scene_path", "")
	var character_path = context.get("character_path", "")
	var base_dirs = get_base_dirs(scene_path, character_path)
	
	# Try to load animation.yaml or animation-scene.yaml
	var defaults_def = _load_animation_defaults_yaml(base_dirs)
	
	if defaults_def.has("defaults") and defaults_def.defaults.has(action_type):
		return defaults_def.defaults[action_type]
	
	return {}


## Registers an animation programmatically
## @param name: Animation name
## @param animation_node: VNAnimationNode instance
func register_animation(name: String, animation_node: VNAnimationNode) -> void:
	_registered_animations[name] = animation_node


## Unregisters an animation
func unregister_animation(name: String) -> void:
	_registered_animations.erase(name)


## Clears the animation cache
func clear_cache() -> void:
	_animation_cache.clear()


## Loads animation YAML file from base directories
func _load_animation_yaml(base_dirs: Array, name: String) -> Dictionary:
	if base_dirs.is_empty():
		return {}
	
	# Try scene-specific first, then fallback to common
	for base_dir in base_dirs:
		var scene_path = base_dir + name + "-scene.yaml"
		if FileAccess.file_exists(scene_path):
			return _load_yaml_file(scene_path)
		
		var common_path = base_dir + name + ".yaml"
		if FileAccess.file_exists(common_path):
			return _load_yaml_file(common_path)
	
	return {}


## Loads animation defaults YAML (animation.yaml or animation-scene.yaml)
func _load_animation_defaults_yaml(base_dirs: Array) -> Dictionary:
	if base_dirs.is_empty():
		return {}
	
	var result = {}
	
	# Load from common (lower priority)
	for i in range(base_dirs.size() - 1, -1, -1):
		var base_dir = base_dirs[i]
		
		# Try base file
		var base_path = base_dir + "animation.yaml"
		if FileAccess.file_exists(base_path):
			var data = _load_yaml_file(base_path)
			result = _merge_dicts(result, data)
		
		# Try scene-specific file
		var scene_path = base_dir + "animation-scene.yaml"
		if FileAccess.file_exists(scene_path):
			var data = _load_yaml_file(scene_path)
			result = _merge_dicts(result, data)
	
	return result


## Loads and parses a YAML file
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


## Creates a VNAnimationNode from a definition dictionary
## Delegates to the factory registry
func _create_from_definition(definition: Dictionary) -> VNAnimationNode:
	if not _factory_registry:
		push_error("AnimationRepository: Factory registry not initialized")
		return null
	
	return _factory_registry.create_animation(definition)


## Register a custom animation factory
## @param anim_type: The animation type this factory handles
## @param factory: AnimationFactoryBase instance
func register_factory(anim_type: String, factory) -> void:
	if not _factory_registry:
		push_error("AnimationRepository: Factory registry not initialized")
		return
	
	_factory_registry.register_factory(anim_type, factory)


## Get all registered animation types
## @return: Array of animation type strings
func get_registered_animation_types() -> Array:
	if not _factory_registry:
		return []
	
	return _factory_registry.get_registered_types()


## Simple dictionary merge
func _merge_dicts(base: Dictionary, override: Dictionary) -> Dictionary:
	var result = base.duplicate(true)
	for key in override:
		result[key] = override[key]
	return result
