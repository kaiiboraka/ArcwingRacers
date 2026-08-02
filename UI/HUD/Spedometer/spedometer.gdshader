shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Pass 1: Clip to parent shape texture
    vec4 base_tex = texture(TEXTURE, UV);
    
    // Pass 2: Clip to screen buffer (subtract sliding child shapes)
    vec4 screen_color = texture(screen_texture, SCREEN_UV);
    
    // Combine both clipping passes
    COLOR = vec4(base_tex.rgb, base_tex.a * screen_color.a);
}