## 進行の記録。autoload 名は GameState。
class_name GameStateData
extends Node

signal changed

var chapter := 0
var told_wife := false
var followed_signal: StringName = &""
var relics := 0
var old_man_alive := true
var found_daughter := false
var flags := {}
## {"signal_id": StringName, "label_key": String, "decoded": bool}
var notebook: Array[Dictionary] = []
## signal_id -> 周期内の経過 ms
var signal_phase := {}

func reset() -> void:
	chapter = 0
	told_wife = false
	followed_signal = &""
	relics = 0
	old_man_alive = true
	found_daughter = false
	flags = {}
	notebook = []
	signal_phase = {}
	changed.emit()

## GameState のフィールドか flags に値を書く（会話の "set" から使う）
func set_value(key: String, value) -> void:
	if key in ["chapter", "told_wife", "followed_signal", "relics", "old_man_alive", "found_daughter"]:
		if key == "followed_signal":
			value = StringName(value)
		set(key, value)
	else:
		flags[key] = value
	changed.emit()

func to_dict() -> Dictionary:
	var phases := {}
	for k in signal_phase:
		phases[String(k)] = signal_phase[k]
	var nb := []
	for e in notebook:
		nb.append({"signal_id": String(e["signal_id"]), "label_key": e["label_key"], "decoded": e["decoded"]})
	return {
		"chapter": chapter, "told_wife": told_wife, "followed_signal": String(followed_signal),
		"relics": relics, "old_man_alive": old_man_alive, "found_daughter": found_daughter,
		"flags": flags, "notebook": nb, "signal_phase": phases,
	}

func from_dict(d: Dictionary) -> void:
	chapter = int(d.get("chapter", 0))
	told_wife = bool(d.get("told_wife", false))
	followed_signal = StringName(d.get("followed_signal", ""))
	relics = int(d.get("relics", 0))
	old_man_alive = bool(d.get("old_man_alive", true))
	found_daughter = bool(d.get("found_daughter", false))
	flags = d.get("flags", {})
	notebook = []
	for e in d.get("notebook", []):
		notebook.append({"signal_id": StringName(e["signal_id"]), "label_key": String(e["label_key"]), "decoded": bool(e["decoded"])})
	# 読み込み後は全信号を周期の最初から再開する
	signal_phase = {}
	for k in d.get("signal_phase", {}):
		signal_phase[StringName(k)] = 0
	changed.emit()
