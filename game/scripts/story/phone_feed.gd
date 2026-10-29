## 主人公のスマホに届く通知（乗っ取りの進行）。定義は data/phone.json、届いた記録は GameState.phone。
class_name PhoneFeed
extends Node

signal delivered(note: Dictionary)

const PATH := "res://data/phone.json"

var state: GameStateData
var _notes := {}

## id → 通知の辞書（手帳からも使う）
static func load_notes(path: String) -> Dictionary:
	var out := {}
	var raw = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(raw) == TYPE_ARRAY:
		for n in raw:
			out[StringName(n["id"])] = n
	return out

func _ready() -> void:
	if _notes.is_empty():
		load_feed(PATH)

func load_feed(path: String) -> void:
	_notes = load_notes(path)

func _get_state() -> GameStateData:
	if state == null:
		state = get_node("/root/GameState")
	return state

func note(id: StringName) -> Dictionary:
	return _notes.get(id, {})

func on_goal_completed(goal: StringName) -> void:
	for id in _notes:
		if _notes[id]["trigger"] == "goal_completed:%s" % goal:
			deliver(id)

## まだ届いていなければ届ける
func deliver(id: StringName) -> bool:
	if not _notes.has(id) or id in _get_state().phone:
		return false
	_get_state().phone.append(id)
	_get_state().changed.emit()
	delivered.emit(_notes[id])
	return true
