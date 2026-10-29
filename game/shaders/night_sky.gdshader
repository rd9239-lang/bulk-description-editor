// 夜空：地平線から天頂へのグラデーション、瞬く星、月とその暈（かさ）。
// dusk=1 で曇りの夕方：暗い橙の地平線、灰色がかった紺の天頂、西の低い位置に雲ごしの太陽のにじみ。星と月は消える。
shader_type sky;

uniform vec3 zenith : source_color = vec3(0.004, 0.006, 0.016);
uniform vec3 horizon : source_color = vec3(0.028, 0.032, 0.048);
uniform vec3 moon_dir = vec3(-0.35, 0.42, -0.84);
uniform float star_density = 0.003;
uniform float dusk = 0.0;
const vec3 DUSK_HORIZON = vec3(0.42, 0.22, 0.12);
const vec3 DUSK_ZENITH = vec3(0.1, 0.12, 0.18);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = EYEDIR;
	float h = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(mix(horizon, DUSK_HORIZON, dusk), mix(zenith, DUSK_ZENITH, dusk), pow(h, 0.45));
	float night = 1.0 - dusk;
	float r = hash(floor(d * 380.0));
	float star = step(1.0 - star_density, r) * smoothstep(0.02, 0.25, d.y);
	col += vec3(0.75, 0.8, 1.0) * star * (0.55 + 0.45 * sin(TIME * 1.7 + r * 60.0)) * night;
	float m = dot(d, normalize(moon_dir));
	col += vec3(0.95, 0.96, 1.0) * smoothstep(0.99935, 0.99965, m) * 2.5 * night;
	col += vec3(0.22, 0.27, 0.42) * pow(max(m, 0.0), 120.0) * 0.5 * night;
	vec3 sun_dir = normalize(vec3(-1.0, 0.08, 0.2));
	col += vec3(1.0, 0.55, 0.3) * pow(max(dot(d, sun_dir), 0.0), 8.0) * 0.35 * dusk;
	COLOR = col;
}
