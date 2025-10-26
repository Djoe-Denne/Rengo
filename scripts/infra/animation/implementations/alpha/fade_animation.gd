## Fade animation - interpolates alpha (modulate.a) from start to end
class_name FadeAnimation
extends VNAnimationNode


func _init(p_target: ResourceNode = null, p_duration: float = 0.0) -> void:
	super._init(p_target, p_duration)
	print("FadeAnimation initialized")


## Setup default values for fade
func _setup_animation() -> void:
	print("FadeAnimation setup animation")
	from_value = target_node.scene_node.modulate.a
	to_value = 1.0 - from_value


## Process fade animation
func _process_animation(progress: float, _delta: float) -> void:
	if not target_node:
		return
	
	var alpha = lerp(float(from_value), float(to_value), progress)
	target_node.scene_node.modulate.a = alpha


## Apply final alpha value
func _apply_final_value() -> void:
	if not target_node or to_value == null:
		return
	
	target_node.modulate.a = float(to_value)
