extends GutTest

func after_each():
	TimeOfDay.current = &"night"

func test_dusk_environment_differs_from_night():
	var d := GraphicsSettings.build_environment(&"high", &"dusk")
	var n := GraphicsSettings.build_environment(&"high", &"night")
	assert_gt(d.tonemap_exposure, n.tonemap_exposure)
	assert_lt(d.fog_density, n.fog_density)
	assert_gt(d.fog_light_color.r, d.fog_light_color.b, "warm haze at dusk")
	assert_almost_eq(float((d.sky.sky_material as ShaderMaterial).get_shader_parameter("dusk")), 1.0, 0.001)
	assert_almost_eq(float((n.sky.sky_material as ShaderMaterial).get_shader_parameter("dusk")), 0.0, 0.001)

func test_default_is_night():
	var e := GraphicsSettings.build_environment(&"high")
	assert_almost_eq(e.tonemap_exposure, 1.7, 0.001)

func test_apply_switches_moon_and_remembers():
	var main := Node3D.new()
	var we := WorldEnvironment.new()
	we.name = "WorldEnv"
	main.add_child(we)
	var moon := DirectionalLight3D.new()
	moon.name = "Moon"
	main.add_child(moon)
	add_child(main)
	TimeOfDay.apply(main, &"dusk")
	assert_eq(TimeOfDay.current, &"dusk")
	assert_gt(moon.light_color.r, moon.light_color.b)
	assert_almost_eq(float((we.environment.sky.sky_material as ShaderMaterial).get_shader_parameter("dusk")), 1.0, 0.001)
	TimeOfDay.apply(main, &"night")
	assert_gt(moon.light_color.b, moon.light_color.r)
	assert_eq(TimeOfDay.current, &"night")
	main.queue_free()
