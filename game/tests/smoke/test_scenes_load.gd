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

func test_quality_toggle_updates_environment():
	var scene = load("res://scenes/island_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	assert_true(scene.get_node_or_null("PostFX") != null)
	scene.apply_quality(&"low")
	assert_false(scene.get_node("WorldEnv").environment.volumetric_fog_enabled)
	scene.apply_quality(&"high")
	assert_true(scene.get_node("WorldEnv").environment.volumetric_fog_enabled)
	assert_true(scene.get_node("Moon").shadow_enabled)
	scene.queue_free()

func test_street_dressing_and_house_detail():
	var scene = load("res://scenes/island_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var home: Node3D = scene.get_node("House_Home")
	for part in ["RoofL", "RoofR", "Ridge", "GableL", "GableR", "Ceiling", "Foundation", "Gutter"]:
		assert_true(home.find_child(part, true, false) != null, part)
	assert_true(get_tree().get_nodes_in_group("block_walls").size() >= 10)
	assert_true(get_tree().get_nodes_in_group("wires").size() >= 8)
	for n in ["AlleyPave", "StopMarking", "CurveMirror", "EdgeLineN", "EdgeLineS"]:
		assert_true(scene.get_node_or_null(n) != null, n)
	var body := scene.get_node("Mother").get_node_or_null("Body") as MeshInstance3D
	assert_true(body != null and not (body.mesh is CapsuleMesh))
	scene.queue_free()
