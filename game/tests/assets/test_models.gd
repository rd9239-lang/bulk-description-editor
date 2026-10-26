extends GutTest

func _inst(path: String) -> Node3D:
	var ps: PackedScene = load(path)
	assert_true(ps != null, "missing " + path)
	return ps.instantiate() if ps else null

func test_streetlight_contract():
	var n := _inst("res://assets/models/streetlight.glb")
	if n == null: return
	for name in ["Pole", "LampHead", "LightAnchor"]:
		assert_true(n.find_child(name, true, false) != null, name)
	var anchor := n.find_child("LightAnchor", true, false) as Node3D
	assert_eq(anchor.get_parent(), n)
	assert_almost_eq(anchor.position.y, 4.5, 0.05)
	var head := n.find_child("LampHead", true, false) as MeshInstance3D
	assert_eq(head.mesh.surface_get_material(0).resource_name, "lamp_emit")
	n.free()

func test_pole_contract():
	var n := _inst("res://assets/models/pole.glb")
	if n == null: return
	for name in ["Pole", "CrossArm", "WireAnchor_L", "WireAnchor_R"]:
		assert_true(n.find_child(name, true, false) != null, name)
	n.free()

func test_house_kit_contract():
	var n := _inst("res://assets/models/house_kit.glb")
	if n == null: return
	for name in ["Wall_2m", "Wall_Window_2m", "Door_Frame", "Floor_2m", "Roof_Tile_2m"]:
		assert_true(n.find_child(name, true, false) != null, name)
	n.free()
