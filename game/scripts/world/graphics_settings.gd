## 画質の設定。高：ボリュメトリックフォグ・映り込み・陰影・影あり／低：重い効果を切る。
class_name GraphicsSettings
extends RefCounted

const SKY_SHADER := preload("res://shaders/night_sky.gdshader")

static var quality: StringName = &"high"

static func build_environment(q: StringName) -> Environment:
	var high := q == &"high"
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = SKY_SHADER
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.27, 0.4)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.7
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.045, 0.055, 0.08)
	env.fog_density = 0.006 if high else 0.02
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.82
	env.volumetric_fog_enabled = high
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(0.85, 0.88, 0.95)
	env.volumetric_fog_anisotropy = 0.45
	env.volumetric_fog_length = 48.0
	env.volumetric_fog_ambient_inject = 0.35
	env.ssr_enabled = high
	env.ssr_max_steps = 64
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssr_depth_tolerance = 0.2
	env.ssao_enabled = high
	env.ssao_radius = 0.9
	env.ssao_intensity = 1.6
	return env

## 街灯・室内灯の影とフォグへの寄与
static func configure_lamp(light: Light3D, q: StringName) -> void:
	light.shadow_enabled = q == &"high"
	light.light_volumetric_fog_energy = 4.0
