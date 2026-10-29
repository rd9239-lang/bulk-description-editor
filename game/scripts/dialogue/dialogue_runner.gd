## 会話の進行。データ形式は data/dialogue/*.json（ノードID → ノード）。
class_name DialogueRunner
extends Node

signal line_changed(node: Dictionary)
signal ended(last_node_id: String)

var state: GameStateData
var _nodes := {}
var _id := ""

func _get_state() -> GameStateData:
	if state == null:
		state = get_node("/root/GameState")
	return state

func start(file: String, node_id: String) -> void:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(file))
	_nodes = raw if typeof(raw) == TYPE_DICTIONARY else {}
	if _nodes.is_empty():
		push_warning("DialogueRunner: cannot load %s" % file)
	_go(node_id)

func is_active() -> bool:
	return _id != ""

## 選択肢のないノードを次へ進める
func advance() -> void:
	if _id == "" or not current().get("choices", []).is_empty():
		return
	_go(_nodes[_id].get("next"))

func choose(index: int) -> void:
	var choices: Array = current().get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var c: Dictionary = choices[index]
	for key in c.get("set", {}):
		_get_state().set_value(key, c["set"][key])
	_go(c.get("next"))

## 表示用：require を満たす選択肢だけを含む
func current() -> Dictionary:
	if _id == "" or not _nodes.has(_id):
		return {}
	var node: Dictionary = _nodes[_id].duplicate(true)
	var visible := []
	for c in node.get("choices", []):
		if _meets(c.get("require", {})):
			visible.append(c)
	node["choices"] = visible
	return node

func _meets(req: Dictionary) -> bool:
	var s := _get_state()
	for key in req:
		var have = s.get(key) if key in s else s.flags.get(key)
		if have != req[key]:
			return false
	return true

func _go(next) -> void:
	var last := _id
	if next == null or not _nodes.has(str(next)):
		_id = ""
		ended.emit(last)
		return
	_id = str(next)
	# ノード自体の "set"：そのせりふが出たときに記録する（掲示板を読んだ、など）
	var node: Dictionary = _nodes[_id]
	for key in node.get("set", {}):
		_get_state().set_value(key, node["set"][key])
	line_changed.emit(current())
