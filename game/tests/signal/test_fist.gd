extends GutTest

func test_trap_sos_exact():
	var t := Fist.trap().timeline("E", 1)
	assert_eq(Array(t), [200])

func test_starts_on_and_alternates():
	var t := Fist.trap().timeline("SOS", 1)
	assert_eq(t.size(), 17)
	assert_eq(t[0], 200)
	assert_eq(t[1], 200)
	assert_eq(t[5], 600)

func test_deterministic_with_seed():
	assert_eq(Fist.daughter_a().timeline("SOS", 7), Fist.daughter_a().timeline("SOS", 7))

func test_jitter_changes_lengths():
	assert_ne(Fist.daughter_a().timeline("SOS", 7), Fist.daughter_a().timeline("SOS", 8))

func test_min_duration():
	var f := Fist.daughter_a()
	f.jitter = 5.0
	for ms in f.timeline("SOS", 3):
		assert_true(ms >= 30)

func test_a_vs_b_is_subtle():
	assert_between(Fist.daughter_a().distance(Fist.captive_b()), 0.1, 0.5)

func test_a_vs_trap_is_clear():
	assert_true(Fist.daughter_a().distance(Fist.trap()) >= 1.0)
