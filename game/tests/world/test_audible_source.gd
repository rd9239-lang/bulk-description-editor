extends GutTest

func test_heard_only_within_range():
	var s := FingerTaps.new()
	s.signal_id = &"oldman_nigero"
	add_child(s)
	s.global_position = Vector3.ZERO
	assert_true(s.heard_from(Vector3(2.9, 0, 0)))
	assert_false(s.heard_from(Vector3(3.1, 0, 0)))
	s.queue_free()

func test_radio_is_audible_source_and_needs_power():
	var r := Radio.new()
	r.signal_id = &"sos_a_radio"
	add_child(r)
	r.tuned_freq = r.station_freq
	assert_true(r is AudibleSource)
	assert_false(r.heard_from(r.global_position))
	r.power_on()
	assert_true(r.heard_from(r.global_position + Vector3(5.9, 0, 0)))
	assert_false(r.heard_from(r.global_position + Vector3(6.1, 0, 0)))
	r.tuned_freq = r.station_freq + 1.0
	assert_false(r.heard_from(r.global_position), "poor reception")
	r.queue_free()

func test_earphone_signal_defined():
	var defs := SignalDef.load_all("res://data/signals.json")
	assert_true(defs.has(&"sos_a_earphone"))
	var d: SignalDef = defs[&"sos_a_earphone"]
	assert_false(d.hidden)
	assert_eq(d.text, "SOS")

func test_earphone_volume_grows_near_the_wire():
	var e := EarphoneSignal.new()
	e.signal_id = &"sos_a_earphone"
	add_child(e)
	e.global_position = Vector3.ZERO
	assert_eq(e.hearing_range, 2.5)
	var near := e.loudness_at(Vector3(0.5, 0, 0))
	var mid := e.loudness_at(Vector3(4.0, 0, 0))
	var far := e.loudness_at(Vector3(6.0, 0, 0))
	assert_gt(near, mid)
	assert_eq(far, 0.0)
	e.queue_free()

func test_observer_counts_finger_taps_only_when_close():
	var obs := SignalObserver.new()
	add_child(obs)
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	var s := FingerTaps.new()
	s.signal_id = &"oldman_nigero"
	add_child(s)
	s.global_position = Vector3(0, 0, -2)
	assert_true(obs._perceives(cam, s))
	s.global_position = Vector3(0, 0, -5)
	assert_false(obs._perceives(cam, s))
	obs.queue_free(); cam.queue_free(); s.queue_free()

func test_knock_has_ship_rhythm():
	assert_eq(Knock.SHIP, [0.0, 0.3, 0.6, 1.6])
	var w := Knock.make_stream(Knock.SHIP)
	assert_gt(w.data.size(), int(1.6 * Knock.RATE) * 2)
