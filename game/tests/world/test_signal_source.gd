extends GutTest

func _src(text := "SOS", pause := 1000) -> SignalSource:
	var d := SignalDef.new()
	d.id = &"t"
	d.text = text
	d.fist = Fist.trap()
	d.loop_pause_ms = pause
	var s := SignalSource.new()
	s.configure(d)
	return s

func test_states_follow_timeline_at_boundaries():
	var s := _src("E", 1000)   # 200 on, 1000 off
	assert_true(s.is_on)
	s.advance(199)
	assert_true(s.is_on)
	s.advance(1)
	assert_false(s.is_on)
	s.advance(999)
	assert_false(s.is_on)
	s.advance(1)
	assert_true(s.is_on)
	s.free()

func test_advance_crossing_many_segments():
	var s := _src("SOS", 1000)
	s.advance(1000 + 600 + 300)   # S(1000) + 文字間(600) + O の最初の線の途中
	assert_true(s.is_on)
	s.free()

func test_cycle_completed_once_per_cycle():
	var s := _src("E", 1000)
	var count := [0]
	s.cycle_completed.connect(func(_id): count[0] += 1)
	s.advance(1199)
	assert_eq(count[0], 0)
	s.advance(1)
	assert_eq(count[0], 1)
	s.advance(1200)
	assert_eq(count[0], 2)
	s.free()

func test_low_fps_keeps_every_flash():
	var s := _src("SOS", 1000)
	var rises := 0
	var prev := false
	var t := 0
	while t < s.cycle_length_ms():
		if s.is_on and not prev:
			rises += 1
		prev = s.is_on
		s.advance(100)
		t += 100
	assert_eq(rises, 9)
	s.free()

func test_paused_tree_does_not_advance():
	var s := _src("E", 1000)
	add_child(s)
	get_tree().paused = true
	for i in 5:
		await get_tree().process_frame
	assert_eq(s.phase_ms, 0)
	get_tree().paused = false
	s.queue_free()
