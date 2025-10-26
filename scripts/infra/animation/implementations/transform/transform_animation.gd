## Transform animation - smooth interpolation with easing functions
## Supports Vector2, Vector3, float values
## Can apply shake/wobble effects on top of base interpolation
class_name TransformAnimation
extends VNAnimationNode

## Easing type
enum EasingType {
	LINEAR,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT,
	ELASTIC_IN,
	ELASTIC_OUT,
	ELASTIC_IN_OUT,
	BOUNCE_IN,
	BOUNCE_OUT,
	BOUNCE_IN_OUT,
	BACK_IN,
	BACK_OUT,
	BACK_IN_OUT
}

## Current easing function
var easing: EasingType = EasingType.LINEAR

## Shake parameters
var shake_intensity: float = 0.0
var shake_frequency: float = 20.0

## Current interpolated value
var current_value: Variant = null


func _init(p_duration: float = 0.0, p_easing: EasingType = EasingType.LINEAR) -> void:
	super._init(p_duration)
	easing = p_easing


## Applies the animation to a target
func apply_to(target: Variant, progress: float, delta: float) -> void:
	# Apply easing to progress
	var eased_progress = _apply_easing(progress, easing)
	
	# Interpolate between from_value and to_value
	current_value = _interpolate(from_value, to_value, eased_progress)
	
	# Apply shake if intensity > 0
	if shake_intensity > 0.0:
		current_value = _apply_shake(current_value, progress, delta)
	
	# The calling AnimatedAction will use this value
	# We don't directly modify the target here


## Gets the current interpolated value (with shake if applicable)
func get_current_value() -> Variant:
	return current_value


## Interpolate between two values
func _interpolate(from: Variant, to: Variant, t: float) -> Variant:
	if from is Vector2 and to is Vector2:
		return from.lerp(to, t)
	elif from is Vector3 and to is Vector3:
		return from.lerp(to, t)
	elif from is float and to is float:
		return lerpf(from, to, t)
	elif from is int and to is int:
		return int(lerpf(float(from), float(to), t))
	elif from is Color and to is Color:
		return from.lerp(to, t)
	else:
		# Fallback - just return the target when halfway
		return to if t >= 0.5 else from


## Apply shake effect to a value
func _apply_shake(value: Variant, progress: float, _delta: float) -> Variant:
	# Shake diminishes as animation progresses
	var shake_amount = shake_intensity * (1.0 - progress)
	
	# Use time for randomness
	var time = _elapsed_time * shake_frequency
	var offset_x = sin(time * 13.0) * shake_amount
	var offset_y = cos(time * 17.0) * shake_amount
	
	if value is Vector2:
		return value + Vector2(offset_x, offset_y)
	elif value is Vector3:
		var offset_z = sin(time * 19.0) * shake_amount
		return value + Vector3(offset_x, offset_y, offset_z)
	else:
		return value


## Apply easing function to progress
func _apply_easing(t: float, ease_type: EasingType) -> float:
	match ease_type:
		EasingType.LINEAR:
			return t
		
		EasingType.EASE_IN:
			return t * t
		
		EasingType.EASE_OUT:
			return t * (2.0 - t)
		
		EasingType.EASE_IN_OUT:
			return -0.5 * (cos(PI * t) - 1.0)
		
		EasingType.ELASTIC_IN:
			return _ease_elastic_in(t)
		
		EasingType.ELASTIC_OUT:
			return _ease_elastic_out(t)
		
		EasingType.ELASTIC_IN_OUT:
			return _ease_elastic_in_out(t)
		
		EasingType.BOUNCE_IN:
			return 1.0 - _ease_bounce_out(1.0 - t)
		
		EasingType.BOUNCE_OUT:
			return _ease_bounce_out(t)
		
		EasingType.BOUNCE_IN_OUT:
			return _ease_bounce_in_out(t)
		
		EasingType.BACK_IN:
			return _ease_back_in(t)
		
		EasingType.BACK_OUT:
			return _ease_back_out(t)
		
		EasingType.BACK_IN_OUT:
			return _ease_back_in_out(t)
		
		_:
			return t


## Elastic easing functions
func _ease_elastic_in(t: float) -> float:
	if t == 0.0 or t == 1.0:
		return t
	return -pow(2.0, 10.0 * (t - 1.0)) * sin((t - 1.1) * 5.0 * PI)


func _ease_elastic_out(t: float) -> float:
	if t == 0.0 or t == 1.0:
		return t
	return pow(2.0, -10.0 * t) * sin((t - 0.1) * 5.0 * PI) + 1.0


func _ease_elastic_in_out(t: float) -> float:
	if t == 0.0 or t == 1.0:
		return t
	
	t = t * 2.0
	if t < 1.0:
		return -0.5 * pow(2.0, 10.0 * (t - 1.0)) * sin((t - 1.1) * 5.0 * PI)
	else:
		return 0.5 * pow(2.0, -10.0 * (t - 1.0)) * sin((t - 1.1) * 5.0 * PI) + 1.0


## Bounce easing functions
func _ease_bounce_out(t: float) -> float:
	if t < 1.0 / 2.75:
		return 7.5625 * t * t
	elif t < 2.0 / 2.75:
		t -= 1.5 / 2.75
		return 7.5625 * t * t + 0.75
	elif t < 2.5 / 2.75:
		t -= 2.25 / 2.75
		return 7.5625 * t * t + 0.9375
	else:
		t -= 2.625 / 2.75
		return 7.5625 * t * t + 0.984375


func _ease_bounce_in_out(t: float) -> float:
	if t < 0.5:
		return (1.0 - _ease_bounce_out(1.0 - t * 2.0)) * 0.5
	else:
		return _ease_bounce_out(t * 2.0 - 1.0) * 0.5 + 0.5


## Back easing functions
func _ease_back_in(t: float) -> float:
	var s = 1.70158
	return t * t * ((s + 1.0) * t - s)


func _ease_back_out(t: float) -> float:
	var s = 1.70158
	t -= 1.0
	return t * t * ((s + 1.0) * t + s) + 1.0


func _ease_back_in_out(t: float) -> float:
	var s = 1.70158 * 1.525
	t = t * 2.0
	
	if t < 1.0:
		return 0.5 * (t * t * ((s + 1.0) * t - s))
	else:
		t -= 2.0
		return 0.5 * (t * t * ((s + 1.0) * t + s) + 2.0)


## Builder method to set easing
func set_easing(ease_type: EasingType) -> TransformAnimation:
	easing = ease_type
	return self


## Builder method to set shake parameters
func set_shake(intensity: float, frequency: float = 20.0) -> TransformAnimation:
	shake_intensity = intensity
	shake_frequency = frequency
	return self

