## AnimationRepository - Singleton for centralized animation loading
## Similar to ResourceRepository but for animations
## Supports YAML-based animation definitions and programmatic registration
extends Node

## Base paths for animation resolution
const COMMON_PATH = "res://assets/scenes/common/"
const SCENES_PATH = "res://assets/scenes/"
const ANIMATIONS_PATH = "animations/"

## Programmatically registered animations
var _registered_animations: Dictionary = {}

## Cached animation definitions
var _animation_cache: Dictionary = {}


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
	var cache_key = "%s|%s|%s" % [scene_path, character_path, name]
	
	# Check cache
	if cache_key in _animation_cache:
		return _create_from_definition(_animation_cache[cache_key])
	
	# Load from YAML
	var base_dirs = get_base_dirs(scene_path, character_path)
	var anim_def = _load_animation_yaml(base_dirs, name)
	
	if anim_def.is_empty():
		push_warning("AnimationRepository: Animation '%s' not found" % name)
		return null
	
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
func _create_from_definition(definition: Dictionary) -> VNAnimationNode:
	var anim_type = definition.get("type", "instant")
	var duration = definition.get("duration", 0.0)
	var params = definition.get("parameters", {})
	
	match anim_type:
		"transform":
			return _create_transform_animation(duration, params)
		
		"state_change":
			return _create_state_change_animation(duration, params)
		
		"shader":
			return _create_shader_animation(duration, params)
		
		"video":
			return _create_video_animation(duration, params)
		
		"instant", _:
			var InstantAnimation = load("res://scripts/infra/animation/implementations/effects/instant_animation.gd")
			return InstantAnimation.new()


## Creates a TransformAnimation from parameters
func _create_transform_animation(duration: float, params: Dictionary) -> VNAnimationNode:
	var TransformAnimation = load("res://scripts/infra/animation/implementations/transform/transform_animation.gd")
	
	# Parse easing
	var easing_str = params.get("easing", "linear")
	var easing = _parse_easing(easing_str)
	
	var anim = TransformAnimation.new(duration, easing)
	
	# Set shake parameters if present
	if params.has("shake_intensity"):
		var intensity = params.shake_intensity
		var frequency = params.get("shake_frequency", 20.0)
		anim.set_shake(intensity, frequency)
	
	return anim


## Creates a StateChangeAnimation from parameters
func _create_state_change_animation(duration: float, params: Dictionary) -> VNAnimationNode:
	var StateChangeAnimation = load("res://scripts/infra/animation/implementations/state_change_animation.gd")
	var fade_fraction = params.get("fade_fraction", 0.3)
	var anim = StateChangeAnimation.new(duration, fade_fraction)
	return anim


## Creates a ShaderAnimation from parameters
func _create_shader_animation(duration: float, params: Dictionary) -> VNAnimationNode:
	var ShaderAnimation = load("res://scripts/infra/animation/implementations/shader_animation.gd")
	var anim = ShaderAnimation.new(duration)
	
	# Set shader path if provided
	if params.has("shader_path"):
		anim.with_shader(params.shader_path)
	
	# Set shader parameters if provided
	if params.has("shader_params"):
		anim.set_shader_params(params.shader_params)
	
	return anim


## Creates a VideoAnimation from parameters
func _create_video_animation(duration: float, params: Dictionary) -> VNAnimationNode:
	var VideoAnimation = load("res://scripts/infra/animation/implementations/video_animation.gd")
	
	# Parse video type
	var video_type_str = params.get("video_type", "animated_texture")
	var video_type = _parse_video_type(video_type_str)
	
	var anim = VideoAnimation.new(duration, video_type)
	
	# Set resource path if provided
	if params.has("resource_path"):
		anim.with_resource(params.resource_path)
	
	# Set loop if provided
	if params.has("loop"):
		anim.with_loop(params.loop)
	
	return anim


## Parses easing string to EasingType enum
func _parse_easing(easing_str: String) -> int:
	var TransformAnimation = load("res://scripts/infra/animation/implementations/transform/transform_animation.gd")
	
	match easing_str.to_lower():
		"linear":
			return TransformAnimation.EasingType.LINEAR
		"ease_in":
			return TransformAnimation.EasingType.EASE_IN
		"ease_out":
			return TransformAnimation.EasingType.EASE_OUT
		"ease_in_out":
			return TransformAnimation.EasingType.EASE_IN_OUT
		"elastic_in":
			return TransformAnimation.EasingType.ELASTIC_IN
		"elastic_out":
			return TransformAnimation.EasingType.ELASTIC_OUT
		"elastic_in_out":
			return TransformAnimation.EasingType.ELASTIC_IN_OUT
		"bounce_in":
			return TransformAnimation.EasingType.BOUNCE_IN
		"bounce_out":
			return TransformAnimation.EasingType.BOUNCE_OUT
		"bounce_in_out":
			return TransformAnimation.EasingType.BOUNCE_IN_OUT
		"back_in":
			return TransformAnimation.EasingType.BACK_IN
		"back_out":
			return TransformAnimation.EasingType.BACK_OUT
		"back_in_out":
			return TransformAnimation.EasingType.BACK_IN_OUT
		_:
			return TransformAnimation.EasingType.LINEAR


## Parses video type string to VideoType enum
func _parse_video_type(video_type_str: String) -> int:
	var VideoAnimation = load("res://scripts/infra/animation/implementations/video_animation.gd")
	
	match video_type_str.to_lower():
		"video_stream":
			return VideoAnimation.VideoType.VIDEO_STREAM
		"animated_texture":
			return VideoAnimation.VideoType.ANIMATED_TEXTURE
		"sprite_frames":
			return VideoAnimation.VideoType.SPRITE_FRAMES
		"image_sequence":
			return VideoAnimation.VideoType.IMAGE_SEQUENCE
		_:
			return VideoAnimation.VideoType.ANIMATED_TEXTURE


## Simple dictionary merge
func _merge_dicts(base: Dictionary, override: Dictionary) -> Dictionary:
	var result = base.duplicate(true)
	for key in override:
		result[key] = override[key]
	return result

