## ScaleAction - Changes scale of a ResourceNode's scene_node
## Supports fluent API: scale().to(x, y), scale().up(factor), scale().uniform(factor)
## Works with both 2D (Vector2) and 3D (Vector3) nodes
class_name ScaleAction
extends TransformAction


func _init(p_target = null) -> void:
	super._init(p_target, TransformType.SCALE)


## Scale to absolute values
func to(x: float, y: float, z: float = 1.0) -> ScaleAction:
	# Scale is always Vector3 in our models
	target_value = Vector3(x, y, z)
	return self


## Scale uniformly to a factor
func uniform(factor: float) -> ScaleAction:
	target_value = Vector3(factor, factor, factor)
	return self


## Scale up by multiplying current scale
func up(factor: float) -> ScaleAction:
	var model = target.model if ("model" in target) else null
	if not model or not "scale" in model:
		push_warning("ScaleAction.up(): target has no scale model")
		target_value = Vector3.ONE
		return self
	
	var current_scale = model.scale
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
	var model = target.model if ("model" in target) else null
	if not model or not "scale" in model:
		push_warning("ScaleAction.x(): target has no scale model")
		target_value = Vector3.ONE
		return self
	
	var current_scale = model.scale
	target_value = Vector3(value, current_scale.y, current_scale.z)
	return self


## Scale only Y axis
func y(value: float) -> ScaleAction:
	var model = target.model if ("model" in target) else null
	if not model or not "scale" in model:
		push_warning("ScaleAction.y(): target has no scale model")
		target_value = Vector3.ONE
		return self
	
	var current_scale = model.scale
	target_value = Vector3(current_scale.x, value, current_scale.z)
	return self


## Scale only Z axis (3D only)
func z(value: float) -> ScaleAction:
	var model = target.model if ("model" in target) else null
	if not model or not "scale" in model:
		push_warning("ScaleAction.z(): target has no scale model")
		return self
	
	var current_scale = model.scale
	target_value = Vector3(current_scale.x, current_scale.y, value)
	return self


## Alias for in_duration
func in_time(p_duration: float) -> ScaleAction:
	return in_duration(p_duration)
