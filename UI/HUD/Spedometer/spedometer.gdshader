shader_type canvas_item;
uniform sampler2D mask;

void fragment() {
    COLOR = texture(TEXTURE, UV);
    COLOR.a *= texture(mask, UV).a;   // fill only shows where a blob is
}