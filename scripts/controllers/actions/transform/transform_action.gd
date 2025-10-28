## Base class for transformation actions (move, rotate, scale)
## Handles position/rotation/scale changes with animation support
class_name TransformAction
extends AnimatedAction

## Type of transformation
enum TransformType {
	POSITION,
	ROTATION,
	SCALE
}

## What property to transform
var transform_type: TransformType = TransformType.POSITION


func _init(p_target = null, p_type: TransformType = TransformType.POSITION) -> void:
	super._init(p_target)
	transform_type = p_type


## Create default animation for transforms
func _create_default_animation() -> VNAnimationNode:
	var TransformAnimation = load("res://scripts/infra/animation/implementations/transform/transform_animation.gd")
	return TransformAnimation.new(duration)


## Get current value based on transform type from MODEL
func _get_current_value() -> Variant:
	if not target:
		return null
	
	# Get the model (for Actor it's character, could be other Transformable)
	var model = _get_model()
	if not model:
		return null
	
	match transform_type:
		TransformType.POSITION:
			return model.position if "position" in model else Vector3.ZERO
		TransformType.ROTATION:
			return model.rotation if "rotation" in model else Vector3.ZERO
		TransformType.SCALE:
			return model.scale if "scale" in model else Vector3.ONE
	
	return null


## Apply value based on transform type to MODEL
func _apply_value(value: Variant) -> void:
	if not target:
		return
	
	# Get the model (for Actor it's character, could be other Transformable)
	var model = _get_model()
	if not model:
		return
	
	match transform_type:
		TransformType.POSITION:
			if model.has_method("set_position"):
				model.set_position(value)
			elif "position" in model:
				model.position = value
		
		TransformType.ROTATION:
			if model.has_method("set_rotation"):
				model.set_rotation(value)
			elif "rotation" in model:
				model.rotation = value
		
		TransformType.SCALE:
			if model.has_method("set_scale"):
				model.set_scale(value)
			elif "scale" in model:
				model.scale = value


## Process action - override to get interpolated value from animation
func _process_action(delta: float) -> void:
	if _is_complete:
		return
	
	if animation_node and animation_node.is_playing:
		# Process animation
		var is_done = animation_node.process(delta)
		
		# Get current value from animation and apply it
		var progress = animation_node.get_progress()
		animation_node.apply_to(target, progress, delta)
		
		# For TransformAnimation, get the current interpolated value
		if animation_node.has_method("get_current_value"):
			var current = animation_node.get_current_value()
			if current != null:
				_apply_value(current)
		
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


## Helper to get the model from the target
func _get_model():
	if not target:
		return null
	
	# For Actor: get the character model
	if "character" in target and target.character:
		return target.character
	
	# For other views that might have a model property
	if "model" in target and target.model:
		return target.model
	
	# If target itself is a Transformable (direct model access)
	if target is Transformable:
		return target
	
	push_warning("TransformAction: target does not have a Transformable model")
	return null
