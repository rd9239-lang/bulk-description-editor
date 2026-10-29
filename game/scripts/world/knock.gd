## ノック音を合成して鳴らす。島民は炭鉱の合図の名残のリズム、妻は普通のリズムで叩く。
## 帰ってきた男は船の作業の合図で机を叩く。
class_name Knock
extends AudioStreamPlayer3D

## 叩く時刻（秒）
const ISLAND := [0.0, 0.45, 0.62, 1.1]
const NORMAL := [0.0, 0.28]
## 帰ってきた男が机を叩く、船の作業の合図（3回叩いて、2回ぶん止める）
const SHIP := [0.0, 0.3, 0.6, 1.6]
const RATE := 22050

static func make_stream(times: Array) -> AudioStreamWAV:
	var length := int((times[-1] + 0.4) * RATE)
	var data := PackedByteArray()
	data.resize(length * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for t in times:
		var start := int(t * RATE)
		for i in int(0.12 * RATE):
			var env := exp(-i / (0.018 * RATE))
			var s := (sin(TAU * 180.0 * i / RATE) * 0.7 + rng.randf_range(-1, 1) * 0.3) * env
			var idx := start + i
			if idx < length:
				data.encode_s16(idx * 2, clampi(int(s * 26000), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	return wav

func play_rhythm(kind: String) -> void:
	stream = make_stream(ISLAND if kind == "island" else SHIP if kind == "ship" else NORMAL)
	play()
