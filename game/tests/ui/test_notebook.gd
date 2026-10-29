extends GutTest

var state: GameStateData
var nb: Notebook

func before_each():
	state = GameStateData.new()
	nb = Notebook.new()
	nb.state = state
	nb.defs = SignalDef.load_all("res://data/signals.json")

func after_each():
	TranslationServer.set_locale("ja")
	nb.free()
	state.free()

func test_record_once():
	assert_true(nb.record(&"sos_a"))
	assert_false(nb.record(&"sos_a"))
	assert_eq(state.notebook.size(), 1)
	assert_eq(state.notebook[0]["decoded"], true)

func test_hidden_signal_is_not_decoded():
	nb.record(&"oldman_nigero")
	assert_eq(state.notebook[0]["decoded"], false)
	assert_true(nb.entry_text(state.notebook[0]).contains("-. .. --. . .-. ---"))

func test_manual_decode():
	nb.record(&"oldman_nigero")
	assert_false(nb.try_manual_decode(&"oldman_nigero", "NIGERU"))
	assert_true(nb.try_manual_decode(&"oldman_nigero", "ni gero"))
	assert_eq(state.notebook[0]["decoded"], true)

func test_language_switch_rerenders_entry():
	TranslationServer.set_locale("ja")
	nb.record(&"sos_a")
	assert_true(nb.entry_text(state.notebook[0]).contains("窓の外の街灯"))
	TranslationServer.set_locale("en")
	assert_true(nb.entry_text(state.notebook[0]).contains("Streetlight outside the window"))
	assert_eq(state.notebook[0]["label_key"], "sig_sos_a")

func test_recorded_signal_emitted():
	var got := []
	nb.recorded.connect(func(id): got.append(id))
	nb.record(&"sos_a")
	nb.record(&"sos_a")
	assert_eq(got, [&"sos_a"])

func test_shows_section_headings():
	add_child(nb)
	nb._rebuild()
	var text := "\n".join(nb.lines())
	for k in ["nb_signals", "nb_relics", "nb_phone"]:
		assert_true(text.contains(tr(k)), k)

func test_shows_relics_and_phone():
	state.relics_found = [&"watch"] as Array[StringName]
	state.phone = [&"bank_address"] as Array[StringName]
	add_child(nb)
	nb._rebuild()
	var text := "\n".join(nb.lines())
	assert_true(text.contains(tr("relic_watch")))
	assert_true(text.contains(tr("relic_watch_desc")))
	assert_true(text.contains(tr("ph_bank_address")))

func test_language_switch_retranslates():
	state.relics_found = [&"watch"] as Array[StringName]
	add_child(nb)
	TranslationServer.set_locale("en")
	nb._rebuild()
	var en := "\n".join(nb.lines())
	TranslationServer.set_locale("ja")
	nb._rebuild()
	var ja := "\n".join(nb.lines())
	assert_ne(en, ja)
	assert_true(ja.contains("腕時計"))
	assert_true(en.contains("wristwatch"))
