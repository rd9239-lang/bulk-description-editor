extends GutTest
## 「つづきから」で第2章の途中に戻れること（時間帯・位置・東の道・つきまとい・遺品）

var main: SliceMain

func before_each():
	DirAccess.remove_absolute("user://save_0.json")
	main = load("res://scenes/island_slice.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

func after_each():
	main.queue_free()
	await get_tree().process_frame
	get_node("/root/GameState").reset()
	TimeOfDay.current = &"night"
	DirAccess.remove_absolute("user://save_0.json")

func _write_save(state_dict: Dictionary) -> void:
	var f := FileAccess.open("user://save_0.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "state": state_dict}))
	f.close()

func test_v3_save_after_chapter1_resumes_in_chapter2():
	_write_save({"chapter": 1, "flags": {"goal_index": 9}, "notebook": []})
	main._start(true)
	await get_tree().process_frame
	assert_eq(main.flow.current_goal(), &"ch2_phone")
	assert_eq(get_node("/root/GameState").chapter, 2)
	assert_eq(TimeOfDay.current, &"dusk")
	assert_true(main.player.global_position.distance_to(Vector3(56.5, 0.1, 6.5)) < 0.5)
	assert_true(main.get_node("East/Barrier").visible, "road still closed before the old man")
	assert_false(main.get_node("Wife").visible)

func test_night_save_resumes_at_night_with_follower_and_open_road():
	_write_save({"chapter": 2, "flags": {"goal_index": 16, "time_of_day": "night", "east_open": true}, "notebook": [], "relics_found": ["watch", "letter"], "relics": 2})
	main._start(true)
	await get_tree().process_frame
	assert_eq(main.flow.current_goal(), &"ch2_power_plant")
	assert_eq(TimeOfDay.current, &"night")
	assert_false(main.get_node("East/Barrier").visible)
	assert_true(main.ch2.follower.active)
	assert_false(main.get_node("Ch2/Returnee").visible)
	assert_eq(get_node("/root/GameState").relics, 2)
	assert_false(main.has_node("Ch2/DeadLampRelic"), "picked relics stay picked")
	assert_false(main.has_node("Ch2/Letter"))

func test_new_game_is_night_even_after_chapter2_session():
	TimeOfDay.current = &"dusk"
	main._start(false)
	await get_tree().process_frame
	assert_eq(TimeOfDay.current, &"night")
	assert_eq(main.flow.current_goal(), &"arrive_pier")

func test_chapter2_card_on_continue():
	_write_save({"chapter": 2, "flags": {"goal_index": 11, "time_of_day": "dusk"}, "notebook": []})
	main._start(true)
	await get_tree().process_frame
	assert_eq(main._card.text, tr("ui_chapter2"))
