// bloom_hover_pass3.gdshader
// Pass 3: Vertical Blur with Outward Bias and Animation
shader_type canvas_item;
render_mode blend_premul_alpha;

uniform sampler2D BASE_TEXTURE;
uniform float blur_amount : hint_range(0.0, 30.0, 0.5) = 12.0;
uniform float blur_quality : hint_range(3.0, 20.0, 1.0) = 9.0;
uniform float outward_bias : hint_range(0.0, 2.0, 0.1) = 0.3;
uniform float time_offset : hint_range(0.0, 100.0, 0.1) = 0.0;

void fragment() {
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 pixel_size = 1.0 / tex_size;
    
    vec4 color = vec4(0.0);
    float total_weight = 0.0;
    
    // Get direction from sprite center
    vec2 from_center = UV - vec2(0.5);
    float angle = atan(from_center.y, from_center.x);
    vec2 outward_dir = vec2(cos(angle), sin(angle));
    
    // Animate blur for breathing effect
    float animated_blur = blur_amount * (1.0 + 0.2 * sin(TIME * 2.0 + time_offset));
    float sigma = animated_blur / 3.0;
    int samples = int(blur_quality);
    
    // Gaussian blur - vertical pass with outward bias
    for (int i = -samples; i <= samples; i++) {
        float weight = exp(-0.5 * float(i * i) / (sigma * sigma));
        
        // Add outward bias to positive samples
        if (i > 0) {
            weight *= (1.0 + outward_bias);
        }
        
        vec2 offset = vec2(0.0, float(i) * pixel_size.y);
        
        // Bend the blur outward
        offset += outward_dir * abs(float(i)) * pixel_size * outward_bias * 0.5;
        
        color += textureLod(TEXTURE, UV + offset, 0.0) * weight;
        total_weight += weight;
    }
    
    COLOR = color / total_weight;
}