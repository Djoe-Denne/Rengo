shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = vec4(1.0 - tex_color.rgb, tex_color.a);
}


//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
