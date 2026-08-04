shader_type spatial;

// Tell the engine to process BOTH sides so nothing gets clipped out
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

//uniform vec4 wing_color : source_color = vec4(0.0, 0.6, 1.0, 0.3);
//uniform vec4 glow_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
//uniform float glow_intensity : hint_range(0.0, 10.0) = 2.0;
//uniform float roughness : hint_range(0.0, 1.0) = 0.1;
//uniform float metallic : hint_range(0.0, 1.0) = 0.1;

void vertex() {
	// If the model cluster is negatively scaled along the X axis,
	// Godot's MODEL_MATRIX determinant becomes negative.
	// We force the vertex normals to face outwards to correct the winding shift.
	if (determinant(MODEL_MATRIX) < 0.0) {
		NORMAL = -NORMAL;
	}
}

void fragment() {
	// Built-in FRONT_FACING tells us if the renderer thinks we are looking at the back.
	// Since our vertices are flipped, if it thinks it's a backface, it's actually our front!
	vec3 corrected_normal = NORMAL;
	if (!FRONT_FACING) {
		corrected_normal = -NORMAL;
	}

	// Apply glass parameters using the corrected normal layout
	//ALBEDO = wing_color.rgb;
	//ALPHA = wing_color.a;
	//ROUGHNESS = roughness;
	//METALLIC = metallic;
	
	// Re-establish your glassy glow/emission track smoothly
	//EMISSION = glow_color.rgb * glow_intensity;
	
	// Pass the corrected lighting vectors to Godot's internal fragment buffer
	NORMAL = corrected_normal;
}
