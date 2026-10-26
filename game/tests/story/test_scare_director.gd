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
