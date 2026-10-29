## 序章→第1章→第2章の目標の進行と自動セーブ。目標は順番どおりにしか進まない。
## 第2章は夕方に始まり、母への電話から夜になる（時間帯は flags["time_of_day"] に保存）。
class_name ChapterFlow
extends Node

signal goal_changed(goal_id: StringName)
signal goal_completed(goal_id: StringName)
signal chapter_changed(chapter: int)
signal ending_triggered(ending_id: StringName)
signal time_of_day_changed(tod: StringName)

const GOALS: Array[StringName] = [
	&"arrive_pier", &"greet_mother", &"visit_museum", &"go_home", &"first_night",
	&"ask_neighbor", &"talk_wife", &"find_regular_lamp", &"radio_night",
	&"ch2_phone", &"ch2_coffee", &"ch2_dead_lamp", &"ch2_old_man", &"ch2_dorm", &"ch2_ruins",
	&"ch2_call_mother", &"ch2_power_plant", &"ch2_earphone", &"ch2_window", &"ch2_end",
]
const CHAPTER1_START := 5
const CHAPTER2_START := 9
## ここから夜（ch2_call_mother）
const NIGHT_START := 15
## 手帳に記録されると完了する目標
const SIGNAL_GOALS := {
	&"museum_hi": &"visit_museum", &"sos_a": &"find_regular_lamp", &"sos_a_radio": &"radio_night",
	&"sos_a_earphone": &"ch2_earphone",
}
## 書いてあることがすべてそろうと完了する目標（flag:名前 / relic:遺品ID）
const REQUIREMENT_GOALS := {&"ch2_ruins": ["flag:read_board", "relic:letter"]}

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

## 目標の番号に応じた時間帯
static func time_of_day_for(index: int) -> StringName:
	return &"dusk" if index >= CHAPTER2_START and index < NIGHT_START else &"night"

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
	elif next == CHAPTER2_START:
		state.chapter = 2
		state.flags["time_of_day"] = "dusk"
		saver.save_slot(0, state)
		chapter_changed.emit(2)
		time_of_day_changed.emit(&"dusk")
	elif next == NIGHT_START:
		state.flags["time_of_day"] = "night"
		saver.save_slot(0, state)
		time_of_day_changed.emit(&"night")
	goal_changed.emit(current_goal())
	_complete_if_already_recorded()
	_complete_if_requirements_met()

## 次の目標の信号がもう手帳にあれば、その場で完了させる（先に記録していても詰まらないように）
func _complete_if_already_recorded() -> void:
	for sid in SIGNAL_GOALS:
		if SIGNAL_GOALS[sid] == current_goal():
			for e in state.notebook:
				if e["signal_id"] == sid:
					complete(current_goal())
					return

func _complete_if_requirements_met() -> void:
	var reqs: Array = REQUIREMENT_GOALS.get(current_goal(), [])
	if reqs.is_empty():
		return
	for r in reqs:
		var kind_name := String(r).split(":")
		if kind_name[0] == "flag" and not state.flags.get(kind_name[1], false):
			return
		if kind_name[0] == "relic" and not StringName(kind_name[1]) in state.relics_found:
			return
	complete(current_goal())

func on_signal_recorded(signal_id: StringName) -> void:
	if SIGNAL_GOALS.has(signal_id):
		complete(SIGNAL_GOALS[signal_id])

func on_location_entered(_location: StringName) -> void:
	saver.save_slot(0, state)

func _on_state_changed() -> void:
	_complete_if_requirements_met()
	if _ended or not state.told_wife:
		return
	var e := EndingResolver.resolve(state)
	if e == &"confession":
		_ended = true
		ending_triggered.emit(e)
