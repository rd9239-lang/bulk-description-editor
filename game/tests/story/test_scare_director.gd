extends GutTest

func test_plays_matching_scare_once():
	var sd := ScareDirector.new()
	sd.load_scares("res://data/scares.json")
	var played := []
	sd.scare_played.connect(func(id): played.append(id))
	sd.on_goal_completed(&"ask_neighbor")
	assert_eq(played.size(), 0)
	sd.on_goal_completed(&"find_regular_lamp")
	sd.on_goal_completed(&"find_regular_lamp")
	assert_eq(played, ["ch1_figure"])
	sd.free()

func test_custom_kinds_are_handed_off_once():
	var sd := ScareDirector.new()
	add_child(sd)
	var got := []
	sd.custom_scare.connect(func(s): got.append(s["kind"]))
	sd.on_goal_completed(&"ch2_earphone")
	sd.on_goal_completed(&"ch2_earphone")
	sd.on_goal_completed(&"ch2_window")
	assert_eq(got, ["blackout", "window_photo"])
	assert_true(sd.get_node_or_null("Stinger") == null, "blackout plays its own sound later")
	sd.queue_free()

func test_play_sound_helper_plays_stinger():
	var sd := ScareDirector.new()
	add_child(sd)
	sd.play_sound("stinger")
	assert_true((sd.get_node("Stinger") as AudioStreamPlayer).playing)
	sd.queue_free()
