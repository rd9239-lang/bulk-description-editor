extends GutTest

func test_buses_exist_after_setup():
	AudioMixer.ensure_buses()
	for b in ["Outdoor", "Indoor", "SFX"]:
		assert_true(AudioServer.get_bus_index(b) >= 0, b)

func test_indoor_muffles_outdoor_and_raises_room():
	AudioMixer.ensure_buses()
	var out := AudioServer.get_bus_index("Outdoor")
	var ind := AudioServer.get_bus_index("Indoor")
	AudioMixer.set_indoor(true)
	assert_true(AudioServer.is_bus_effect_enabled(out, 0))
	assert_true(AudioServer.get_bus_volume_db(out) < -6.0)
	assert_true(AudioServer.get_bus_volume_db(ind) > -1.0)
	AudioMixer.set_indoor(false)
	assert_false(AudioServer.is_bus_effect_enabled(out, 0))
	assert_almost_eq(AudioServer.get_bus_volume_db(out), 0.0, 0.01)
	assert_true(AudioServer.get_bus_volume_db(ind) < -20.0)

func test_loop_streams_are_looping():
	var s := AudioMixer.load_loop("res://assets/audio/amb_waves.ogg")
	assert_true(s is AudioStreamOggVorbis and s.loop)

func test_horn_delay_range():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 50:
		assert_between(Ambience.next_horn_delay(rng), 35.0, 80.0)

func test_scene_ambience_and_interiors():
	var scene = load("res://scenes/island_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var amb := scene.get_node_or_null("Ambience") as Ambience
	assert_true(amb != null)
	if amb:
		for n in ["Waves", "Wind", "RoomTone", "Horn"]:
			assert_true(amb.get_node_or_null(n) != null, n)
		assert_true(amb.find_children("Insects*", "", false, false).size() >= 4)
		assert_eq((amb.get_node("Waves") as AudioStreamPlayer3D).bus, &"Outdoor")
		assert_eq((amb.get_node("RoomTone") as AudioStreamPlayer).bus, &"Indoor")
	assert_true(scene.get_node("House_Home").get_node_or_null("Interior") is Area3D)
	scene.set_player_indoor(true)
	assert_true(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Outdoor")) < -6.0)
	scene.set_player_indoor(false)
	scene.queue_free()
