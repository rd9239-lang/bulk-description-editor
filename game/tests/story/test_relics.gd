extends GutTest

func test_pick_counts_once():
	var s := GameStateData.new()
	assert_true(Relics.pick(s, &"watch"))
	assert_false(Relics.pick(s, &"watch"))
	assert_false(Relics.pick(s, &"nope"))
	assert_eq(s.relics, 1)
	assert_eq(s.relics_found, [&"watch"] as Array[StringName])
	s.free()

func test_chapter2_relics_defined():
	var d := Relics.defs()
	for id in [&"watch", &"letter", &"nametag"]:
		assert_true(d.has(id), String(id))
		assert_true(String(d[id]["name_key"]).begins_with("relic_"))

func test_interactable_has_relic_id():
	var it := Interactable.new()
	assert_eq(it.relic_id, &"")
	it.free()
