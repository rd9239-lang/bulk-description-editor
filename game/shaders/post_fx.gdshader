// 画面効果：周辺減光、フィルムの粒子、わずかな色ずれ。
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette = 0.4;
uniform float grain = 0.05;
uniform float aberration = 0.0018;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	vec2 off = c * aberration;
	vec3 col = vec3(texture(screen_tex, uv + off).r, texture(screen_tex, uv).g, texture(screen_tex, uv - off).b);
	col *= 1.0 - vignette * smoothstep(0.25, 0.85, length(c) * 1.25);
	col += (rand(uv * vec2(1920.0, 1080.0) + fract(TIME * 7.0) * 113.0) - 0.5) * grain;
	COLOR = vec4(col, 1.0);
}
