extends GutTest

func test_radio_starts_switched_off():
	var r := Radio.new()
	assert_false(r.powered)
	r.power_on()
	assert_true(r.powered)
	r.free()

func test_power_off_silences_radio():
	var r := Radio.new()
	r.signal_id = &"sos_a_radio"
	add_child(r)
	r.power_on()
	await get_tree().process_frame
	assert_true((r.get_node("Tone") as AudioStreamPlayer3D).playing)
	r.power_off()
	assert_false(r.powered)
	assert_false((r.get_node("Tone") as AudioStreamPlayer3D).playing)
	assert_false((r.get_node("Static") as AudioStreamPlayer3D).playing)
	r.queue_free()
