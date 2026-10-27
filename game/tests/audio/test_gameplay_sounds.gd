extends GutTest

func test_surface_from_meta_and_ancestors():
	var body := StaticBody3D.new()
	body.set_meta("surface", "wood")
	var shape := CollisionShape3D.new()
	body.add_child(shape)
	assert_eq(Footsteps.surface_for(body), "wood")
	assert_eq(Footsteps.surface_for(shape), "wood")
	var plain := StaticBody3D.new()
	assert_eq(Footsteps.surface_for(plain), "gravel")
	assert_eq(Footsteps.surface_for(null), "gravel")
	body.free(); plain.free()

func test_step_timing_matches_head_bob():
	assert_eq(Footsteps.step_index(0.0), 0)
	assert_eq(Footsteps.step_index(0.27), 0)
	assert_eq(Footsteps.step_index(0.28), 1)
	assert_eq(Footsteps.step_index(0.56), 2)

func test_footstep_streams_exist_for_all_surfaces():
	for s in Footsteps.SURFACES:
		for i in Footsteps.VARIATIONS:
			assert_true(Footsteps.stream_for(s, i) is AudioStream, "%s %d" % [s, i])

func test_level_surfaces_are_tagged():
	var scene = load("res://scenes/island_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	assert_eq(Footsteps.surface_for(scene.get_node("Road")), "asphalt")
	assert_eq(Footsteps.surface_for(scene.get_node("Pier")), "wood")
	assert_eq(Footsteps.surface_for(scene.get_node("Ground")), "gravel")
	assert_eq(Footsteps.surface_for(scene.get_node("AlleyPave")), "asphalt")
	var floors: Array = scene.get_node("House_Home").find_children("*", "StaticBody3D", true, false).filter(func(b): return b.has_meta("surface"))
	assert_true(floors.size() > 0 and floors[0].get_meta("surface") == "tatami")
	scene.queue_free()

func _signal_lamp() -> Streetlight:
	var d := SignalDef.new()
	d.id = &"t"
	d.text = "E"
	d.fist = Fist.trap()
	d.loop_pause_ms = 500
	var l := Streetlight.new()
	l.configure(d)
	return l

func test_signal_lamp_buzzes_only_when_lit_and_clicks_on_toggle():
	var l := _signal_lamp()
	add_child(l)
	var buzz := l.find_child("Buzz", true, false) as AudioStreamPlayer3D
	var relay := l.find_child("Relay", true, false) as AudioStreamPlayer3D
	assert_true(buzz != null and relay != null)
	assert_true(buzz.playing)
	l.advance(200)  # 点灯 → 消灯
	assert_false(buzz.playing)
	assert_true(relay.playing)
	l.advance(500)  # 再び点灯
	assert_true(buzz.playing)
	l.queue_free()

func test_steady_lamp_has_no_relay():
	var l := Streetlight.new()
	add_child(l)
	assert_true(l.find_child("Buzz", true, false) != null)
	assert_true(l.find_child("Relay", true, false) == null)
	l.queue_free()

func test_scare_plays_stinger():
	var sd := ScareDirector.new()
	add_child(sd)
	sd.load_scares("res://data/scares.json")
	sd.on_goal_completed(&"find_regular_lamp")
	var st := sd.get_node_or_null("Stinger") as AudioStreamPlayer
	assert_true(st != null and st.playing)
	sd.queue_free()

func test_notebook_plays_page_sound_when_opened():
	var nb := Notebook.new()
	nb.state = GameStateData.new()
	add_child(nb)
	nb.toggle()
	assert_true((nb.get_node("PageSound") as AudioStreamPlayer).playing)
	nb.toggle()
	nb.state.free()
	nb.queue_free()

func test_radio_uses_indoor_bus():
	var r := Radio.new()
	add_child(r)
	var p := r.find_children("*", "AudioStreamPlayer3D", false, false)[0] as AudioStreamPlayer3D
	assert_eq(p.bus, &"Indoor")
	r.queue_free()
