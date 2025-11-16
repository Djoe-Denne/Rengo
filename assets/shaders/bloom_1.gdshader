// bloom_hover.gdshader
// Pass 1: Outward Edge Detection and Expansion
shader_type canvas_item;
render_mode blend_premul_alpha;

uniform float edge_threshold : hint_range(0.01, 1.0, 0.01) = 0.1;
uniform float expand_radius : hint_range(1.0, 20.0, 0.5) = 300.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float glow_falloff : hint_range(0.5, 4.0, 0.1) = 2.0;

void fragment() {
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 pixel_size = 1.0 / tex_size;
    
    // Sample the current pixel
    vec4 center = textureLod(TEXTURE, UV, 0.0);
    
    float glow_intensity = 0.0;
    
    // Only process if we're outside the sprite
    if (center.a <= edge_threshold) {
        // We're outside the sprite - check distance to nearest sprite pixel
        float min_distance = expand_radius;
        float found_edge = 0.0;
        
        // Sample in expanding circles to find nearest sprite edge
        int samples = int(expand_radius);
        for (int r = 1; r <= samples; r++) {
            float radius = float(r);
            int angle_samples = min(r * 4, 16); // More samples for larger radii
            
            for (int a = 0; a < angle_samples; a++) {
                float angle = (float(a) / float(angle_samples)) * 6.28318;
                vec2 offset = vec2(cos(angle), sin(angle)) * radius * pixel_size;
                
                float sample_alpha = textureLod(TEXTURE, UV + offset, 0.0).a;
                
                if (sample_alpha > edge_threshold) {
                    min_distance = min(min_distance, radius);
                    found_edge = 1.0;
                }
            }
            
            // Early exit if we found an edge close enough
            if (found_edge > 0.0 && radius > min_distance + 2.0) {
                break;
            }
        }
        
        // Calculate glow intensity based on distance
        if (found_edge > 0.0) {
            float normalized_dist = min_distance / expand_radius;
            glow_intensity = pow(1.0 - normalized_dist, glow_falloff);
        }
    }
    
    // Output the glow
    COLOR = glow_color * glow_intensity;
    COLOR.a *= glow_intensity;
}