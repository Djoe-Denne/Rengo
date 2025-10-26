## MoveAction - Changes position of a ResourceNode
## Supports fluent API: move().to(x, y), move().left(amount), etc.
class_name MoveAction
extends TransformAction


func _init(p_target = null) -> void:
	super._init(p_target, TransformType.POSITION)


## Move to absolute position (normalized coordinates)
func to(x: float, y: float, z: float = 0.0) -> MoveAction:
	target_value = Vector3(x, y, z)
	return self


## Move left by amount (normalized)
func left(amount: float) -> MoveAction:
	if not target or not "position" in target:
		push_warning("MoveAction.left(): target has no position")
		target_value = Vector3.ZERO
		return self
	
	var current_pos = target.position
	target_value = Vector3(current_pos.x - amount, current_pos.y, current_pos.z)
	return self


## Move right by amount (normalized)
func right(amount: float) -> MoveAction:
	if not target or not "position" in target:
		push_warning("MoveAction.right(): target has no position")
		target_value = Vector3.ZERO
		return self
	
	var current_pos = target.position
	target_value = Vector3(current_pos.x + amount, current_pos.y, current_pos.z)
	return self


## Move up by amount (normalized)
func up(amount: float) -> MoveAction:
	if not target or not "position" in target:
		push_warning("MoveAction.up(): target has no position")
		target_value = Vector3.ZERO
		return self
	
	var current_pos = target.position
	target_value = Vector3(current_pos.x, current_pos.y - amount, current_pos.z)
	return self


## Move down by amount (normalized)
func down(amount: float) -> MoveAction:
	if not target or not "position" in target:
		push_warning("MoveAction.down(): target has no position")
		target_value = Vector3.ZERO
		return self
	
	var current_pos = target.position
	target_value = Vector3(current_pos.x, current_pos.y + amount, current_pos.z)
	return self


## Move forward (increase z-depth)
func forward(amount: float) -> MoveAction:
	if not target or not "position" in target:
		push_warning("MoveAction.forward(): target has no position")
		target_value = Vector3.ZERO
		return self
	
	var current_pos = target.position
	target_value = Vector3(current_pos.x, current_pos.y, current_pos.z + amount)
	return self


## Move backward (decrease z-depth)
func backward(amount: float) -> MoveAction:
	if not target or not "position" in target:
		push_warning("MoveAction.backward(): target has no position")
		target_value = Vector3.ZERO
		return self
	
	var current_pos = target.position
	target_value = Vector3(current_pos.x, current_pos.y, current_pos.z - amount)
	return self


## Alias for in_duration to match user's expected API
func in_time(p_duration: float) -> MoveAction:
	return in_duration(p_duration)

