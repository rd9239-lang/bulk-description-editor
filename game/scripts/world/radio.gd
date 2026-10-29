## ラジオ。周波数を合わせると信号のビープが聞こえ、外れると雑音になる。
class_name Radio
extends AudibleSource

const TONE_HZ := 600.0
const STATIC := "res://assets/audio/earphone_static.ogg"
## 雑音と信号音の最大の大きさ（0〜1）
const STATIC_GAIN := 0.17
const TONE_GAIN := 1.0
const RESYNC_S := 0.08

@export var station_freq := 81.7
var tuned_freq := 76.0
## 調べて電源を入れるまでは鳴らない
var powered := false

var _static: AudioStreamPlayer3D
var _tone: AudioStreamPlayer3D

func _init() -> void:
	hearing_range = 6.0

func power_on() -> void:
	powered = true
	if is_inside_tree() and _tone:
		_start_sound()

func power_off() -> void:
	powered = false
	if _tone:
		_tone.stop()
		_static.stop()

## 電源が入っていて、局にほぼ合っているときだけ信号が聞き取れる
func audible() -> bool:
	return powered and reception() >= 0.8

func reception() -> float:
	var off := absf(tuned_freq - station_freq)
	if off <= 0.3:
		return 1.0
	if off >= 1.5:
		return 0.0
	return 1.0 - (off - 0.3) / 1.2

func _ready() -> void:
	super._ready()
	_static = _make_player("Static")
	if ResourceLoader.exists(STATIC):
		_static.stream = AudioMixer.load_loop(STATIC)
	_tone = _make_player("Tone")
	_tone.stream = SignalTone.make_loop(_timeline, _pause_ms, TONE_HZ)
	cycle_completed.connect(func(_id): _resync())
	if powered:
		_start_sound()

func _make_player(name: String) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.name = name
	p.bus = AudioMixer.INDOOR
	p.volume_db = -80.0
	add_child(p)
	return p

func _start_sound() -> void:
	if _static.stream:
		_static.play()
	_tone.play(phase_ms / 1000.0)
	_update_volume()

## 信号音のループが点滅とずれてきたら合わせ直す
func _resync() -> void:
	if powered and _tone.playing and absf(_tone.get_playback_position() - phase_ms / 1000.0) > RESYNC_S:
		_tone.play(phase_ms / 1000.0)

func _update_volume() -> void:
	var r := reception()
	_static.volume_db = linear_to_db(maxf(STATIC_GAIN * (1.0 - r), 0.0005))
	_tone.volume_db = linear_to_db(maxf(TONE_GAIN * r, 0.0005))

func _process(delta: float) -> void:
	super._process(delta)
	if powered and _tone:
		_update_volume()
