extends GutTest

var state: GameStateData
var dr: DialogueRunner

func before_each():
	state = GameStateData.new()
	dr = DialogueRunner.new()
	dr.state = state

func after_each():
	dr.free(); state.free()

func test_follows_next():
	dr.start("res://tests/fixtures/dialogue_test.json", "start")
	assert_eq(dr.current()["text_key"], "t_hello")
	dr.advance()
	assert_eq(dr.current()["text_key"], "t_ask")

func test_choice_sets_state_field():
	dr.start("res://tests/fixtures/dialogue_test.json", "ask")
	dr.choose(0)
	assert_true(state.told_wife)
	assert_eq(dr.current()["text_key"], "t_told")

func test_choice_sets_flag():
	dr.start("res://tests/fixtures/dialogue_test.json", "ask")
	dr.choose(1)
	assert_eq(state.flags.get("asked_neighbor"), true)

func test_require_filters_choices():
	dr.start("res://tests/fixtures/dialogue_test.json", "ask")
	assert_eq(dr.current()["choices"].size(), 2)
	state.flags["knows_secret"] = true
	dr.start("res://tests/fixtures/dialogue_test.json", "ask")
	assert_eq(dr.current()["choices"].size(), 3)

func test_null_next_ends():
	var ended := [""]
	dr.ended.connect(func(id): ended[0] = id)
	dr.start("res://tests/fixtures/dialogue_test.json", "told")
	dr.advance()
	assert_eq(ended[0], "told")
	assert_true(dr.current().is_empty())
