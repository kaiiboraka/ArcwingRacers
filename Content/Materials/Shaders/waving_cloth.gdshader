shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;

uniform float amplitude_u = 0.05;
uniform float frequency_u = 62.83185307179586 ; // = 10 * 2PI; 
uniform float speed_u = 5.0;

uniform float amplitude_v = 0.05;
uniform float frequency_v = 10.0;
uniform float speed_v = 2.0;

// toon shading stuff
uniform sampler2D albedo_tex : source_color;
uniform vec4 tint : source_color = vec4(1.0);
uniform float shade_levels = 3.0;

float get_height(vec2 uv, float weight) {
    float phase_u = TIME * speed_u + uv.x * frequency_u;
    float phase_v = TIME * speed_v + uv.y * frequency_v;

    float wave_u = sin(phase_u);
    float wave_v = sin(phase_v);

    return (wave_u * amplitude_u + wave_v * amplitude_v) * weight;
}

float get_dh_du(vec2 uv, float color) {
    float phase_u = TIME * speed_u + uv.x * frequency_u;
    return cos(phase_u) * frequency_u * amplitude_u * color;
}

float get_dh_dv(vec2 uv, float color) {
    float phase_v = TIME * speed_v + uv.y * frequency_v;
    return cos(phase_v) * frequency_v * amplitude_v * color;
}

void vertex() {
	float height = get_height(UV, COLOR.x);
	VERTEX += NORMAL * height;
}

void fragment() {
    // wave function derivates
    float dh_du = get_dh_du(UV, COLOR.r);
    float dh_dv = get_dh_dv(UV, COLOR.r);

    // rebuild normal from tangent and binormal
    vec3 T = normalize(TANGENT);
    vec3 B = normalize(BINORMAL);
    vec3 N = normalize(NORMAL);
    vec3 new_normal = normalize(
        N 
        - T * dh_du 
        - B * dh_dv
    );
    NORMAL = new_normal;

    // albedo
    vec3 albedo = texture(albedo_tex, UV).rgb * tint.rgb;
    ALBEDO = albedo;
}

void light() {
    float ndl = max(dot(NORMAL, LIGHT), 0.0);
    float toon = floor(ndl * shade_levels) / shade_levels;
    DIFFUSE_LIGHT += ALBEDO * toon * LIGHT_COLOR;
}
