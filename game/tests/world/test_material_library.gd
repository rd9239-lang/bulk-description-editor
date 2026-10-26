extends GutTest

func test_material_has_triplanar_pbr_maps():
	var m := MaterialLibrary.material("asphalt")
	assert_true(m is StandardMaterial3D)
	assert_true(m.albedo_texture != null)
	assert_true(m.normal_enabled and m.normal_texture != null)
	assert_true(m.roughness_texture != null)
	assert_true(m.uv1_triplanar and m.uv1_world_triplanar)
	assert_almost_eq(m.uv1_scale.x, 1.0 / 3.0, 0.001)

func test_material_is_cached():
	assert_eq(MaterialLibrary.material("concrete"), MaterialLibrary.material("concrete"))

func test_unknown_material_is_null():
	assert_eq(MaterialLibrary.material("no_such_material"), null)

func test_source_names_map_to_library():
	assert_eq(MaterialLibrary.for_source("tin_roof"), MaterialLibrary.material("tin_roof"))
	assert_eq(MaterialLibrary.for_source("plank"), MaterialLibrary.material("plank"))
	assert_true(MaterialLibrary.for_source("glass").transparency == BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert_eq(MaterialLibrary.for_source("lamp_emit"), null)

func test_apply_replaces_only_known_materials():
	var root := Node3D.new()
	for src in ["plank", "unknown_mat"]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var m := StandardMaterial3D.new()
		m.resource_name = src
		bm.material = m
		mi.mesh = bm
		mi.name = src
		root.add_child(mi)
	assert_eq(MaterialLibrary.apply(root), 1)
	assert_eq((root.get_node("plank") as MeshInstance3D).get_surface_override_material(0), MaterialLibrary.material("plank"))
	assert_true((root.get_node("unknown_mat") as MeshInstance3D).get_surface_override_material(0) == null)
	root.free()

func test_streetlight_model_gets_textures():
	var n: Node3D = load("res://assets/models/streetlight.glb").instantiate()
	MaterialLibrary.apply(n)
	var pole := n.find_child("Pole", true, false) as MeshInstance3D
	assert_eq(pole.get_surface_override_material(0), MaterialLibrary.material("concrete"))
	n.free()

func test_plain_material_without_texture():
	var g := MaterialLibrary.material("glass")
	assert_true(g.albedo_texture == null)
	assert_true(g.albedo_color.a < 0.3)
	assert_true(g.roughness < 0.1)
