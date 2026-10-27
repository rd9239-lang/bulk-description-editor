extends GutTest

func test_radio_starts_switched_off():
	var r := Radio.new()
	assert_false(r.powered)
	r.power_on()
	assert_true(r.powered)
	r.free()
