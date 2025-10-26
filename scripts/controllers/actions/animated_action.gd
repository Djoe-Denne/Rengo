## Base class for actions that can be animated
## Composes an AnimationNode to provide smooth transitions
## Supports fluent API: action.in(duration).using(animation)
class_name AnimatedAction
extends ActionNode

## The animation node that controls how the action is animated
var animation_node: VNAnimationNode = null

## The target layers to animate
var parameters: Dictionary = {}

## The target value to reach (position, state, etc.)
var target_value: Variant = null

## The initial value (captured at execute time)
var initial_value: Variant = null

## Animation name or instance to use
var animation_name: String = ""

## Whether animation has been initialized
var _animation_initialized: bool = false


func _init(p_target = null) -> void:
	super._init(p_target, 0.0)


## Builder method: Sets the duration of the animation
func in_duration(p_duration: float):
	duration = p_duration
	if animation_node:
		animation_node.set_duration(p_duration)
	return self


## Alias for in_duration (more fluent API)
## Note: "in" is a reserved keyword in GDScript, so we use "over"
func over(p_duration: float):
	return in_duration(p_duration)


## Builder method: Specifies which animation to use
## Can be a string (animation name from repository) or VNAnimationNode instance
func using(animation_or_name: Variant):
	if animation_or_name is String:
		animation_name = animation_or_name
	elif animation_or_name is VNAnimationNode:
		animation_node = animation_or_name
		animation_node.set_duration(duration)
	else:
		push_warning("AnimatedAction.using(): Expected String or VNAnimationNode, got %s" % type_string(typeof(animation_or_name)))
	return self


## Builder method: Specifies which layers to animate
func set_parameters(p_parameters: Dictionary):
	parameters = p_parameters
	return self


## Execute the action - setup animation
func execute() -> void:
	super.execute()
	
	if not target:
		push_error("AnimatedAction: no target")
		_is_complete = true
		return
	
	# Capture initial value
	initial_value = _get_current_value()
	
	# Setup animation if duration > 0
	if duration > 0.0:
		_initialize_animation()
		if animation_node:
			animation_node.set_values(initial_value, target_value)
			animation_node.play()
	else:
		# Instant - apply immediately
		_apply_value(target_value)
		_is_complete = true


## Process the action each frame
func _process_action(delta: float) -> void:
	if _is_complete:
		return
	
	if animation_node and animation_node.is_playing:
		# Process animation
		var is_done = animation_node.process(delta)
		
		# Apply animation to target
		var progress = animation_node.get_progress()
		animation_node.apply_to(target, progress, delta)
		
		if is_done:
			# Ensure final value is set
			_apply_value(target_value)
			_is_complete = true
			on_complete()
	elif duration <= 0.0:
		# Instant action
		_apply_value(target_value)
		_is_complete = true
		on_complete()


## Initialize the animation node
func _initialize_animation() -> void:
	if _animation_initialized:
		return
	
	_animation_initialized = true
	
	# If no animation node set, try to load from repository or create default
	if not animation_node:
		if animation_name != "":
			animation_node = _load_animation_from_repository(animation_name)
		else:
			animation_node = _create_default_animation()
		
		if animation_node:
			animation_node.set_duration(duration)


## Load animation from AnimationRepository
func _load_animation_from_repository(anim_name: String) -> VNAnimationNode:
	# Get AnimationRepository singleton (autoload, accessible by name)
	if not AnimationRepository:
		push_warning("AnimationRepository singleton not found, using default animation")
		return _create_default_animation()
	
	# Build context for animation loading
	var context = {}
	if not parameters.is_empty():
		context["parameters"] = parameters

	# TODO: Get scene_path and character_path from target if available
	
	# Load animation from repository
	var anim = AnimationRepository.load_animation(anim_name, context)
	if not anim:
		push_warning("Animation '%s' not found in repository, using default" % anim_name)
		return _create_default_animation()
	
	return anim


## Create default animation - override in subclasses
func _create_default_animation() -> VNAnimationNode:
	# Default to instant animation
	var InstantAnimation = load("res://scripts/infra/animation/implementations/effects/instant_animation.gd")
	return InstantAnimation.new()


## Get current value from target - override in subclasses
func _get_current_value() -> Variant:
	push_error("AnimatedAction._get_current_value() must be implemented by subclass")
	return null


## Apply value to target - override in subclasses
func _apply_value(value: Variant) -> void:
	push_error("AnimatedAction._apply_value() must be implemented by subclass")
