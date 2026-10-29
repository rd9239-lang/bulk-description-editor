extends GutTest
## 第2章の通し確認：夕方の自宅から、老人・寮・廃墟・電話・発電所・停電・窓の写真を経て「第二章 おわり」まで。

var main: SliceMain

func before_each():
	DirAccess.remove_absolute("user://save_0.json")
	main = load("res://scenes/island_slice.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._start(false)
	await get_tree().process_frame
	main.ch2.blackout_hold = 0.05
	main.ch2.blackout_interval = 0.02

func after_each():
	main.queue_free()
	await get_tree().process_frame
	get_node("/root/GameState").reset()
	TimeOfDay.current = &"night"

## 目標を直接その手前まで進め、手前の目標を完了させる（章や時間帯の切り替えも本物の流れで起きる）
func _jump_to(goal: StringName) -> void:
	var idx := ChapterFlow.GOALS.find(goal)
	get_node("/root/GameState").flags["goal_index"] = idx - 1
	main.flow.complete(ChapterFlow.GOALS[idx - 1])
	await _wait_until(func(): return not main._overlay.visible and TimeOfDay.current == ChapterFlow.time_of_day_for(idx), 5.0)
	await _finish_dialogue()

func _wait_until(cond: Callable, sec: float) -> bool:
	var t := 0.0
	while not cond.call() and t < sec:
		await get_tree().process_frame
		t += get_process_delta_time()
	return cond.call()

func _finish_dialogue() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var guard := 0
	while main.dialogue.visible and guard < 60:
		guard += 1
		main.dialogue.runner.advance()
		await get_tree().process_frame
		await get_tree().process_frame

func _talk_node(node: Node, choice := -1) -> void:
	await _finish_dialogue()
	node.interact(null)
	var opened := await _wait_until(func(): return main.dialogue.visible, 4.0)
	assert_true(opened, "dialogue opened for %s (goal=%s)" % [node.name, main.flow.current_goal()])
	var guard := 0
	while main.dialogue.visible and guard < 60:
		guard += 1
		if choice >= 0 and not main.dialogue.runner.current().get("choices", []).is_empty():
			main.dialogue.runner.choose(choice)
		else:
			main.dialogue.runner.advance()
		await get_tree().process_frame
	await get_tree().process_frame

func _talk(path: String, choice := -1) -> void:
	await _talk_node(main.get_node(path), choice)

func _interact_event() -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	return ev

func test_chapter2_reaches_end():
	var gs: GameStateData = get_node("/root/GameState")
	await _jump_to(&"ch2_phone")
	assert_eq(TimeOfDay.current, &"dusk")
	assert_eq(gs.chapter, 2)
	assert_true(main.player.global_position.distance_to(Chapter2.HOME_POS) < 1.0, "woke up at home")
	assert_false(main.get_node("Wife").visible, "wife is away")
	await _talk("Ch2/Phone")
	assert_eq(gs.phone, [&"bank_address"] as Array[StringName])
	await _talk("Ch2/Kettle")
	await _talk("Ch2/DeadLampRelic")
	assert_eq(gs.relics, 1)
	assert_eq(main.flow.current_goal(), &"ch2_old_man")
	await _talk("Ch2/OldMan")
	assert_false(main.get_node("East/Barrier").visible)
	await _talk("Ch2/Returnee", 0)
	assert_true(main.ch2.follower.active)
	assert_false(main.get_node("Ch2/Returnee").visible, "he left the dorm to follow")
	await _talk("Ch2/NoticeBoard")
	await _talk("Ch2/Letter")
	assert_eq(gs.relics, 2)
	await _wait_until(func(): return TimeOfDay.current == &"night" and not main._overlay.visible, 5.0)
	assert_eq(main.flow.current_goal(), &"ch2_call_mother")
	assert_eq(TimeOfDay.current, &"night")
	main._enter_home()
	var opened := await _wait_until(func(): return main.dialogue.visible, 3.0)
	assert_true(opened, "call to mother starts at home")
	await _finish_dialogue()
	await _wait_until(func(): return main.flow.current_goal() == &"ch2_power_plant", 2.0)
	await _talk("Ch2/Switchboard")
	assert_eq(main.flow.current_goal(), &"ch2_earphone")
	assert_true(main.has_node("Ch2/Earphone"))
	main.notebook.record(&"sos_a_earphone")
	opened = await _wait_until(func(): return main.dialogue.visible, 10.0)
	assert_true(opened, "returnee speaks after the lights come back")
	assert_true((main.get_node("East/PlantLamp") as Streetlight)._light.visible)
	assert_true(main.ch2.follower.global_position.distance_to(Chapter2.UNDER_PLANT_LAMP) < 0.5)
	await _finish_dialogue()
	await _talk("Window")
	var shown := await _wait_until(func(): return main.ch2.popup.is_post_open(), 5.0)
	assert_true(shown, "photo post opens")
	assert_eq(gs.phone, [&"bank_address", &"sns_like"] as Array[StringName])
	main.ch2.popup._unhandled_input(_interact_event())
	await _wait_until(func(): return main.dialogue.visible, 2.0)
	await _finish_dialogue()
	assert_eq(main.flow.current_goal(), &"ch2_end")
	assert_true(main.player.input_enabled)

func test_returnee_lines_cycle():
	await _jump_to(&"ch2_ruins")
	for i in 5:
		await _talk_node(main.ch2.follower.body)
	assert_eq(get_node("/root/GameState").flags.get("follow_line"), 5)

func test_blackout_waits_for_open_dialogue():
	await _jump_to(&"ch2_earphone")
	main.dialogue.open("res://data/dialogue/ch2.json", "memo")
	main.notebook.record(&"sos_a_earphone")
	await get_tree().create_timer(2.0).timeout
	assert_eq(main.dialogue.runner.current().get("text_key"), "d_memo", "memo stays open")
	main.dialogue.runner.advance()
	var opened := await _wait_until(func(): return main.dialogue.visible, 3.0)
	assert_true(opened)
	assert_eq(main.dialogue.runner.current().get("text_key"), "d_returnee_back")

func test_relic_is_picked_once_and_removed():
	await _jump_to(&"ch2_dead_lamp")
	await _talk("Ch2/DeadLampRelic")
	await get_tree().process_frame
	assert_eq(get_node("/root/GameState").relics, 1)
	assert_false(main.has_node("Ch2/DeadLampRelic"), "picked relic is gone")

func test_chapter2_people_absent_before_chapter2():
	assert_false(main.get_node("Ch2/OldMan").visible)
	assert_false(main.get_node("Ch2/Memo").visible)
	assert_false(main.ch2.follower.active)
	assert_true(main.get_node("East/Barrier").visible)
