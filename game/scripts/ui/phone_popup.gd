## スマホの通知の表示。ふつうの通知は画面右上に出て4秒で消える。写真つきの投稿は中央に大きく開き、E で閉じる。
class_name PhonePopup
extends Control

signal closed

const HOLD_S := 4.0
const VIBRATE := "res://assets/audio/phone_vibrate.ogg"

var _banner: PanelContainer
var _banner_sender: Label
var _banner_text: Label
var _post: PanelContainer
var _post_sender: Label
var _post_photo: TextureRect
var _post_text: Label
var _vibrate: AudioStreamPlayer
var _serial := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner = PanelContainer.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_banner.offset_left = -470; _banner.offset_right = -24; _banner.offset_top = 24; _banner.offset_bottom = 110
	add_child(_banner)
	var bb := VBoxContainer.new()
	_banner.add_child(bb)
	_banner_sender = _label(bb, 16, Color(0.7, 0.75, 0.82))
	_banner_text = _label(bb, 20, Color(0.95, 0.95, 0.95))
	_post = PanelContainer.new()
	_post.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_post.offset_left = -340; _post.offset_right = 340; _post.offset_top = -290; _post.offset_bottom = 290
	add_child(_post)
	var pb := VBoxContainer.new()
	_post.add_child(pb)
	_post_sender = _label(pb, 18, Color(0.7, 0.75, 0.82))
	_post_photo = TextureRect.new()
	_post_photo.custom_minimum_size = Vector2(640, 400)
	_post_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_post_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pb.add_child(_post_photo)
	_post_text = _label(pb, 22, Color(0.95, 0.95, 0.95))
	var hint := _label(pb, 16, Color(0.6, 0.6, 0.6))
	hint.text = tr("ui_close_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_vibrate = AudioStreamPlayer.new()
	_vibrate.name = "Vibrate"
	_vibrate.bus = AudioMixer.SFX
	if ResourceLoader.exists(VIBRATE):
		_vibrate.stream = load(VIBRATE)
	add_child(_vibrate)
	_banner.visible = false
	_post.visible = false

func _label(parent: Control, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func is_open() -> bool:
	return _banner.visible or _post.visible

## 写真つきの投稿が開いているか
func is_post_open() -> bool:
	return _post.visible

func show_note(note: Dictionary, photo: Texture2D = null) -> void:
	if _vibrate.stream:
		_vibrate.play()
	if note.get("photo", false):
		_post_sender.text = tr(note.get("sender_key", "")) + "　" + tr(note.get("text_key", ""))
		_post_photo.texture = photo
		_post_text.text = tr(note.get("post_key", ""))
		_banner.visible = false
		_post.visible = true
		return
	_banner_sender.text = tr(note.get("sender_key", ""))
	_banner_text.text = tr(note.get("text_key", ""))
	_banner.visible = true
	_serial += 1
	var mine := _serial
	await get_tree().create_timer(HOLD_S).timeout
	if mine == _serial and is_instance_valid(_banner):
		_banner.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _post.visible and event.is_action_pressed("interact"):
		_post.visible = false
		get_viewport().set_input_as_handled()
		closed.emit()
