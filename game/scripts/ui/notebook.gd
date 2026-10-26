## 信号手帳。記録は GameState.notebook に翻訳キーで保存し、表示のたびに翻訳する。
class_name Notebook
extends Control

signal recorded(signal_id: StringName)

var state: GameStateData
var defs: Dictionary

var _list: VBoxContainer

func _get_state() -> GameStateData:
	if state == null:
		state = get_node("/root/GameState")
	return state

func _get_defs() -> Dictionary:
	if defs.is_empty():
		defs = SignalSource.registry()
	return defs

func _find(signal_id: StringName) -> int:
	var nb := _get_state().notebook
	for i in nb.size():
		if nb[i]["signal_id"] == signal_id:
			return i
	return -1

func record(signal_id: StringName) -> bool:
	if _find(signal_id) != -1 or not _get_defs().has(signal_id):
		return false
	var d: SignalDef = _get_defs()[signal_id]
	_get_state().notebook.append({"signal_id": signal_id, "label_key": d.label_key, "decoded": not d.hidden})
	_get_state().changed.emit()
	recorded.emit(signal_id)
	if is_inside_tree():
		_rebuild()
	return true

func has_entry(signal_id: StringName) -> bool:
	return _find(signal_id) != -1

func entry_text(entry: Dictionary) -> String:
	var d: SignalDef = _get_defs()[entry["signal_id"]]
	var body := d.text if entry["decoded"] else Morse.encode(d.text)
	return tr(entry["label_key"]) + tr("nb_sep") + body

func try_manual_decode(signal_id: StringName, guess: String) -> bool:
	var i := _find(signal_id)
	if i == -1:
		return false
	var d: SignalDef = _get_defs()[signal_id]
	var norm := func(s: String) -> String: return s.to_upper().replace(" ", "").replace("　", "")
	if norm.call(guess) != norm.call(d.text):
		return false
	_get_state().notebook[i]["decoded"] = true
	_get_state().changed.emit()
	if is_inside_tree():
		_rebuild()
	return true

# ---- 表示 ----

func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.06, 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 80; scroll.offset_top = 60; scroll.offset_right = -80; scroll.offset_bottom = -60
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_notebook"):
		visible = not visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
		if visible:
			_rebuild()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _list:
		_rebuild()

func _rebuild() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = tr("nb_title")
	title.add_theme_font_size_override("font_size", 32)
	_list.add_child(title)
	for entry in _get_state().notebook:
		var label := Label.new()
		label.text = entry_text(entry)
		label.add_theme_font_size_override("font_size", 22)
		_list.add_child(label)
		var wave := _Waveform.new()
		wave.timeline = (_get_defs()[entry["signal_id"]] as SignalDef).timeline(0)
		wave.custom_minimum_size = Vector2(0, 28)
		_list.add_child(wave)
		if not entry["decoded"]:
			var input := LineEdit.new()
			input.placeholder_text = tr("nb_decode_hint")
			var id: StringName = entry["signal_id"]
			input.text_submitted.connect(func(t): try_manual_decode(id, t))
			_list.add_child(input)

## timeline を横棒で描く
class _Waveform extends Control:
	var timeline := PackedInt32Array()
	func _draw() -> void:
		var total := 0
		for ms in timeline:
			total += ms
		if total == 0:
			return
		var x := 0.0
		for i in timeline.size():
			var w := size.x * timeline[i] / total
			if i % 2 == 0:
				draw_rect(Rect2(x, 4, w, size.y - 8), Color(1.0, 0.85, 0.5))
			x += w
