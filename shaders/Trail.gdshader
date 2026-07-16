// Trail.gdshader — эффект следа для летящих/катящихся кубиков (опционально).
// Применяется как material на Line2D или отдельном Polygon2D.
shader_type canvas_item;

uniform float alpha : hint_range(0.0, 1.0) = 0.5;
uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    col.a *= alpha;
    col.rgb = mix(col.rgb, tint.rgb, 0.3);
    COLOR = col;
}
