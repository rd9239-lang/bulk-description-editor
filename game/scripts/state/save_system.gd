## セーブ。autoload 名は SaveSystem。保存先 <save_dir>/save_<slot>.json。
class_name SaveSystemNode
extends Node

const VERSION := 1

var save_dir := "user://"

func _path(slot: int) -> String:
	return save_dir.path_join("save_%d.json" % slot)

func _state(state: GameStateData) -> GameStateData:
	return state if state != null else get_node("/root/GameState")

func save_slot(slot: int, state: GameStateData = null) -> bool:
	var f := FileAccess.open(_path(slot), FileAccess.WRITE)
	if f == null:
		push_warning("SaveSystem: cannot write %s" % _path(slot))
		return false
	f.store_string(JSON.stringify({"version": VERSION, "state": _state(state).to_dict()}))
	f.close()
	return true

func load_slot(slot: int, state: GameStateData = null) -> bool:
	if not has_save(slot):
		push_warning("SaveSystem: no save in slot %d" % slot)
		return false
	var raw = JSON.parse_string(FileAccess.get_file_as_string(_path(slot)))
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("version", 0)) != VERSION or typeof(raw.get("state")) != TYPE_DICTIONARY:
		push_warning("SaveSystem: invalid or outdated save in slot %d" % slot)
		return false
	_state(state).from_dict(raw["state"])
	return true

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_path(slot))
