extends GutTest

var state: GameStateData
var nb: Notebook
var obs: SignalObserver

func before_each():
	state = GameStateData.new()
	nb = Notebook.new()
	nb.state = state
	nb.defs = SignalDef.load_all("res://data/signals.json")
	obs = SignalObserver.new()
	obs.notebook = nb
	obs.set_cycle(&"sos_a", 1000)

func after_each():
	obs.free(); nb.free(); state.free()

func test_94_percent_is_not_enough():
	obs.tick(940, [&"sos_a"])
	assert_eq(state.notebook.size(), 0)

func test_95_percent_records():
	obs.tick(940, [&"sos_a"])
	obs.tick(10, [&"sos_a"])
	assert_eq(state.notebook.size(), 1)

func test_any_starting_point_works():
	# 周期の途中から見始めても、1周期ぶん見れば記録される（周期の切れ目は関係ない）
	obs.tick(400, [&"sos_a"])
	obs.tick(600, [&"sos_a"])
	assert_eq(state.notebook.size(), 1)

func test_short_look_away_keeps_progress():
	obs.tick(500, [&"sos_a"])
	obs.tick(1000, [])
	obs.tick(460, [&"sos_a"])
	assert_eq(state.notebook.size(), 1)

func test_long_look_away_resets_progress():
	obs.tick(500, [&"sos_a"])
	obs.tick(1600, [])
	obs.tick(460, [&"sos_a"])
	assert_eq(state.notebook.size(), 0)

func test_progress_and_current_target():
	obs.tick(475, [&"sos_a"])
	assert_almost_eq(obs.progress(&"sos_a"), 0.5, 0.01)
	assert_eq(obs.current_target(), &"sos_a")
	obs.tick(10, [])
	assert_eq(obs.current_target(), &"")

func test_observed_signal_fires_each_full_watch():
	var seen := []
	obs.observed.connect(func(id): seen.append(id))
	obs.tick(960, [&"sos_a"])
	obs.tick(960, [&"sos_a"])
	assert_eq(seen, [&"sos_a", &"sos_a"])
	assert_eq(state.notebook.size(), 1)

func test_unknown_cycle_never_records():
	obs.tick(99999, [&"museum_hi"])
	assert_eq(state.notebook.size(), 0)

func test_source_added_later_gets_its_cycle():
	var o := SignalObserver.new()
	o.notebook = nb
	add_child(o)
	await get_tree().process_frame
	await get_tree().process_frame
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	var taps := FingerTaps.new()
	taps.signal_id = &"oldman_nigero"
	add_child(taps)
	taps.global_position = Vector3(0, 0, -1)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_gt(o.progress(&"oldman_nigero"), 0.0, "late source is observed")
	o.queue_free(); cam.queue_free(); taps.queue_free()
