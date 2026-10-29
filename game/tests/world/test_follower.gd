extends GutTest

func test_stays_when_looked_at():
	var p := Follower.next_position(Vector3(20, 0, 0), Vector3.ZERO, Vector3(1, 0, 0), true, false, 1.0)
	assert_eq(p, Vector3(20, 0, 0))

func test_approaches_but_keeps_distance():
	var p := Follower.next_position(Vector3(20, 0, 0), Vector3.ZERO, Vector3(-1, 0, 0), false, false, 1.0)
	assert_almost_eq(p.x, 18.8, 0.01)
	var q := Follower.next_position(Vector3(9.5, 0, 0), Vector3.ZERO, Vector3(-1, 0, 0), false, false, 1.0)
	assert_almost_eq(q.x, 9.0, 0.01)

func test_waits_while_player_indoors():
	var p := Follower.next_position(Vector3(20, 0, 0), Vector3(0, 0, 6), Vector3(0, 0, 1), false, true, 1.0)
	assert_eq(p, Vector3(20, 0, 0))

func test_teleports_behind_when_far():
	var p := Follower.next_position(Vector3(100, 0, 0), Vector3(30, 0, 0), Vector3(1, 0, 0), false, false, 0.1)
	assert_almost_eq(p.x, 18.0, 0.01)
	assert_almost_eq(p.z, 0.0, 0.01)

func test_never_leaves_the_road_band():
	var p := Follower.next_position(Vector3(20, 0, 3.0), Vector3(20, 0, 15), Vector3(0, 0, 1), false, false, 1.0)
	assert_true(absf(p.z) <= Follower.BAND_Z + 0.001, str(p))

func test_walks_back_to_the_road_after_being_placed_off_it():
	var p := Follower.next_position(Vector3(118, 0, -5.2), Vector3(118, 0, 10), Vector3(0, 0, 1), false, false, 0.5)
	assert_almost_eq(p.z, -4.6, 0.01, "moves back toward the road at walking speed, no snap")
	var still := Follower.next_position(Vector3(118, 0, -5.2), Vector3(118, 0, 10), Vector3(0, 0, -1), true, false, 0.5)
	assert_eq(still, Vector3(118, 0, -5.2), "stays under the lamp while watched")

func test_looked_at_cone():
	assert_true(Follower.is_looked_at(Vector3.ZERO, Vector3(0, 0, -1), Vector3(3, 1, -10)))
	assert_false(Follower.is_looked_at(Vector3.ZERO, Vector3(0, 0, -1), Vector3(10, 1, -3)))
	assert_false(Follower.is_looked_at(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 1, -50)), "too far to notice")

func test_body_does_not_block_the_player():
	var f := Follower.new()
	add_child(f)
	assert_eq(f.body.collision_layer, 4)
	assert_eq(f.body.collision_mask, 0)
	f.queue_free()

func test_deactivate_hides_and_removes_from_interaction():
	var f := Follower.new()
	add_child(f)
	f.deactivate()
	assert_false(f.active)
	assert_false(f.visible)
	assert_eq(f.body.collision_layer, 0)
	f.activate(Vector3(78, 0, 4.2))
	assert_true(f.active)
	assert_true(f.visible)
	assert_eq(f.body.collision_layer, 4)
	assert_eq(f.global_position, Vector3(78, 0, 4.2))
	f.queue_free()
