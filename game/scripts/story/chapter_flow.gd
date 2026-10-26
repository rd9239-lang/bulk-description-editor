## 序章→第1章の目標の進行と自動セーブ。目標は順番どおりにしか進まない。
class_name ChapterFlow
extends Node

signal goal_changed(goal_id: StringName)
signal goal_completed(goal_id: StringName)
signal chapter_changed(chapter: int)
signal ending_triggered(ending_id: StringName)

const GOALS: Array[StringName] = [
	&"arrive_pier", &"greet_mother", &"visit_museum", &"go_home", &"first_night",
	&"ask_neighbor", &"talk_wife", &"find_regular_lamp", &"radio_night", &"slice_end",
]
const CHAPTER1_START := 5
## 手帳に記録されると完了する目標
const SIGNAL_GOALS := {&"museum_hi": &"visit_museum", &"sos_a": &"find_regular_lamp", &"sos_a_radio": &"radio_night"}

var state: GameStateData
var saver: SaveSystemNode
var _ended := false

func _ready() -> void:
	begin()

func begin() -> void:
	if state == null:
		state = get_node("/root/GameState")
	if saver == null:
		saver = get_node("/root/SaveSystem")
	if not state.changed.is_connected(_on_state_changed):
		state.changed.connect(_on_state_changed)
	goal_changed.emit(current_goal())

func _index() -> int:
	return int(state.flags.get("goal_index", 0))

func current_goal() -> StringName:
	return GOALS[mini(_index(), GOALS.size() - 1)]

func complete(goal_id: StringName) -> void:
	if goal_id != current_goal() or _index() >= GOALS.size() - 1:
		return
	var next := _index() + 1
	goal_completed.emit(goal_id)
	state.flags["goal_index"] = next
	if next == CHAPTER1_START:
		state.chapter = 1
		saver.save_slot(0, state)
		chapter_changed.emit(1)
	goal_changed.emit(current_goal())

func on_signal_recorded(signal_id: StringName) -> void:
	if SIGNAL_GOALS.has(signal_id):
		complete(SIGNAL_GOALS[signal_id])

func on_location_entered(_location: StringName) -> void:
	saver.save_slot(0, state)

func _on_state_changed() -> void:
	if _ended or not state.told_wife:
		return
	var e := EndingResolver.resolve(state)
	if e == &"confession":
		_ended = true
		ending_triggered.emit(e)
