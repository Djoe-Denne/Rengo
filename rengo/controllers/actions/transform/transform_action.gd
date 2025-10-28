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
	var TransformAnimation = load("res://rengo/infra/animation/implementations/transform/transform_animation.gd")
	return TransformAnimation.new(duration)


## Get current value based on transform type from MODEL via controller
func _get_current_value() -> Variant:
	if not target:
		return null
	
	# Target should be a controller with a model
	if not ("model" in target):
		push_warning("TransformAction: target is not a controller with model")
		return null
	
	var model = target.model
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


## Apply value based on transform type via controller
func _apply_value(value: Variant) -> void:
	if not target:
		return
	
	# Target should be a controller with update methods
	if not ("model" in target):
		push_warning("TransformAction: target is not a controller")
		return
	
	# Use controller's update_model_* methods
	match transform_type:
		TransformType.POSITION:
			if target.has_method("update_model_position"):
				target.update_model_position(value)
			elif target.model and target.model.has_method("set_position"):
				target.model.set_position(value)
		
		TransformType.ROTATION:
			if target.has_method("update_model_rotation"):
				target.update_model_rotation(value)
			elif target.model and target.model.has_method("set_rotation"):
				target.model.set_rotation(value)
		
		TransformType.SCALE:
			if target.has_method("update_model_scale"):
				target.update_model_scale(value)
			elif target.model and target.model.has_method("set_scale"):
				target.model.set_scale(value)


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
