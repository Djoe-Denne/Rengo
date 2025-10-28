## Dissolve animation - pixelated transition effect using shader
## LEGACY: Kept for reference, not actively maintained
## Consider using ShaderAnimation for new shader effects
class_name DissolveAnimation
extends VNAnimationNode

## Original material to restore after animation
var _original_material: Material = null

## Dissolve shader material
var _dissolve_material: ShaderMaterial = null

## Target reference (stored during apply_to)
var _target: Variant = null


func _init(p_duration: float = 0.0) -> void:
	super._init(p_duration)


## Applies the dissolve animation to controller
## Uses controller.apply_view_effect() for shader manipulation
func apply_to(target: Variant, progress: float, _delta: float) -> void:
	if not target:
		return
	
	# Target should be a controller
	if not ("view" in target and "apply_view_effect" in target):
		push_warning("DissolveAnimation: target is not a controller with view")
		return
	
	# Store target reference and setup shader on first frame
	if _target != target:
		_target = target
		_setup_shader_via_controller()
	
	# Update dissolve progress via controller
	if _dissolve_material:
		var dissolve_progress = lerp(0.0, 1.0, progress)
		target.apply_view_effect(func(_view):
			if _dissolve_material:
				_dissolve_material.set_shader_parameter("dissolve_value", dissolve_progress)
		)


## Setup dissolve shader via controller
func _setup_shader_via_controller() -> void:
	if not _target or not ("view" in _target):
		return
	
	var view = _target.view
	if not view or not ("scene_node" in view) or not view.scene_node:
		return
	
	var scene_node = view.scene_node
	if not "material" in scene_node:
		push_warning("DissolveAnimation: target scene node does not have material property")
		return
	
	# Store original material
	_original_material = scene_node.material
	
	# Create dissolve shader material
	_dissolve_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float dissolve_value : hint_range(0.0, 1.0) = 0.0;
uniform float pixel_size : hint_range(1.0, 32.0) = 4.0;

void fragment() {
	vec2 uv = UV;
	
	// Pixelate effect
	vec2 pixelated_uv = floor(uv * TEXTURE_PIXEL_SIZE.zw / pixel_size) * pixel_size * TEXTURE_PIXEL_SIZE.xy;
	
	// Sample texture
	vec4 color = texture(TEXTURE, pixelated_uv);
	
	// Dissolve based on brightness threshold
	float brightness = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	if (brightness < dissolve_value) {
		color.a = 0.0;
	}
	
	COLOR = color;
}
"""
	_dissolve_material.shader = shader
	_dissolve_material.set_shader_parameter("dissolve_value", 0.0)
	_dissolve_material.set_shader_parameter("pixel_size", 4.0)
	
	# Apply shader via controller
	_target.apply_view_effect(func(v):
		if "scene_node" in v and v.scene_node and "material" in v.scene_node:
			v.scene_node.material = _dissolve_material
	)


## Setup dissolve shader on target (legacy - kept for compatibility)
func _setup_shader_on_target() -> void:
	if not _target or not ("view" in _target):
		return
	_setup_shader_via_controller()


## Finishes the animation and restores original material via controller
func _finish_animation() -> void:
	super._finish_animation()
	
	# Restore original material via controller
	if _target and "apply_view_effect" in _target:
		var original = _original_material  # Capture for lambda
		_target.apply_view_effect(func(view):
			if "scene_node" in view and view.scene_node and "material" in view.scene_node:
				if original:
					view.scene_node.material = original
				else:
					view.scene_node.material = null
		)

