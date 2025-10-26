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


## Applies the dissolve animation to target
func apply_to(target: Variant, progress: float, _delta: float) -> void:
	if not target or not target.scene_node:
		return
	
	# Store target reference
	if _target != target:
		_target = target
		_setup_shader_on_target()
	
	# Update dissolve progress
	if _dissolve_material:
		var dissolve_progress = lerp(0.0, 1.0, progress)
		_dissolve_material.set_shader_parameter("dissolve_value", dissolve_progress)


## Setup dissolve shader on target
func _setup_shader_on_target() -> void:
	if not _target or not _target.scene_node:
		return
	
	var scene_node = _target.scene_node
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
	
	scene_node.material = _dissolve_material


## Finishes the animation and restores original material
func _finish_animation() -> void:
	super._finish_animation()
	
	# Restore original material
	if _target and _target.scene_node and "material" in _target.scene_node:
		if _original_material:
			_target.scene_node.material = _original_material
		else:
			_target.scene_node.material = null

