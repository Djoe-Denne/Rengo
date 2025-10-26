## Fade animation - interpolates alpha (modulate.a) from start to end
## LEGACY: This is kept for backward compatibility
## New code should use StateChangeAnimation or TransformAnimation
class_name FadeAnimation
extends VNAnimationNode


func _init(p_duration: float = 0.0) -> void:
	super._init(p_duration)


## Applies the fade animation to target
func apply_to(target: Variant, progress: float, _delta: float) -> void:
	if not target or not target.scene_node:
		return
	
	# Setup from_value on first frame
	if from_value == null:
		from_value = target.scene_node.modulate.a
		to_value = 1.0 - from_value
	
	# Interpolate alpha
	var alpha = lerp(float(from_value), float(to_value), progress)
	target.scene_node.modulate.a = alpha
