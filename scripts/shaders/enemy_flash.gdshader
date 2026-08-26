shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Color to invert (default black)
uniform float tolerance : hint_range(0.0, 1.0) = 0.1;               // How close the match needs to be


void fragment() {
	vec4 current_color = texture(TEXTURE, UV);
    
// Check how close the current pixel is to the target color
	float diff = distance(current_color.rgb, target_color.rgb);
    
	if (diff < tolerance) {
		// Invert only the RGB channels, keep alpha intact
		COLOR = vec4(1.0 - current_color.rgb, current_color.a);
	} else {
		// Leave the pixel unchanged
		COLOR = current_color;
	}
}
