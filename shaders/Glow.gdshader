// Glow.gdshader — мягкое свечение для кубиков (rim light).
// Применяется как material на Polygon2D Visual кубика.
shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 0.6);
uniform float glow_intensity : hint_range(0.0, 3.0) = 0.8;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    // rim: ярче у краёв (UV ~ 0 или 1)
    float edge = max(
        smoothstep(0.85, 1.0, UV.x) + smoothstep(0.85, 1.0, 1.0 - UV.x),
        smoothstep(0.85, 1.0, UV.y) + smoothstep(0.85, 1.0, 1.0 - UV.y)
    );
    edge = clamp(edge, 0.0, 1.0);
    col.rgb += glow_color.rgb * edge * glow_intensity;
    COLOR = col;
}
