extends GutTest

## 200ms 単位で点・線に見立てて文字列化する（テスト用）
func _as_morse(p: PackedInt32Array) -> String:
	var out := ""
	for i in p.size():
		var units := roundi(p[i] / 200.0)
		if i % 2 == 0:
			out += "." if units <= 1 else "-"
		elif units >= 7:
			out += " / "
		elif units >= 3:
			out += " "
	return Morse.decode(out)

func test_pattern_is_deterministic():
	assert_eq(Flicker.pattern(3, 20000), Flicker.pattern(3, 20000))

func test_pattern_length_covers_requested():
	var sum := 0
	for ms in Flicker.pattern(5, 20000):
		sum += ms
	assert_true(sum >= 20000)

func test_never_looks_like_sos():
	for seed in 100:
		assert_false(_as_morse(Flicker.pattern(seed, 20000)).contains("SOS"), "seed %d" % seed)

func test_radio_reception_curve():
	var r := Radio.new()
	r.station_freq = 81.7
	for pair in [[81.7, 1.0], [82.0, 1.0], [83.2, 0.0], [82.6, 0.5]]:
		r.tuned_freq = pair[0]
		assert_almost_eq(r.reception(), pair[1], 0.01, str(pair))
	r.free()
