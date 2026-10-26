extends GutTest

func _truth_state() -> GameStateData:
	var s := GameStateData.new()
	s.followed_signal = &"real"
	s.found_daughter = true
	s.relics = 5
	s.old_man_alive = true
	return s

func after_each():
	pass

func test_truth():
	var s := _truth_state()
	assert_eq(EndingResolver.resolve(s), &"truth")
	s.free()

func test_confession_wins_over_truth():
	var s := _truth_state()
	s.told_wife = true
	assert_eq(EndingResolver.resolve(s), &"confession")
	s.free()

func test_trap_wins_even_if_daughter_found():
	var s := _truth_state()
	s.followed_signal = &"trap"
	assert_eq(EndingResolver.resolve(s), &"next_blink")
	s.free()

func test_alone_when_daughter_not_found():
	var s := _truth_state()
	s.found_daughter = false
	assert_eq(EndingResolver.resolve(s), &"alone")
	s.free()

func test_nameless_when_relics_missing():
	var s := _truth_state()
	s.relics = 4
	assert_eq(EndingResolver.resolve(s), &"nameless")
	s.free()

func test_nameless_when_old_man_dead():
	var s := _truth_state()
	s.old_man_alive = false
	assert_eq(EndingResolver.resolve(s), &"nameless")
	s.free()
