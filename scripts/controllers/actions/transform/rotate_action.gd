## RotateAction - Changes rotation of a ResourceNode's scene_node
## Supports fluent API: rotate().to(angle), rotate().by(amount)
class_name RotateAction
extends TransformAction


func _init(p_target = null) -> void:
	super._init(p_target, TransformType.ROTATION)


## Rotate to absolute angle (radians)
func to(angle: float) -> RotateAction:
	target_value = angle
	return self


## Rotate to angle in degrees
func to_degrees(degrees: float) -> RotateAction:
	target_value = deg_to_rad(degrees)
	return self


## Rotate by relative amount (radians)
func by(amount: float) -> RotateAction:
	var model = _get_model()
	if not model or not "rotation" in model:
		push_warning("RotateAction.by(): target has no rotation model")
		target_value = Vector3.ZERO
		return self
	
	var current_rotation = model.rotation
	# For Vector3 rotation, add to the appropriate axis (assume z-axis for 2D-style rotation)
	if current_rotation is Vector3:
		target_value = Vector3(current_rotation.x, current_rotation.y, current_rotation.z + amount)
	else:
		target_value = current_rotation + amount
	return self


## Rotate by amount in degrees
func by_degrees(degrees: float) -> RotateAction:
	return by(deg_to_rad(degrees))


## Rotate clockwise by amount
func clockwise(degrees: float) -> RotateAction:
	return by_degrees(degrees)


## Rotate counter-clockwise by amount
func counter_clockwise(degrees: float) -> RotateAction:
	return by_degrees(-degrees)


## Alias for in_duration
func in_time(p_duration: float) -> RotateAction:
	return in_duration(p_duration)

