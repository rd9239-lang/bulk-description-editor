## 打ち癖：点の長さ・線と点の比・文字間/語間の間・揺らぎ。
## timeline() は点灯から始まり、点灯・消灯を交互に並べたミリ秒の列を返す。
class_name Fist
extends Resource

const MIN_MS := 30

@export var unit_ms := 200.0
@export var dash_ratio := 3.0
@export var char_gap := 3.0
@export var word_gap := 7.0
@export var jitter := 0.0

static func make(u: float, d: float, c: float, w: float, j: float) -> Fist:
	var f := Fist.new()
	f.unit_ms = u
	f.dash_ratio = d
	f.char_gap = c
	f.word_gap = w
	f.jitter = j
	return f

## 本物の娘（A）
static func daughter_a() -> Fist:
	return make(300.0, 3.6, 3.4, 7.5, 0.12)

## 坑道の手前にいた女性（B）。Aから教わったので癖が近い
static func captive_b() -> Fist:
	return make(300.0, 3.3, 3.4, 7.5, 0.10)

## 罠のSOS。癖がなく正確すぎる
static func trap() -> Fist:
	return make(200.0, 3.0, 3.0, 7.0, 0.0)

func timeline(text: String, seed: int) -> PackedInt32Array:
	var units: Array[float] = []
	var words := Morse.encode(text).split(" / ", false)
	for wi in words.size():
		if wi > 0:
			units.append(word_gap)
		var chars := words[wi].split(" ", false)
		for ci in chars.size():
			if ci > 0:
				units.append(char_gap)
			var sym: String = chars[ci]
			for si in sym.length():
				if si > 0:
					units.append(1.0)
				units.append(1.0 if sym[si] == "." else dash_ratio)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out := PackedInt32Array()
	for u in units:
		var g := clampf(rng.randfn(0.0, 1.0), -2.0, 2.0)
		out.append(maxi(MIN_MS, roundi(u * unit_ms * (1.0 + jitter * g))))
	return out

func distance(other: Fist) -> float:
	return absf(unit_ms - other.unit_ms) / 200.0 \
		+ absf(dash_ratio - other.dash_ratio) / 3.0 \
		+ absf(char_gap - other.char_gap) / 3.0 \
		+ absf(word_gap - other.word_gap) / 7.0 \
		+ absf(jitter - other.jitter) / 0.1
