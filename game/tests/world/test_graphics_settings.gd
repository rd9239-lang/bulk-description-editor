extends GutTest

func test_high_quality_environment():
	var e := GraphicsSettings.build_environment(&"high")
	assert_true(e.volumetric_fog_enabled)
	assert_true(e.ssr_enabled)
	assert_true(e.ssao_enabled)
	assert_true(e.glow_enabled)
	assert_eq(e.tonemap_mode, Environment.TONE_MAPPER_ACES)
	assert_eq(e.background_mode, Environment.BG_SKY)
	assert_true(e.sky.sky_material is ShaderMaterial)

func test_low_quality_environment_drops_heavy_effects():
	var e := GraphicsSettings.build_environment(&"low")
	assert_false(e.volumetric_fog_enabled)
	assert_false(e.ssr_enabled)
	assert_false(e.ssao_enabled)
	assert_true(e.glow_enabled)
	assert_true(e.fog_enabled)

func test_lamp_shadows_follow_quality():
	var l := SpotLight3D.new()
	GraphicsSettings.configure_lamp(l, &"high")
	assert_true(l.shadow_enabled)
	GraphicsSettings.configure_lamp(l, &"low")
	assert_false(l.shadow_enabled)
	l.free()

func test_head_bob_is_zero_when_standing_still():
	assert_eq(Player.bob_offset(1.234, 0.0), Vector2.ZERO)

func test_head_bob_is_small_when_walking():
	for i in 20:
		var o := Player.bob_offset(i * 0.05, Player.WALK)
		assert_true(absf(o.y) <= 0.04 and absf(o.x) <= 0.025)
	assert_ne(Player.bob_offset(0.1, Player.WALK), Vector2.ZERO)
