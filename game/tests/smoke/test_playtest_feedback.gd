extends GutTest
## 試遊の感想（点滅に気づきにくい／見分けにくい／人影に気づかない／部屋のノイズ）への対応

var main: SliceMain

func before_each():
	DirAccess.remove_absolute("user://save_0.json")
	main = load("res://scenes/island_slice.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._start(false)
	await get_tree().process_frame

func after_each():
	main.queue_free()
	await get_tree().process_frame
	get_node("/root/GameState").reset()

func test_sos_lamp_is_cool_white_and_others_are_warm():
	var sos: Streetlight = main.get_node("Street/LampSOS")
	var other: Streetlight = main.get_node("Street/Lamp20")
	assert_true(sos.light_color.b > sos.light_color.r, "SOS lamp is bluish white")
	assert_true(other.light_color.r > other.light_color.b, "other lamps stay warm")

func test_daughter_signal_is_slow_enough_to_follow():
	assert_true(Fist.daughter_a().unit_ms >= 300.0)

func test_observe_hud_shows_while_watching_a_signal():
	var obs: SignalObserver = main.player.get_node("SignalObserver")
	obs.set_cycle(&"sos_a", 10000)
	obs.tick(3000, [&"sos_a"])
	main._update_observe_hud()
	assert_true(main._observe_box.visible)
	assert_almost_eq(main._observe_bar.value, 3000.0 / 9500.0, 0.02)
	obs.tick(10, [])
	main._update_observe_hud()
	assert_false(main._observe_box.visible)

func test_toast_when_recorded():
	main.notebook.record(&"museum_hi")
	assert_true(main._toast.visible)
	assert_true(main._toast.text.contains("N"))

func test_monologue_once_when_sos_first_watched():
	var obs: SignalObserver = main.player.get_node("SignalObserver")
	obs.observed.emit(&"sos_a")
	await get_tree().process_frame
	assert_true(main.dialogue.visible)
	assert_eq(main.dialogue.runner.current().get("text_key"), "d_notice_sos")
	while main.dialogue.visible:
		main.dialogue.runner.advance()
		await get_tree().process_frame
	obs.observed.emit(&"sos_a")
	await get_tree().process_frame
	assert_false(main.dialogue.visible, "monologue only once")

func test_radio_is_silent_until_switched_on():
	assert_false(main.radio.powered)
	main._tune_radio()
	assert_true(main.radio.powered)
	assert_eq(main.radio.tuned_freq, 76.0, "first press only switches it on")

func test_figure_appears_after_delay_and_plays_stinger():
	var lamp: Streetlight = main.get_node("Street/LampSOS")
	main.scares.appear_delay = 0.2
	main.scares.on_goal_completed(&"find_regular_lamp")
	var fig := lamp.find_child("Figure", true, false) as Node3D
	assert_true(fig != null, "figure created")
	assert_false(fig.visible, "not visible before the delay")
	# 見ていないうちは姿を見せない
	main.player.camera.look_at(fig.global_position + Vector3(0, 1.2, 40))
	await get_tree().create_timer(0.3).timeout
	_lamp_on(lamp)
	main.scares._process(0.016)
	assert_false(fig.visible, "stays hidden while the player looks elsewhere")
	assert_true(main.scares.get_node_or_null("Stinger") == null, "no sound before it is seen")
	# 路地の入口から街灯を見ると、灯りが点いた瞬間に姿を見せて音が鳴る
	main.player.global_position = Vector3(55, 0.1, -1)
	main.player.camera.look_at(fig.global_position + Vector3(0, 1.2, 0))
	await get_tree().physics_frame
	_lamp_on(lamp)
	main.scares._process(0.016)
	assert_true(fig.visible, "visible when the lamp is on and in view")
	assert_true((main.scares.get_node("Stinger") as AudioStreamPlayer).playing)
	var mi := fig as MeshInstance3D
	assert_true(mi != null and not (mi.mesh is CapsuleMesh), "humanoid silhouette")

func test_figure_vanishes_after_player_looks_away():
	var lamp: Streetlight = main.get_node("Street/LampSOS")
	main.scares.appear_delay = 0.0
	main.player.global_position = Vector3(55, 0.1, -1)
	main.scares.on_goal_completed(&"find_regular_lamp")
	var fig := lamp.find_child("Figure", true, false) as Node3D
	main.player.camera.look_at(fig.global_position + Vector3(0, 1.2, 0))
	await get_tree().physics_frame
	_lamp_on(lamp)
	main.scares._process(0.016)
	assert_true(fig.visible)
	main.player.camera.look_at(fig.global_position + Vector3(0, 1.2, 40))
	_lamp_on(lamp)
	main.scares._process(0.5)
	assert_true(fig.is_queued_for_deletion(), "gone once the player looks away")

func _lamp_on(lamp: Streetlight) -> void:
	lamp.advance(lamp.cycle_length_ms() - lamp.phase_ms)  # 周期の頭（点灯）へ
	assert_true(lamp.is_on, "lamp lit at the start of the cycle")
