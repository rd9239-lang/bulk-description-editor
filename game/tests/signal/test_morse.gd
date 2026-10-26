extends GutTest

func test_encode_sos():
	assert_eq(Morse.encode("SOS"), "... --- ...")

func test_encode_words():
	assert_eq(Morse.encode("hi you"), ".... .. / -.-- --- ..-")

func test_decode_roundtrip():
	assert_eq(Morse.decode(Morse.encode("HELP 42")), "HELP 42")

func test_decode_unknown():
	assert_eq(Morse.decode("...... ..."), "?S")
