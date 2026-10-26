extends GutTest

const DIR := "user://test_saves"
var saver: SaveSystemNode

func before_each():
	saver = SaveSystemNode.new()
	saver.save_dir = DIR
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))

func after_each():
	saver.free()

func _sample() -> GameStateData:
	var s := GameStateData.new()
	s.chapter = 1
	s.told_wife = true
	s.followed_signal = &"real"
	s.relics = 3
	s.old_man_alive = false
	s.found_daughter = true
	s.flags = {"asked_neighbor": true}
	s.notebook = [{"signal_id": &"sos_a", "label_key": "sig_sos_a", "decoded": true}]
	s.signal_phase = {&"sos_a": 1234}
	return s

func test_roundtrip_restores_all_fields():
	var s := _sample()
	assert_true(saver.save_slot(0, s))
	var t := GameStateData.new()
	assert_true(saver.load_slot(0, t))
	assert_eq(t.chapter, 1)
	assert_eq(t.told_wife, true)
	assert_eq(t.followed_signal, &"real")
	assert_eq(t.relics, 3)
	assert_eq(t.old_man_alive, false)
	assert_eq(t.found_daughter, true)
	assert_eq(t.flags, {"asked_neighbor": true})
	assert_eq(t.notebook[0]["signal_id"], &"sos_a")
	assert_eq(t.notebook[0]["decoded"], true)
	s.free(); t.free()

func test_signal_phase_restarts_from_zero_after_load():
	var s := _sample()
	saver.save_slot(0, s)
	var t := GameStateData.new()
	saver.load_slot(0, t)
	assert_eq(t.signal_phase.get(&"sos_a", -1), 0)
	s.free(); t.free()

func _assert_load_fails_cleanly(content):
	if content != null:
		var f := FileAccess.open(DIR.path_join("save_0.json"), FileAccess.WRITE)
		f.store_string(content)
		f.close()
	var t := GameStateData.new()
	assert_false(saver.load_slot(0, t))
	assert_eq(t.chapter, 0)
	assert_eq(t.relics, 0)
	assert_eq(t.old_man_alive, true)
	t.free()

func test_missing_file():
	_assert_load_fails_cleanly(null)

func test_corrupt_json():
	_assert_load_fails_cleanly("{not json")

func test_old_version():
	_assert_load_fails_cleanly('{"version": 0, "state": {"chapter": 3}}')

func test_has_save():
	assert_false(saver.has_save(0))
	var s := _sample()
	saver.save_slot(0, s)
	assert_true(saver.has_save(0))
	s.free()
