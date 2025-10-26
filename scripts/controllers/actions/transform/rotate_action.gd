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
	if not target or not target.scene_node or not "rotation" in target.scene_node:
		push_warning("RotateAction.by(): target has no rotation")
		target_value = 0.0
		return self
	
	var current_rotation = target.scene_node.rotation
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

