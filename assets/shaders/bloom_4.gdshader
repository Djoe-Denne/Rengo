// bloom_hover_pass4.gdshader
// Pass 4: Final Composition with Animated Outward Effects
shader_type canvas_item;
render_mode blend_premul_alpha;

uniform sampler2D BASE_TEXTURE;
uniform float bloom_intensity : hint_range(0.0, 5.0, 0.1) = 1.5;
uniform float pulse_speed : hint_range(0.0, 10.0, 0.1) = 3.0;
uniform float wave_speed : hint_range(0.0, 10.0, 0.1) = 5.0;
uniform float wave_amplitude : hint_range(0.0, 0.5, 0.01) = 0.15;
uniform float noise_strength : hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float radial_wave_speed : hint_range(0.0, 10.0, 0.1) = 4.0;
uniform float flicker_amount : hint_range(0.0, 0.5, 0.01) = 0.15;

// Simple noise function
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Smooth noise
float smooth_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal brownian motion for plasma/fire effect
float fbm(vec2 p, float time) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 2.0;
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * smooth_noise(p * frequency + vec2(time, time * 0.7));
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

void fragment() {
    // Get original texture
    vec4 original = textureLod(BASE_TEXTURE, UV, 0.0);
    
    // Get bloom texture
    vec4 bloom = textureLod(TEXTURE, UV, 0.0);
    
    // Calculate radial direction from center
    vec2 from_center = UV - vec2(0.5);
    float dist_from_center = length(from_center);
    float angle = atan(from_center.y, from_center.x);
    
    // Radial wave animation (expanding outward)
    float radial_wave = sin(dist_from_center * 10.0 - TIME * radial_wave_speed) * 0.5 + 0.5;
    
    // Angular variation for fire-like effect
    float angular_wave = sin(angle * 4.0 + TIME * wave_speed) * 0.5 + 0.5;
    
    // Combine waves
    float combined_wave = radial_wave * 0.6 + angular_wave * 0.4;
    
    // Pulse animation
    float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
    
    // Add plasma-like distortion pushing outward
    vec2 distorted_uv = UV;
    float plasma = fbm(UV * 6.0 + vec2(0.0, TIME * 0.3), TIME * wave_speed);
    
    // Make distortion push outward from center
    vec2 outward_push = normalize(from_center) * plasma * wave_amplitude * bloom.a;
    distorted_uv += outward_push;
    
    // Add turbulence perpendicular to radial direction
    vec2 perpendicular = vec2(-from_center.y, from_center.x) * 0.5;
    distorted_uv += perpendicular * sin(plasma * 6.28318) * wave_amplitude * 0.5 * bloom.a;
    
    // Sample bloom with distortion
    vec4 distorted_bloom = textureLod(TEXTURE, distorted_uv, 0.0);
    
    // Mix based on noise and waves
    bloom = mix(bloom, distorted_bloom, noise_strength);
    bloom *= (1.0 + combined_wave * 0.5);
    
    // Apply pulsing and intensity
    bloom *= pulse * bloom_intensity;
    
    // Add flickering for fire-like effect
    float flicker = 1.0 - flicker_amount + flicker_amount * smooth_noise(vec2(TIME * 20.0, angle));
    bloom *= flicker;
    
    // Add slight color variation based on intensity
    bloom.r *= 1.0 + bloom.a * 0.2;
    bloom.g *= 1.0 - bloom.a * 0.1;
    
    // Composite: original on top of bloom
    // Bloom only appears outside the sprite
    if (original.a > 0.1) {
        COLOR = original;
    } else {
        COLOR = bloom;
    }
    
    // Ensure bloom extends the alpha channel
    COLOR.a = max(original.a, bloom.a);
}