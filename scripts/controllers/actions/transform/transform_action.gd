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


## Get current value based on transform type
func _get_current_value() -> Variant:
	if not target:
		return null
	
	match transform_type:
		TransformType.POSITION:
			return target.position if "position" in target else Vector3.ZERO
		TransformType.ROTATION:
			if target.scene_node and "rotation" in target.scene_node:
				return target.scene_node.rotation
			return 0.0
		TransformType.SCALE:
			if target.scene_node and "scale" in target.scene_node:
				var scale_val = target.scene_node.scale
				# Return appropriate type based on node type
				if target.scene_node is Node3D:
					return scale_val if scale_val is Vector3 else Vector3.ONE
				else:
					return scale_val if scale_val is Vector2 else Vector2.ONE
			# Default based on likely node type
			return Vector3.ONE if (target.scene_node and target.scene_node is Node3D) else Vector2.ONE
	
	return null


## Apply value based on transform type
func _apply_value(value: Variant) -> void:
	if not target:
		return
	
	match transform_type:
		TransformType.POSITION:
			if "position" in target:
				target.position = value
				if target.has_method("update_position"):
					target.update_position()
		
		TransformType.ROTATION:
			if target.scene_node and "rotation" in target.scene_node:
				target.scene_node.rotation = value
		
		TransformType.SCALE:
			if target.scene_node and "scale" in target.scene_node:
				# Convert Vector2 to Vector3 for Node3D
				if target.scene_node is Node3D and value is Vector2:
					target.scene_node.scale = Vector3(value.x, value.y, 1.0)
				# Convert Vector3 to Vector2 for Node2D
				elif target.scene_node is Node2D and value is Vector3:
					target.scene_node.scale = Vector2(value.x, value.y)
				else:
					target.scene_node.scale = value


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
