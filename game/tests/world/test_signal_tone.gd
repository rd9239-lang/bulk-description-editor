extends GutTest

func test_signal_tone_loop_matches_timeline():
	var tl := PackedInt32Array([100, 100, 300])
	var wav := SignalTone.make_loop(tl, 500, 600.0, 22050)
	assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	var frames := wav.data.size() / 2
	assert_eq(frames, int(22050 * 1.0))
	assert_eq(wav.loop_end, frames)
	var peak_on := 0
	var peak_off := 0
	for i in range(int(0.02 * 22050), int(0.08 * 22050)):
		peak_on = maxi(peak_on, absi(wav.data.decode_s16(i * 2)))
	for i in range(int(0.12 * 22050), int(0.18 * 22050)):
		peak_off = maxi(peak_off, absi(wav.data.decode_s16(i * 2)))
	assert_gt(peak_on, 5000)
	assert_eq(peak_off, 0)

func test_unpowered_radio_plays_nothing():
	var r := Radio.new()
	r.signal_id = &"sos_a_radio"
	add_child(r)
	await get_tree().process_frame
	for p in r.find_children("*", "AudioStreamPlayer3D", true, false):
		assert_false((p as AudioStreamPlayer3D).playing)
	r.power_on()
	await get_tree().process_frame
	assert_true((r.get_node("Tone") as AudioStreamPlayer3D).playing)
	assert_true(r.get_node("Tone").stream is AudioStreamWAV)
	r.queue_free()

func test_earphone_plays_only_near_the_wire():
	var e := EarphoneSignal.new()
	e.signal_id = &"sos_a_earphone"
	add_child(e)
	e.global_position = Vector3(0, 0, -100)
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	await get_tree().process_frame
	assert_false((e.get_node("Tone") as AudioStreamPlayer).playing)
	e.global_position = Vector3(0, 0, -1)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true((e.get_node("Tone") as AudioStreamPlayer).playing)
	assert_true(e.get_node("Tone").stream is AudioStreamWAV)
	e.queue_free(); cam.queue_free()
