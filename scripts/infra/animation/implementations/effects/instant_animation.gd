## Instant animation - completes immediately with no interpolation
class_name InstantAnimation
extends VNAnimationNode


func _init() -> void:
	# Force duration to 0 for instant animations
	super._init(0.0)


## No processing needed for instant animations - action handles the value change
## Target should be a controller, but instant animations don't use it
func apply_to(target: Variant, progress: float, delta: float) -> void:
	# Instant animations don't animate anything
	# The action that contains this animation will apply the value directly
	# via controller methods (update_model_* or apply_view_effect)
	pass

