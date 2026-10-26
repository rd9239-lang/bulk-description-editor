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

func after_each():
	obs.free(); nb.free(); state.free()

func test_94_percent_is_not_enough():
	obs.tick(940, [&"sos_a"])
	assert_false(obs.on_cycle_completed(&"sos_a", 1000))
	assert_eq(state.notebook.size(), 0)

func test_95_percent_records():
	obs.tick(950, [&"sos_a"])
	assert_true(obs.on_cycle_completed(&"sos_a", 1000))
	assert_eq(state.notebook.size(), 1)

func test_looking_away_and_back_sums_time():
	obs.tick(500, [&"sos_a"])
	obs.tick(300, [])
	obs.tick(460, [&"sos_a"])
	assert_true(obs.on_cycle_completed(&"sos_a", 1000))

func test_counter_resets_each_cycle():
	obs.tick(960, [&"sos_a"])
	obs.on_cycle_completed(&"sos_a", 1000)
	state.notebook.clear()
	obs.tick(100, [&"sos_a"])
	assert_false(obs.on_cycle_completed(&"sos_a", 1000))
