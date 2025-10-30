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
	
	// Get texture size for pixel offset calculation
	vec2 texture_size = vec2(textureSize(screen_texture, 0));
	vec2 pixel_size = 1.0 / texture_size;
	
	// Sample surrounding pixels to detect edges
	float outline = 0.0;
	
	// Check 8 directions around current pixel
	for (float y = -1.0; y <= 1.0; y += 1.0) {
		for (float x = -1.0; x <= 1.0; x += 1.0) {
			if (x == 0.0 && y == 0.0) continue;
			
			vec2 offset = vec2(x, y) * pixel_size * outline_width;
			vec4 sample_color = texture(screen_texture, SCREEN_UV + offset);
			
			// If we sample a pixel with alpha but current pixel has no alpha, we're on an edge
			if (sample_color.a > 0.1 && input_color.a < 0.1) {
				outline = 1.0;
			}
		}
	}
	
	// Output: show input color where it exists, outline where edges are detected
	if (input_color.a > 0.1) {
		ALBEDO = input_color.rgb;
		ALPHA = input_color.a;
	} else if (outline > 0.0) {
		ALBEDO = outline_color.rgb;
		ALPHA = outline_color.a;
	} else {
		ALPHA = 0.0;
	}
}

