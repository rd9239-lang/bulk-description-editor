## 信号の定義（data/signals.json の1件）。
class_name SignalDef
extends RefCounted

var id: StringName
var text: String
var fist: Fist
var hidden: bool
var label_key: String
var loop_pause_ms: int

static func load_all(path: String) -> Dictionary:
	var out := {}
	var raw = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(raw) != TYPE_DICTIONARY:
		push_warning("SignalDef: cannot parse %s" % path)
		return out
	for key in raw:
		var e: Dictionary = raw[key]
		var f := _fist_from(e.get("fist"))
		if f == null:
			push_warning("SignalDef: unknown fist for '%s', skipped" % key)
			continue
		var d := SignalDef.new()
		d.id = StringName(key)
		d.text = e.get("text", "")
		d.fist = f
		d.hidden = e.get("hidden", false)
		d.label_key = e.get("label_key", "")
		d.loop_pause_ms = int(e.get("loop_pause_ms", 0))
		out[d.id] = d
	return out

static func _fist_from(v) -> Fist:
	if typeof(v) == TYPE_STRING:
		match v:
			"daughter_a": return Fist.daughter_a()
			"captive_b": return Fist.captive_b()
			"trap": return Fist.trap()
	if typeof(v) == TYPE_DICTIONARY:
		return Fist.make(v.get("unit_ms", 200.0), v.get("dash_ratio", 3.0), v.get("char_gap", 3.0), v.get("word_gap", 7.0), v.get("jitter", 0.0))
	return null

func timeline(seed: int) -> PackedInt32Array:
	return fist.timeline(text, seed)

func cycle_ms(seed: int) -> int:
	var sum := loop_pause_ms
	for ms in timeline(seed):
		sum += ms
	return sum
