## 古い線のそばでイヤホンに入るノイズと信号音。耳元で鳴る（立体でなく、屋内でもこもらない）。
## 線に近いほど大きく、hearing_range の2倍より離れると聞こえない。
class_name EarphoneSignal
extends AudibleSource

const TONE_HZ := 600.0
const MIX_RATE := 22050.0
const STATIC := "res://assets/audio/earphone_static.ogg"

var _static: AudioStreamPlayer
var _tone: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _loud := 0.0

func _init() -> void:
	hearing_range = 2.5

## 聞く位置での大きさ（0〜1）
func loudness_at(pos: Vector3) -> float:
	return clampf(1.0 - pos.distance_to(global_position) / (hearing_range * 2.0), 0.0, 1.0)

func _ready() -> void:
	super._ready()
	_static = AudioStreamPlayer.new()
	_static.name = "Static"
	_static.bus = AudioMixer.SFX
	if ResourceLoader.exists(STATIC):
		_static.stream = AudioMixer.load_loop(STATIC)
	add_child(_static)
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	_tone = AudioStreamPlayer.new()
	_tone.name = "Tone"
	_tone.stream = gen
	_tone.bus = AudioMixer.SFX
	add_child(_tone)
	_tone.play()
	_playback = _tone.get_stream_playback()

func _process(delta: float) -> void:
	super._process(delta)
	var cam := get_viewport().get_camera_3d()
	_loud = loudness_at(cam.global_position) if cam else 0.0
	if _static.stream:
		if _loud > 0.0 and not _static.playing:
			_static.play()
		elif _loud == 0.0 and _static.playing:
			_static.stop()
		_static.volume_db = linear_to_db(maxf(_loud, 0.001)) - 6.0
	if _playback == null:
		return
	for i in _playback.get_frames_available():
		var s := sin(_phase * TAU) * 0.3 * _loud if is_on else 0.0
		_phase = fmod(_phase + TONE_HZ / MIX_RATE, 1.0)
		_playback.push_frame(Vector2(s, s))
