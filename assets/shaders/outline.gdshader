shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled;

// Outline shader - adds a colored outline around the sprite
// Works with next_pass chaining

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	// Sample the input texture
	vec4 input_color = texture(screen_texture, SCREEN_UV);
	
	// Output: show input color where it exists, outline where edges are detected
	if (input_color.a == 0.0) {
		ALBEDO = (0.0, 0.0, 0.0);
		ALPHA = 1.0;
	} else {
		ALBEDO = input_color.rgb;
		ALPHA = input_color.a;
	}
}

