shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.6, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;
uniform float pulse_speed : hint_range(0.1, 20.0) = 5.0;

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
	float alpha = texture(TEXTURE, UV).a;
	    
	// Sample neighboring pixels to find edges
	alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
	alpha = clamp(alpha, 0.0, 1.0);
	    
	// Calculate pulse multiplier using sine wave over time
	float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5; // ranges from 0.0 to 1.0
	// Adjust base intensity so it doesn't completely vanish (e.g., 0.3 to 1.0)
	float current_intensity = mix(0.3, 1.0, pulse);
	    
	vec4 final_color = outline_color;
	final_color.a *= current_intensity;
	    
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = mix(final_color, tex_color, tex_color.a);
}