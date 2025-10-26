## ScaleAction - Changes scale of a ResourceNode's scene_node
## Supports fluent API: scale().to(x, y), scale().up(factor), scale().uniform(factor)
class_name ScaleAction
extends TransformAction


func _init(p_target = null) -> void:
	super._init(p_target, TransformType.SCALE)


## Scale to absolute values
func to(x: float, y: float) -> ScaleAction:
	target_value = Vector2(x, y)
	return self


## Scale uniformly to a factor
func uniform(factor: float) -> ScaleAction:
	target_value = Vector2(factor, factor)
	return self


## Scale up by multiplying current scale
func up(factor: float) -> ScaleAction:
	if not target or not target.scene_node or not "scale" in target.scene_node:
		push_warning("ScaleAction.up(): target has no scale")
		target_value = Vector2.ONE
		return self
	
	var current_scale = target.scene_node.scale
	target_value = current_scale * factor
	return self


## Scale down by dividing current scale
func down(factor: float) -> ScaleAction:
	if factor == 0.0:
		push_warning("ScaleAction.down(): factor cannot be zero")
		return self
	
	return up(1.0 / factor)


## Scale only X axis
func x(value: float) -> ScaleAction:
	if not target or not target.scene_node or not "scale" in target.scene_node:
		push_warning("ScaleAction.x(): target has no scale")
		target_value = Vector2.ONE
		return self
	
	var current_scale = target.scene_node.scale
	target_value = Vector2(value, current_scale.y)
	return self


## Scale only Y axis
func y(value: float) -> ScaleAction:
	if not target or not target.scene_node or not "scale" in target.scene_node:
		push_warning("ScaleAction.y(): target has no scale")
		target_value = Vector2.ONE
		return self
	
	var current_scale = target.scene_node.scale
	target_value = Vector2(current_scale.x, value)
	return self


## Alias for in_duration
func in_time(p_duration: float) -> ScaleAction:
	return in_duration(p_duration)

