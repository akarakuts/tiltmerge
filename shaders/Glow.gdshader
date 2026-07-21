// Glow.gdshader — мягкое свечение + лёгкий «candy» rim для кубиков.
shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 0.6);
uniform float glow_intensity : hint_range(0.0, 3.0) = 0.8;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float edge = max(
        smoothstep(0.82, 1.0, UV.x) + smoothstep(0.82, 1.0, 1.0 - UV.x),
        smoothstep(0.82, 1.0, UV.y) + smoothstep(0.82, 1.0, 1.0 - UV.y)
    );
    edge = clamp(edge, 0.0, 1.0);
    // Тёплый блик сверху-слева
    float shine = smoothstep(0.55, 0.0, length(UV - vec2(0.32, 0.28)));
    col.rgb += glow_color.rgb * edge * glow_intensity;
    col.rgb += vec3(1.0, 1.0, 1.0) * shine * 0.22;
    COLOR = col;
}
