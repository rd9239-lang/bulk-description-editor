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
