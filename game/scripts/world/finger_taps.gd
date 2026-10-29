## 老人が指でベンチを叩く音。点くたびに「コツ」と鳴る（隠れた信号。手帳は訳さない）。
class_name FingerTaps
extends AudibleSource

const TAP := "res://assets/audio/finger_tap.ogg"

var _player: AudioStreamPlayer3D

func _ready() -> void:
	super._ready()
	_player = AudioStreamPlayer3D.new()
	_player.name = "Tap"
	_player.volume_db = -10.0
	_player.unit_size = 1.5
	_player.max_distance = 12.0
	_player.bus = AudioMixer.OUTDOOR
	if ResourceLoader.exists(TAP):
		_player.stream = load(TAP)
	add_child(_player)
	toggled.connect(func(on): if on and _player.stream: _player.play())
