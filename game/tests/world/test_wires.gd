extends GutTest

func test_catenary_endpoints_and_sag():
	var a := Vector3(0, 8, 0)
	var b := Vector3(16, 8, 0)
	var pts := Wires.sag_points(a, b, 0.6, 16)
	assert_eq(pts.size(), 17)
	assert_true(pts[0].is_equal_approx(a))
	assert_true(pts[16].is_equal_approx(b))
	assert_almost_eq(pts[8].y, 8.0 - 0.6, 0.001)
	assert_almost_eq(pts[8].x, 8.0, 0.001)

func test_sag_is_lowest_in_the_middle():
	var pts := Wires.sag_points(Vector3(0, 8, 0), Vector3(10, 6, 0), 0.5, 10)
	for i in range(1, 10):
		var straight := lerpf(8.0, 6.0, i / 10.0)
		assert_true(pts[i].y < straight)

func test_wire_mesh_has_segments():
	var mi := Wires.make_wire(Vector3(0, 8, 0), Vector3(16, 8, 0), 0.6, 12)
	assert_true(mi is MeshInstance3D)
	assert_true(mi.mesh.get_surface_count() == 1)
	mi.free()
