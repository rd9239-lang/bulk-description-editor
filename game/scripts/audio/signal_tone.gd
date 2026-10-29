## 信号の点滅に合わせた「ピー」という音を、1周期ぶんのループ音として前もって作る。
## （その場で音を生成する AudioStreamGenerator は、場面の入れ替え時に音声処理を止めてしまうことがあったため使わない）
class_name SignalTone
extends RefCounted

const FADE_S := 0.004

static func make_loop(timeline: PackedInt32Array, pause_ms: int, hz: float, rate := 22050, amp := 0.35) -> AudioStreamWAV:
	var total_ms := pause_ms
	for ms in timeline:
		total_ms += ms
	var frames := int(rate * total_ms / 1000.0)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var fade := int(FADE_S * rate)
	var t_ms := 0
	for i in timeline.size():
		if i % 2 == 0:
			var start := int(rate * t_ms / 1000.0)
			var n := int(rate * timeline[i] / 1000.0)
			for k in n:
				var idx := start + k
				if idx >= frames:
					break
				var env := minf(1.0, minf(float(k) / fade, float(n - 1 - k) / fade))
				var s := sin(TAU * hz * idx / rate) * amp * env
				data.encode_s16(idx * 2, int(s * 32767.0))
		t_ms += timeline[i]
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = frames
	return wav
