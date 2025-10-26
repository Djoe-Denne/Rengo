## Dissolve animation - pixelated transition effect using shader
class_name DissolveAnimation
extends VNAnimationNode

## Original material to restore after animation
var _original_material: Material = null

## Dissolve shader material
var _dissolve_material: ShaderMaterial = null


func _init(p_target: ResourceNode = null, p_duration: float = 0.0) -> void:
	super._init(p_target, p_duration)


## Setup dissolve shader
func _setup_animation() -> void:
	if not target_node or not "material" in target_node:
		push_warning("DissolveAnimation: target node does not have material property")
		return
	
	# Store original material
	_original_material = target_node.material
	
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
	
	target_node.material = _dissolve_material
	
	# Setup default values
	from_value = target_node.scene_node.modulate.a
	to_value = 1.0 - from_value


## Process dissolve animation
func _process_animation(progress: float, _delta: float) -> void:
	if not target_node or not _dissolve_material:
		return
	
	var dissolve_progress = lerp(float(from_value), float(to_value), progress)
	_dissolve_material.set_shader_parameter("dissolve_value", dissolve_progress)


## Restore original material
func _apply_final_value() -> void:
	if not target_node:
		return
	
	# Restore original material if we have one
	if _original_material:
		target_node.material = _original_material
	else:
		target_node.material = null


## Restore material on loop
func _on_loop() -> void:
	if _dissolve_material:
		_dissolve_material.set_shader_parameter("dissolve_value", float(from_value))

