## 壊れかけの街灯の不規則な点滅。親の SignalSource に生成した点滅を流し込む。
## 文字間に相当する消灯（600〜1399ms）を作らないので、偶然モールスの文字列にはならない。
class_name Flicker
extends Node

@export var seed := 0
@export var length_ms := 20000

static func pattern(seed: int, length_ms: int) -> PackedInt32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out := PackedInt32Array()
	var total := 0
	while total < length_ms:
		var on := rng.randi_range(40, 180) if rng.randf() < 0.7 else rng.randi_range(1500, 4000)
		var off := rng.randi_range(30, 180) if rng.randf() < 0.85 else rng.randi_range(1500, 3000)
		out.append(on)
		out.append(off)
		total += on + off
	return out

func _ready() -> void:
	var src := get_parent() as SignalSource
	if src:
		src.configure_raw(pattern(seed, length_ms), 0)
