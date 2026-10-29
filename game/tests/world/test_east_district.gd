extends GutTest

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

func test_east_district_built():
	for p in ["East/Dorm", "East/Row1", "East/Row2", "East/Row3", "East/Plant", "East/PlantLamp", "East/Barrier", "Harbor/Bench", "East/Plant/Switchboard", "East/Plant/Locker", "East/Row2/NoticeBoard", "East/Row2/Desk", "East/Dorm/LongTable", "East/Plant/OldWire"]:
		assert_true(main.has_node(p), p)

func test_new_lamps_are_streetlights():
	var lamp := main.get_node("East/PlantLamp") as Streetlight
	assert_true(lamp != null)
	assert_true(lamp.is_in_group("streetlights"))
	assert_eq(main.get_node("East/PlantLamp").global_position, Vector3(118, 0, -4.5))

func test_barrier_opens():
	EastDistrict.set_east_open(main, false)
	assert_true(main.get_node("East/Barrier").visible)
	assert_eq((main.get_node("East/Barrier") as StaticBody3D).collision_layer, 1)
	EastDistrict.set_east_open(main, true)
	assert_false(main.get_node("East/Barrier").visible)
	assert_eq((main.get_node("East/Barrier") as StaticBody3D).collision_layer, 0)

func test_barrier_closed_at_start():
	assert_true(main.get_node("East/Barrier").visible)

func test_new_interiors_muffle_outdoor_sound():
	for p in ["East/Dorm/Interior", "East/Row2/Interior", "East/Plant/Interior"]:
		var a := main.get_node(p) as Area3D
		a.body_entered.emit(main.player)
		assert_eq(main._indoor_count, 1, p)
		a.body_exited.emit(main.player)
		assert_eq(main._indoor_count, 0, p)

func test_ground_extends_east():
	var q := PhysicsRayQueryParameters3D.create(Vector3(120, 5, 0), Vector3(120, -5, 0))
	await get_tree().physics_frame
	var hit := main.get_world_3d().direct_space_state.intersect_ray(q)
	assert_false(hit.is_empty(), "ground under the far end of the road")

func test_building_windows_are_visible_panes():
	var panes := main.get_node("East/Dorm").find_children("Pane*", "MeshInstance3D", true, false)
	assert_gt(panes.size(), 3)
	for p in panes:
		var m := ((p as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		assert_eq(m.albedo_color.a, 1.0, "opaque dark pane, not see-through glass")
