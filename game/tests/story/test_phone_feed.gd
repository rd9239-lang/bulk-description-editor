extends GutTest

var state: GameStateData
var feed: PhoneFeed

func before_each():
	state = GameStateData.new()
	feed = PhoneFeed.new()
	feed.state = state
	add_child(feed)

func after_each():
	feed.free(); state.free()

func test_goal_delivers_once():
	var got := []
	feed.delivered.connect(func(n): got.append(n["id"]))
	feed.on_goal_completed(&"ch2_phone")
	feed.on_goal_completed(&"ch2_phone")
	assert_eq(got, ["bank_address"])
	assert_eq(state.phone, [&"bank_address"] as Array[StringName])

func test_unrelated_goal_delivers_nothing():
	feed.on_goal_completed(&"ch2_coffee")
	assert_eq(state.phone.size(), 0)

func test_photo_post_is_marked():
	assert_true(feed.note(&"sns_like")["photo"])
	assert_false(feed.note(&"bank_address")["photo"])

func test_static_notes_match_feed():
	var notes := PhoneFeed.load_notes(PhoneFeed.PATH)
	assert_true(notes.has(&"bank_address"))
	assert_true(notes.has(&"sns_like"))
