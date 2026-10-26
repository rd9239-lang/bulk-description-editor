extends GutTest

const DIR := "user://test_saves_flow"
var state: GameStateData
var saver: SaveSystemNode
var flow: ChapterFlow

func before_each():
	state = GameStateData.new()
	saver = SaveSystemNode.new()
	saver.save_dir = DIR
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	flow = ChapterFlow.new()
	flow.state = state
	flow.saver = saver
	flow.begin()

func after_each():
	flow.free(); saver.free(); state.free()

func _run_to(goal: StringName):
	while flow.current_goal() != goal:
		flow.complete(flow.current_goal())

func test_starts_at_pier():
	assert_eq(flow.current_goal(), &"arrive_pier")

func test_goals_only_advance_in_order():
	flow.complete(&"greet_mother")
	assert_eq(flow.current_goal(), &"arrive_pier")
	flow.complete(&"arrive_pier")
	assert_eq(flow.current_goal(), &"greet_mother")

func test_museum_signal_completes_visit():
	_run_to(&"visit_museum")
	flow.on_signal_recorded(&"museum_hi")
	assert_eq(flow.current_goal(), &"go_home")

func test_lamp_and_radio_signals():
	_run_to(&"find_regular_lamp")
	flow.on_signal_recorded(&"sos_a_radio")
	assert_eq(flow.current_goal(), &"find_regular_lamp")
	flow.on_signal_recorded(&"sos_a")
	assert_eq(flow.current_goal(), &"radio_night")
	flow.on_signal_recorded(&"sos_a_radio")
	assert_eq(flow.current_goal(), &"slice_end")

func test_chapter_change_saves():
	_run_to(&"first_night")
	assert_false(saver.has_save(0))
	flow.complete(&"first_night")
	assert_eq(state.chapter, 1)
	assert_true(saver.has_save(0))

func test_location_entry_saves():
	flow.on_location_entered(&"home")
	assert_true(saver.has_save(0))

func test_telling_wife_triggers_confession():
	var got := [&""]
	flow.ending_triggered.connect(func(id): got[0] = id)
	state.set_value("told_wife", true)
	assert_eq(got[0], &"confession")

func test_resume_from_saved_goal():
	_run_to(&"ask_neighbor")
	var f2 := ChapterFlow.new()
	f2.state = state
	f2.saver = saver
	f2.begin()
	assert_eq(f2.current_goal(), &"ask_neighbor")
	f2.free()

func test_goal_completed_signal():
	var got := []
	flow.goal_completed.connect(func(id): got.append(id))
	flow.complete(&"arrive_pier")
	assert_eq(got, [&"arrive_pier"])
