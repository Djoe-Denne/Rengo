## StateChangeAnimation - Fade out → change state → fade in
## Used for smooth character state transitions (pose, expression, outfit)
class_name StateChangeAnimation
extends VNAnimationNode

## Target mode for animation application
enum TargetMode {
	WHOLE_NODE,          # Apply to entire sprite_container (prevents layer bleed-through)
	INDIVIDUAL_LAYERS,   # Apply to each layer independently
	SPECIFIC_LAYERS      # Apply only to specified layers
}

## Fade duration as a fraction of total duration (0.0 to 0.5)
## 0.3 means 30% fade out, 40% middle, 30% fade in
var fade_fraction: float = 0.3

## How to target the animation (default: WHOLE_NODE to prevent layer bleed)
var target_mode: TargetMode = TargetMode.WHOLE_NODE

## Specific layers to target (only used if target_mode is SPECIFIC_LAYERS)
var target_layers: Array = []

## Whether the state has been changed yet
var _state_changed: bool = false

## Original alpha values (can be single value or dictionary of layer: alpha)
var _original_alpha: Variant = 1.0

## Callback to trigger state change at midpoint
var state_change_callback: Callable


func _init(p_duration: float = 0.5, p_fade_fraction: float = 0.3, p_target_mode: TargetMode = TargetMode.WHOLE_NODE) -> void:
	super._init(p_duration)
	fade_fraction = clamp(p_fade_fraction, 0.0, 0.5)
	target_mode = p_target_mode


## Applies the animation to target
func apply_to(target: Variant, progress: float, delta: float) -> void:
	if not target:
		return
	
	# Store original alpha on first frame
	if progress <= 0.0:
		_store_original_alpha(target)
		_state_changed = false
	
	# Calculate which phase we're in
	var fade_in_start = 1.0 - fade_fraction
	var fade_out_end = fade_fraction
	
	var current_alpha: float = 0.0
	
	if progress <= fade_out_end:
		# Phase 1: Fade out
		var fade_progress = progress / fade_out_end
		current_alpha = lerp(1.0, 0.0, fade_progress)
	
	elif progress >= fade_in_start:
		# Phase 3: Fade in
		var fade_progress = (progress - fade_in_start) / fade_fraction
		current_alpha = lerp(0.0, 1.0, fade_progress)
	
	else:
		# Phase 2: Middle (fully faded out, state change happens here)
		current_alpha = 0.0
		
		# Trigger state change callback at midpoint (once)
		if not _state_changed and state_change_callback.is_valid():
			state_change_callback.call()
			_state_changed = true
	
	# Apply alpha based on target mode
	_apply_alpha(target, current_alpha)


## Setup animation
func _setup_animation() -> void:
	_state_changed = false


## Store original alpha values based on target mode
func _store_original_alpha(target: Variant) -> void:
	match target_mode:
		TargetMode.WHOLE_NODE:
			# Store alpha of the entire sprite container
			if "sprite_container" in target and target.sprite_container:
				_original_alpha = target.sprite_container.modulate.a
			elif target.scene_node:
				_original_alpha = target.scene_node.modulate.a
			else:
				_original_alpha = 1.0
		
		TargetMode.INDIVIDUAL_LAYERS:
			# Store alpha of each layer
			_original_alpha = {}
			if "layers" in target and target.layers is Dictionary:
				for layer_name in target.layers:
					var layer = target.layers[layer_name]
					if layer and "modulate" in layer:
						_original_alpha[layer_name] = layer.modulate.a
		
		TargetMode.SPECIFIC_LAYERS:
			# Store alpha of specified layers only
			_original_alpha = {}
			if "layers" in target and target.layers is Dictionary:
				for layer_name in target_layers:
					if layer_name in target.layers:
						var layer = target.layers[layer_name]
						if layer and "modulate" in layer:
							_original_alpha[layer_name] = layer.modulate.a


## Apply alpha value based on target mode
func _apply_alpha(target: Variant, alpha: float) -> void:
	match target_mode:
		TargetMode.WHOLE_NODE:
			# Apply to entire sprite container (prevents layer bleed-through)
			if "sprite_container" in target and target.sprite_container:
				target.sprite_container.modulate.a = alpha
			elif target.scene_node:
				target.scene_node.modulate.a = alpha
		
		TargetMode.INDIVIDUAL_LAYERS:
			# Apply to each layer independently
			if "layers" in target and target.layers is Dictionary:
				for layer_name in target.layers:
					var layer = target.layers[layer_name]
					if layer and "modulate" in layer:
						layer.modulate.a = alpha
		
		TargetMode.SPECIFIC_LAYERS:
			# Apply only to specified layers
			if "layers" in target and target.layers is Dictionary:
				for layer_name in target_layers:
					if layer_name in target.layers:
						var layer = target.layers[layer_name]
						if layer and "modulate" in layer:
							layer.modulate.a = alpha


## Restore original alpha (called at end or when animation is interrupted)
func _restore_original_alpha(target: Variant) -> void:
	match target_mode:
		TargetMode.WHOLE_NODE:
			if _original_alpha is float:
				if "sprite_container" in target and target.sprite_container:
					target.sprite_container.modulate.a = _original_alpha
				elif target.scene_node:
					target.scene_node.modulate.a = _original_alpha
		
		TargetMode.INDIVIDUAL_LAYERS, TargetMode.SPECIFIC_LAYERS:
			if _original_alpha is Dictionary:
				if "layers" in target and target.layers is Dictionary:
					for layer_name in _original_alpha:
						if layer_name in target.layers:
							var layer = target.layers[layer_name]
							if layer and "modulate" in layer:
								layer.modulate.a = _original_alpha[layer_name]


## Builder method to set fade fraction
func set_fade_fraction(fraction: float) -> StateChangeAnimation:
	fade_fraction = clamp(fraction, 0.0, 0.5)
	return self


## Builder method to set target mode
func set_target_mode(mode: TargetMode) -> StateChangeAnimation:
	target_mode = mode
	return self


## Builder method to set specific target layers
func set_target_layers(layers: Array) -> StateChangeAnimation:
	target_layers = layers.duplicate()
	target_mode = TargetMode.SPECIFIC_LAYERS
	return self


## Builder method to set state change callback
func with_state_change(callback: Callable) -> StateChangeAnimation:
	state_change_callback = callback
	return self
