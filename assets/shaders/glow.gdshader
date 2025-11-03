shader_type spatial;
render_mode unshaded, blend_add, depth_draw_opaque, cull_disabled;

// Glow shader - adds an emission-based glow effect
// Works with next_pass chaining

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.5, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.8;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D albedo_texture : hint_albedo_texture, repeat_disable, filter_nearest;

void fragment() {
    vec2 uv = UV;

    // Test : moitié supérieure de l'écran
    if (uv.y <= 0.5) {
        ALBEDO = vec3(1.0, 0.0, 0.0); // rouge
        ALPHA = 1.0;
    } else {
		vec4 input_color = texture(albedo_texture, uv);
        ALBEDO = input_color.rgb;
        ALPHA = input_color.a;
    }
}
