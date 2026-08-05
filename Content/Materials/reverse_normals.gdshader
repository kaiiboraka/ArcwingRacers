shader_type spatial;

render_mode cull_disabled;
uniform sampler2D normal : hint_normal;

void vertex() {

}

void fragment() {
	NORMAL = FRONT_FACING ? NORMAL : NORMAL * -1.;
	NORMAL_MAP = texture(normal, UV).rgb;
}
