## 会話の表示。DialogueRunner の内容を画面下に出し、選択肢をボタンで選ばせる。
class_name DialogueBox
extends Control

var runner: DialogueRunner

var _speaker: Label
var _text: Label
var _choices: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -220; panel.offset_left = 120; panel.offset_right = -120; panel.offset_bottom = -40
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_speaker = Label.new()
	_speaker.add_theme_color_override("font_color", Color(0.9, 0.78, 0.45))
	box.add_child(_speaker)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 24)
	box.add_child(_text)
	_choices = VBoxContainer.new()
	box.add_child(_choices)
	visible = false
	if runner == null:
		runner = DialogueRunner.new()
		add_child(runner)
	runner.line_changed.connect(_show)
	runner.ended.connect(func(_id): _close())

func open(file: String, node_id: String) -> void:
	visible = true
	runner.start(file, node_id)

func _show(node: Dictionary) -> void:
	_speaker.text = tr(node.get("speaker_key", ""))
	_text.text = tr(node.get("text_key", ""))
	for c in _choices.get_children():
		c.queue_free()
	var choices: Array = node.get("choices", [])
	for i in choices.size():
		var b := Button.new()
		b.text = tr(choices[i]["text_key"])
		b.pressed.connect(runner.choose.bind(i))
		_choices.add_child(b)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if not choices.is_empty() else Input.MOUSE_MODE_CAPTURED

func _close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
		runner.advance()
		get_viewport().set_input_as_handled()
