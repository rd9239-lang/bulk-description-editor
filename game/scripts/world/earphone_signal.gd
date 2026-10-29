## 古い線のそばでイヤホンに入るノイズと信号音。耳元で鳴る（立体でなく、屋内でもこもらない）。
## 線に近いほど大きく、hearing_range の2倍より離れると聞こえない。信号音は1周期ぶんのループ音（SignalTone）。
class_name EarphoneSignal
extends AudibleSource

const TONE_HZ := 600.0
const STATIC := "res://assets/audio/earphone_static.ogg"

var _static: AudioStreamPlayer
var _tone: AudioStreamPlayer
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
	_tone = AudioStreamPlayer.new()
	_tone.name = "Tone"
	_tone.bus = AudioMixer.SFX
	_tone.stream = SignalTone.make_loop(_timeline, _pause_ms, TONE_HZ)
	add_child(_tone)

func _process(delta: float) -> void:
	super._process(delta)
	var cam := get_viewport().get_camera_3d()
	_loud = loudness_at(cam.global_position) if cam else 0.0
	if _loud > 0.0 and not _tone.playing:
		_tone.play(phase_ms / 1000.0)
		if _static.stream:
			_static.play()
	elif _loud == 0.0 and _tone.playing:
		_tone.stop()
		_static.stop()
	if _tone.playing:
		_static.volume_db = linear_to_db(maxf(_loud, 0.001)) - 6.0
		_tone.volume_db = linear_to_db(maxf(0.85 * _loud, 0.001))
