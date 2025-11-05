## StateChangeAnimation - Fade out → change state → fade in
## Used for smooth character state transitions (pose, expression, outfit)
class_name StateChangeAnimation
extends VNAnimationNode

## Target mode for animation application
enum TargetMode {
	WHOLE_NODE,          # Apply to entire output_mesh (prevents layer bleed-through)
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


## Applies the animation to controller
## Uses controller.apply_view_effect() for visual fading
func apply_to(target: Variant, progress: float, delta: float) -> void:
	if not target:
		return
	
	# Target should be a controller
	if not ("view" in target and "apply_view_effect" in target):
		push_warning("StateChangeAnimation: target is not a controller with view")
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
	
	# Apply alpha using controller's view effect method
	_apply_alpha_via_controller(target, current_alpha)


## Setup animation
func _setup_animation() -> void:
	_state_changed = false


## Store original alpha values based on target mode
## Target is a controller, we access its view
func _store_original_alpha(controller: Variant) -> void:
	var view = controller.view if "view" in controller else null
	if not view:
		_original_alpha = 1.0
		return
	
	match target_mode:
		TargetMode.WHOLE_NODE:
			# Store alpha of the output mesh
			if "output_mesh" in view and view.output_mesh:
				_original_alpha = _get_alpha_from_node(view.output_mesh)
			elif "scene_node" in view and view.scene_node:
				_original_alpha = _get_alpha_from_node(view.scene_node)
			else:
				_original_alpha = 1.0
		
		TargetMode.INDIVIDUAL_LAYERS:
			# Store alpha of each layer
			_original_alpha = {}
			if "layers" in view and view.layers is Dictionary:
				for layer_name in view.layers:
					var layer = view.layers[layer_name]
					if layer:
						_original_alpha[layer_name] = _get_alpha_from_node(layer)
		
		TargetMode.SPECIFIC_LAYERS:
			# Store alpha of specified layers only
			_original_alpha = {}
			if "layers" in view and view.layers is Dictionary:
				for layer_name in target_layers:
					if layer_name in view.layers:
						var layer = view.layers[layer_name]
						if layer:
							_original_alpha[layer_name] = _get_alpha_from_node(layer)


## Apply alpha value via controller's view effect
func _apply_alpha_via_controller(controller: Variant, alpha: float) -> void:
	# Use controller.apply_view_effect() to manipulate the view
	match target_mode:
		TargetMode.WHOLE_NODE:
			# Apply to entire output mesh (prevents layer bleed-through)
			controller.apply_view_effect(func(view):
				if "output_mesh" in view and view.output_mesh:
					_set_alpha_on_node(view.output_mesh, alpha)
				elif "scene_node" in view and view.scene_node:
					_set_alpha_on_node(view.scene_node, alpha)
			)
		
		TargetMode.INDIVIDUAL_LAYERS:
			# Apply to each layer independently
			controller.apply_view_effect(func(view):
				if "layers" in view and view.layers is Dictionary:
					for layer_name in view.layers:
						var layer = view.layers[layer_name]
						if layer:
							_set_alpha_on_node(layer, alpha)
			)
		
		TargetMode.SPECIFIC_LAYERS:
			# Apply only to specified layers
			var layers_to_update = target_layers.duplicate()  # Capture for lambda
			controller.apply_view_effect(func(view):
				if "layers" in view and view.layers is Dictionary:
					for layer_name in layers_to_update:
						if layer_name in view.layers:
							var layer = view.layers[layer_name]
							if layer:
								_set_alpha_on_node(layer, alpha)
			)


## Restore original alpha via controller (called at end or when animation is interrupted)
func _restore_original_alpha(controller: Variant) -> void:
	match target_mode:
		TargetMode.WHOLE_NODE:
			if _original_alpha is float:
				var original = _original_alpha  # Capture for lambda
				controller.apply_view_effect(func(view):
					if "output_mesh" in view and view.output_mesh:
						_set_alpha_on_node(view.output_mesh, original)
					elif "scene_node" in view and view.scene_node:
						_set_alpha_on_node(view.scene_node, original)
				)
		
		TargetMode.INDIVIDUAL_LAYERS, TargetMode.SPECIFIC_LAYERS:
			if _original_alpha is Dictionary:
				var original_dict = _original_alpha.duplicate()  # Capture for lambda
				controller.apply_view_effect(func(view):
					if "layers" in view and view.layers is Dictionary:
						for layer_name in original_dict:
							if layer_name in view.layers:
								var layer = view.layers[layer_name]
								if layer:
									_set_alpha_on_node(layer, original_dict[layer_name])
				)


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


## Helper to get alpha from both 2D and 3D nodes
func _get_alpha_from_node(node: Node) -> float:
	if node is Node2D:
		return node.modulate.a if "modulate" in node else 1.0
	elif node is MeshInstance3D:
		if node.material_override:
			return node.material_override.albedo_color.a
		return 1.0
	elif node is Node3D:
		# For Node3D containers, check first child MeshInstance3D
		for child in node.get_children():
			if child is MeshInstance3D and child.material_override:
				return child.material_override.albedo_color.a
		return 1.0
	return 1.0


## Helper to set alpha on both 2D and 3D nodes
func _set_alpha_on_node(node: Node, alpha: float) -> void:
	if node is Node2D:
		# 2D node - use modulate
		if "modulate" in node:
			node.modulate.a = alpha
	elif node is MeshInstance3D:
		# 3D mesh - set material alpha
		if node.material_override:
			node.material_override.albedo_color.a = alpha
	elif node is Node3D:
		# 3D container - set alpha on all MeshInstance3D children
		for child in node.get_children():
			if child is MeshInstance3D and child.material_override:
				child.material_override.albedo_color.a = alpha
