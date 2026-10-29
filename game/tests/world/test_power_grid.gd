extends GutTest

var lamps: Array = []
var room: OmniLight3D
var grid: PowerGrid

func before_each():
	lamps = []
	for x in [5.0, 15.0, 30.0]:
		var l := Streetlight.new()
		add_child(l)
		l.global_position = Vector3(x, 0, 0)
		lamps.append(l)
	room = OmniLight3D.new()
	room.add_to_group("room_lights")
	add_child(room)
	grid = PowerGrid.new()
	add_child(grid)

func after_each():
	for l in lamps:
		if is_instance_valid(l):
			l.queue_free()
	room.queue_free()
	grid.queue_free()
	await get_tree().process_frame

func test_streetlights_join_group():
	for l in lamps:
		assert_true(l.is_in_group("streetlights"))

func test_cut_turns_everything_off():
	grid.cut()
	for l in lamps:
		assert_false(l._light.visible)
	assert_false(room.visible)

func test_power_back_resumes_steady_light():
	lamps[1].set_power(false)
	assert_false(lamps[1]._light.visible)
	lamps[1].set_power(true)
	assert_true(lamps[1]._light.visible)

func test_restore_goes_far_to_near_and_ends_with_last():
	var order := PowerGrid.restore_order(lamps, Vector3.ZERO, lamps[0])
	assert_eq(order.size(), 3)
	assert_eq(order[-1], lamps[0])
	assert_eq(order[0], lamps[2])
	assert_eq(order[1], lamps[1])

func test_restore_finishes_even_if_a_lamp_is_freed():
	grid.cut()
	var done := [false]
	grid.restored.connect(func(): done[0] = true)
	grid.restore(Vector3.ZERO, lamps[0], 0.01, 0.01)
	lamps[2].free()
	await get_tree().create_timer(0.3).timeout
	assert_true(done[0])
	assert_true(lamps[0]._light.visible)
	assert_true(lamps[1]._light.visible)
	assert_true(room.visible)
