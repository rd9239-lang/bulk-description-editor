## ラジオ。周波数を合わせると信号のビープが聞こえ、外れると雑音になる。
class_name Radio
extends SignalSource

const TONE_HZ := 600.0
const MIX_RATE := 22050.0

@export var station_freq := 81.7
var tuned_freq := 76.0

var _player: AudioStreamPlayer3D
var _playback: AudioStreamGeneratorPlayback
var _tone_phase := 0.0

func reception() -> float:
	var off := absf(tuned_freq - station_freq)
	if off <= 0.3:
		return 1.0
	if off >= 1.5:
		return 0.0
	return 1.0 - (off - 0.3) / 1.2

func _ready() -> void:
	super._ready()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	_player = AudioStreamPlayer3D.new()
	_player.stream = gen
	_player.bus = AudioMixer.INDOOR
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

func _process(delta: float) -> void:
	super._process(delta)
	if _playback == null:
		return
	var r := reception()
	for i in _playback.get_frames_available():
		var s := randf_range(-1.0, 1.0) * 0.25 * (1.0 - r)
		if is_on:
			s += sin(_tone_phase * TAU) * 0.5 * r
		_tone_phase = fmod(_tone_phase + TONE_HZ / MIX_RATE, 1.0)
		_playback.push_frame(Vector2(s, s))
