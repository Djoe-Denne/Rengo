shader_type spatial;
render_mode unshaded, blend_add, depth_draw_opaque, cull_disabled;

// Glow shader - adds an emission-based glow effect
// Works with next_pass chaining

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.5, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.8;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	// Sample the input texture (from previous pass or base texture)
	vec4 input_color = texture(screen_texture, SCREEN_UV);
	
	// Calculate glow based on alpha (only glow where sprite exists)
	vec3 glow = glow_color.rgb * intensity * input_color.a;
	
	// Output glow with additive blending
	ALBEDO = glow;
	ALPHA = input_color.a * intensity;
}

