extends GutTest
## 縦切りの通し確認：目標を順に進め、序章から「第1章 完」まで到達できること。

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

func _talk(npc_name: String, choice := -1) -> void:
	var npc: Interactable = main.get_node(npc_name)
	main._on_interacted(npc)
	while not main.dialogue.visible:
		await get_tree().process_frame
	var guard := 0
	while main.dialogue.visible and guard < 50:
		guard += 1
		if choice >= 0 and not main.dialogue.runner.current().get("choices", []).is_empty():
			main.dialogue.runner.choose(choice)
		else:
			main.dialogue.runner.advance()
		await get_tree().process_frame

func test_full_slice_reaches_end():
	var flow := main.flow
	flow.complete(&"arrive_pier")
	await _talk("Mother")
	assert_eq(flow.current_goal(), &"visit_museum")
	main.notebook.record(&"museum_hi")
	assert_eq(flow.current_goal(), &"go_home")
	main._enter_home()
	assert_eq(flow.current_goal(), &"first_night")
	await _talk("Window")
	assert_eq(flow.current_goal(), &"ask_neighbor")
	assert_eq(get_node("/root/GameState").chapter, 1)
	await _talk("Neighbor")
	await _talk("Wife", 1)
	assert_eq(flow.current_goal(), &"find_regular_lamp")
	assert_false(get_node("/root/GameState").told_wife)
	main.notebook.record(&"sos_a")
	main.notebook.record(&"sos_a_radio")
	assert_eq(flow.current_goal(), &"slice_end")

func test_inactive_goal_npc_does_not_talk():
	main._on_interacted(main.get_node("Neighbor"))
	await get_tree().process_frame
	assert_false(main.dialogue.visible)

func test_telling_wife_leads_to_confession():
	var flow := main.flow
	while flow.current_goal() != &"talk_wife":
		flow.complete(flow.current_goal())
	await _talk("Wife", 0)
	assert_eq(main._pending_ending, &"confession")
	assert_true(main._overlay.visible)

func test_sos_lamp_is_perceived_through_home_window():
	main.player.global_position = Vector3(55.2, 0.1, 5.0)
	for i in 3:
		await get_tree().physics_frame
	var lamp: Streetlight = main.get_node("Street/LampSOS")
	var target := lamp.signal_point()
	main.player.look_at(Vector3(target.x, main.player.global_position.y, target.z))
	var head: Node3D = main.player.get_node("Head")
	head.rotation.x = atan2(target.y - head.global_position.y, Vector2(target.x - head.global_position.x, target.z - head.global_position.z).length())
	for i in 3:
		await get_tree().physics_frame
	var obs: SignalObserver = main.player.get_node("SignalObserver")
	assert_true(obs._perceives(main.player.get_node("Head/Camera3D"), lamp))

func test_double_interact_starts_dialogue_once():
	main.flow.complete(&"arrive_pier")
	var starts := [0]
	main.dialogue.runner.line_changed.connect(func(n): if n.get("text_key") == "d_mother_1": starts[0] += 1)
	main._on_interacted(main.get_node("Mother"))
	main._on_interacted(main.get_node("Mother"))
	await get_tree().create_timer(2.0).timeout
	assert_eq(starts[0], 1)

func _press_interact() -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	get_viewport().push_input(ev)
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	get_viewport().push_input(up)

## 実際のキー入力（E）で人に話しかけ、会話を最後まで進められること（不具合の再現テスト）
func test_talk_with_real_key_presses_until_end():
	main.flow.complete(&"arrive_pier")
	var mother: Node3D = main.get_node("Mother")
	main.player.global_position = Vector3(11, 0.1, 1.6)
	main.player.look_at(Vector3(11, 0.1, 3.0))
	main.player.get_node("Head").rotation.x = deg_to_rad(-15)
	for i in 5:
		await get_tree().physics_frame
	_press_interact()
	var wait := 0.0
	while not main.dialogue.visible and wait < 3.0:
		wait += 0.1
		await get_tree().create_timer(0.1).timeout
	assert_true(main.dialogue.visible, "dialogue opened")
	var guard := 0
	while main.dialogue.visible and guard < 20:
		guard += 1
		_press_interact()
		await get_tree().process_frame
	assert_false(main.dialogue.visible, "dialogue finished with E presses")
	assert_true(main.player.input_enabled, "player can move again")
	assert_eq(main.flow.current_goal(), &"visit_museum")

## ラジオを初めて調べたときのヒント会話も、E キーで最後まで進められること
func test_radio_hint_dialogue_with_real_key_presses():
	var box: Node3D = main.get_node("RadioBox")
	main.player.global_position = Vector3(55.15, 0.1, 5.6)
	main.player.look_at(Vector3(box.global_position.x, main.player.global_position.y, box.global_position.z))
	var head: Node3D = main.player.get_node("Head")
	for i in 3:
		await get_tree().physics_frame
	head.rotation.x = atan2(box.global_position.y - head.global_position.y, Vector2(box.global_position.x - head.global_position.x, box.global_position.z - head.global_position.z).length())
	for i in 5:
		await get_tree().physics_frame
	_press_interact()
	await get_tree().process_frame
	assert_true(main.dialogue.visible, "hint opened")
	var freq: float = main.radio.tuned_freq
	var guard := 0
	while main.dialogue.visible and guard < 10:
		guard += 1
		_press_interact()
		await get_tree().process_frame
	assert_false(main.dialogue.visible, "hint closed")
	assert_eq(main.radio.tuned_freq, freq, "pressing E to read the hint does not retune")
	assert_true(main.player.input_enabled)
