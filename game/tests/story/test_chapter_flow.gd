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
	assert_eq(flow.current_goal(), &"ch2_phone")

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

func test_goal_for_already_recorded_signal_completes_on_arrival():
	# プロローグで窓から SOS を記録済みでも、第1章の目標で詰まらないこと
	state.notebook.append({"signal_id": &"sos_a", "label_key": "sig_sos_a", "decoded": true})
	_run_to(&"talk_wife")
	flow.complete(&"talk_wife")
	assert_eq(flow.current_goal(), &"radio_night")

func test_entering_chapter2_sets_dusk_and_saves():
	var tods := []
	flow.time_of_day_changed.connect(func(t): tods.append(t))
	var chapters := []
	flow.chapter_changed.connect(func(c): chapters.append(c))
	_run_to(&"ch2_phone")
	assert_eq(state.chapter, 2)
	assert_eq(state.flags.get("time_of_day"), "dusk")
	assert_true(saver.has_save(0))
	assert_eq(tods, [&"dusk"])
	assert_eq(chapters, [1, 2])

func test_night_starts_at_call_mother():
	var tods := []
	flow.time_of_day_changed.connect(func(t): tods.append(t))
	_run_to(&"ch2_call_mother")
	assert_eq(state.flags.get("time_of_day"), "night")
	assert_eq(tods, [&"dusk", &"night"])
	assert_eq(ChapterFlow.GOALS[ChapterFlow.NIGHT_START], &"ch2_call_mother")
	assert_eq(ChapterFlow.time_of_day_for(ChapterFlow.NIGHT_START - 1), &"dusk")
	assert_eq(ChapterFlow.time_of_day_for(ChapterFlow.CHAPTER2_START), &"dusk")
	assert_eq(ChapterFlow.time_of_day_for(0), &"night")
	assert_eq(ChapterFlow.time_of_day_for(ChapterFlow.NIGHT_START), &"night")

func test_ruins_needs_board_and_letter():
	_run_to(&"ch2_ruins")
	state.set_value("read_board", true)
	assert_eq(flow.current_goal(), &"ch2_ruins")
	state.relics_found.append(&"letter")
	state.changed.emit()
	assert_eq(flow.current_goal(), &"ch2_call_mother")

func test_ruins_letter_first_then_board():
	_run_to(&"ch2_ruins")
	state.relics_found.append(&"letter")
	state.changed.emit()
	assert_eq(flow.current_goal(), &"ch2_ruins")
	state.set_value("read_board", true)
	assert_eq(flow.current_goal(), &"ch2_call_mother")

func test_earphone_signal_completes_goal():
	_run_to(&"ch2_earphone")
	flow.on_signal_recorded(&"sos_a_earphone")
	assert_eq(flow.current_goal(), &"ch2_window")

func test_end_is_terminal():
	_run_to(&"ch2_end")
	flow.complete(&"ch2_end")
	assert_eq(flow.current_goal(), &"ch2_end")
