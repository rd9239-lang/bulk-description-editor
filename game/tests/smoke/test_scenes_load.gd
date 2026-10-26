extends GutTest

func test_player_scene_instantiates():
	var p = load("res://scenes/parts/player.tscn").instantiate()
	assert_true(p is Player)
	assert_true(p.get_node("Head/Camera3D/Interactor") is Interactor)
	assert_true(p.get_node("SignalObserver") is SignalObserver)
	p.free()

func test_dialogue_box_builds():
	var b := DialogueBox.new()
	add_child(b)
	assert_false(b.visible)
	b.queue_free()

func test_island_slice_builds():
	var scene = load("res://scenes/island_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	assert_true(scene.get_node_or_null("Street/LampSOS") is Streetlight)
	assert_eq(scene.get_node("Street/LampSOS").signal_id, &"sos_a")
	assert_true(scene.get_node_or_null("House_Home") != null)
	assert_true(scene.get_node_or_null("Radio") is Radio)
	scene.queue_free()

func test_polyhaven_props_placed_with_collision():
	var scene = load("res://scenes/island_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	for n in ["PropTable", "PropLaptop", "PropDrawer", "PropCrate", "PropFood", "PropCrateJikka"]:
		var p: Node3D = scene.get_node_or_null(n)
		assert_true(p != null, n)
		if p == null:
			continue
		assert_true(p.find_children("*", "MeshInstance3D", true, false).size() > 0, n + " mesh")
		assert_true(p.find_children("*", "CollisionShape3D", true, false).size() > 0, n + " collision")
	scene.queue_free()
