shader_type spatial;

void vertex() {
	// If X scale is negative, flip the normal vector
	if (MODEL_MATRIX[0][0] < 0.0) {
		NORMAL = -NORMAL;
		TANGENT = -TANGENT;
		BINORMAL = -BINORMAL;
		}
}