extends GutTest

var popup: PhonePopup
var notes: Dictionary

func before_each():
	notes = PhoneFeed.load_notes(PhoneFeed.PATH)
	popup = PhonePopup.new()
	add_child(popup)

func after_each():
	popup.queue_free()
	await get_tree().process_frame

func _interact() -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	return ev

func test_text_note_hides_by_itself():
	popup.show_note(notes[&"bank_address"])
	assert_true(popup.is_open())
	await get_tree().create_timer(4.3).timeout
	assert_false(popup.is_open())

func test_photo_note_waits_for_interact():
	var img := Image.create(64, 40, false, Image.FORMAT_RGB8)
	popup.show_note(notes[&"sns_like"], ImageTexture.create_from_image(img))
	assert_true(popup.is_post_open())
	await get_tree().create_timer(4.3).timeout
	assert_true(popup.is_open())
	var closed := [false]
	popup.closed.connect(func(): closed[0] = true)
	popup._unhandled_input(_interact())
	assert_true(closed[0])
	assert_false(popup.is_open())

func test_interact_does_nothing_when_text_only():
	popup.show_note(notes[&"bank_address"])
	var closed := [false]
	popup.closed.connect(func(): closed[0] = true)
	popup._unhandled_input(_interact())
	assert_false(closed[0], "text notes are not closed by E (E keeps working for the game)")
