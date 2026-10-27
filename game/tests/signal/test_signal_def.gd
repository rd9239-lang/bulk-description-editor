extends GutTest

func test_loads_game_signals():
	var defs := SignalDef.load_all("res://data/signals.json")
	assert_eq(defs.size(), 4)
	assert_has(defs, &"sos_a")
	assert_has(defs, &"sos_a_radio")
	assert_has(defs, &"museum_hi")
	assert_has(defs, &"oldman_nigero")

func test_sos_a_uses_daughter_fist():
	var defs := SignalDef.load_all("res://data/signals.json")
	assert_eq(defs[&"sos_a"].fist.distance(Fist.daughter_a()), 0.0)
	assert_eq(defs[&"sos_a"].text, "SOS")
	assert_false(defs[&"sos_a"].hidden)

func test_oldman_is_hidden():
	var defs := SignalDef.load_all("res://data/signals.json")
	assert_true(defs[&"oldman_nigero"].hidden)

func test_unknown_fist_is_skipped():
	var defs := SignalDef.load_all("res://tests/fixtures/signals_bad.json")
	assert_eq(defs.size(), 2)
	assert_does_not_have(defs, &"broken")
	assert_eq(defs[&"custom"].fist.unit_ms, 150.0)

func test_cycle_ms_is_timeline_plus_pause():
	var d: SignalDef = SignalDef.load_all("res://data/signals.json")[&"sos_a"]
	var sum := 0
	for ms in d.fist.timeline(d.text, 5):
		sum += ms
	assert_eq(d.cycle_ms(5), sum + 3000)
