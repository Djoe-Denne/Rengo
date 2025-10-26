## Instant animation - completes immediately with no interpolation
class_name InstantAnimation
extends VNAnimationNode


func _init(p_target: ResourceNode = null) -> void:
	# Force duration to 0 for instant animations
	super._init(p_target, 0.0)


## No processing needed for instant animations
func _process_animation(_progress: float, _delta: float) -> void:
	pass


## Instant animations complete immediately in the process() method
func _apply_final_value() -> void:
	# No-op - instant animations don't apply values
	pass

