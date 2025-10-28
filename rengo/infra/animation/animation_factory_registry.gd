## Animation Factory Registry
## Scans and registers all animation factories from the factory folder
## Delegates animation instance creation to appropriate factories
class_name AnimationFactoryRegistry
extends RefCounted

## Registered factories mapped by animation type
var _factories: Dictionary = {}

## Fallback factory for unknown types (InstantAnimation)
var _fallback_factory: AnimationFactoryBase = null


func _init() -> void:
	_register_builtin_factories()


## Register all built-in animation factories
func _register_builtin_factories() -> void:
	# Load and instantiate all factory classes
	var transform_factory = load("res://rengo/infra/animation/factory/transform_animation_factory.gd").new()
	var state_change_factory = load("res://rengo/infra/animation/factory/state_change_animation_factory.gd").new()
	var shader_factory = load("res://rengo/infra/animation/factory/shader_animation_factory.gd").new()
	var video_factory = load("res://rengo/infra/animation/factory/video_animation_factory.gd").new()
	var instant_factory = load("res://rengo/infra/animation/factory/instant_animation_factory.gd").new()
	
	# Register factories
	register_factory("transform", transform_factory)
	register_factory("state_change", state_change_factory)
	register_factory("shader", shader_factory)
	register_factory("video", video_factory)
	register_factory("instant", instant_factory)
	
	# Set fallback factory
	_fallback_factory = instant_factory


## Register a factory for a specific animation type
## @param anim_type: The animation type this factory handles
## @param factory: AnimationFactoryBase instance
func register_factory(anim_type: String, factory: AnimationFactoryBase) -> void:
	if not factory:
		push_error("AnimationFactoryRegistry: Cannot register null factory for type '%s'" % anim_type)
		return
	
	_factories[anim_type] = factory


## Unregister a factory
## @param anim_type: The animation type to unregister
func unregister_factory(anim_type: String) -> void:
	_factories.erase(anim_type)


## Create an animation instance from a definition
## @param definition: Dictionary with type, duration, parameters
## @return: VNAnimationNode instance or null
func create_animation(definition: Dictionary) -> VNAnimationNode:
	if not definition or definition.is_empty():
		push_warning("AnimationFactoryRegistry: Empty definition provided")
		return _fallback_factory.create({}) if _fallback_factory else null
	
	var anim_type = definition.get("type", "instant")
	
	# Find appropriate factory
	var factory = _factories.get(anim_type, null)
	
	if not factory:
		push_warning("AnimationFactoryRegistry: No factory registered for type '%s', using fallback" % anim_type)
		factory = _fallback_factory
	
	if not factory:
		push_error("AnimationFactoryRegistry: No fallback factory available")
		return null
	
	# Delegate creation to factory
	return factory.create(definition)


## Check if a factory is registered for the given type
## @param anim_type: Animation type to check
## @return: true if a factory is registered
func has_factory(anim_type: String) -> bool:
	return anim_type in _factories


## Get all registered animation types
## @return: Array of animation type strings
func get_registered_types() -> Array:
	return _factories.keys()


## Scan a directory for factory classes and register them
## This allows runtime discovery of custom factories
## @param directory_path: Path to directory containing factory scripts
func scan_and_register_factories(directory_path: String) -> void:
	if not DirAccess.dir_exists_absolute(directory_path):
		push_warning("AnimationFactoryRegistry: Directory not found: %s" % directory_path)
		return
	
	var dir = DirAccess.open(directory_path)
	if not dir:
		push_error("AnimationFactoryRegistry: Failed to open directory: %s" % directory_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with("_factory.gd"):
			var file_path = directory_path + "/" + file_name
			
			# Try to load and instantiate the factory
			var factory_script = load(file_path)
			if factory_script:
				var factory_instance = factory_script.new()
				
				# Check if it extends AnimationFactoryBase
				if factory_instance is AnimationFactoryBase:
					# Try to determine what type it handles
					# Note: Factories should have a static TYPE constant or we scan with can_create
					_try_register_scanned_factory(factory_instance)
				else:
					push_warning("AnimationFactoryRegistry: '%s' does not extend AnimationFactoryBase" % file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()


## Try to register a scanned factory by testing common animation types
func _try_register_scanned_factory(factory: AnimationFactoryBase) -> void:
	# Test common types
	var common_types = ["transform", "state_change", "shader", "video", "instant", "custom"]
	
	for anim_type in common_types:
		if factory.can_create(anim_type):
			register_factory(anim_type, factory)
			return
	
	push_warning("AnimationFactoryRegistry: Factory doesn't handle any common types, skipping")

