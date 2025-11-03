shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled;

// Outline shader - adds a colored outline around the sprite
// Works with next_pass chaining

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D albedo_texture : hint_albedo_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 screen_uv = SCREEN_UV;
	vec2 uv = UV;
	
    // Test : moitié inférieure de l'écran
    if (uv.y > 0.5) {
        ALBEDO = vec3(0.0, 1.0, 0.0); // vert
        ALPHA = 1.0;
    } else {
		vec4 input_color = texture(screen_texture, screen_uv);
        ALBEDO = input_color.rgb;
        ALPHA = input_color.a;
    }

}

