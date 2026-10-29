## 前の移住者の遺品。定義は data/relics.json、拾った記録は GameState.relics_found。
class_name Relics
extends RefCounted

const PATH := "res://data/relics.json"

static var _defs := {}

## id → {id, name_key, desc_key}
static func defs() -> Dictionary:
	if _defs.is_empty():
		var raw = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if typeof(raw) == TYPE_ARRAY:
			for r in raw:
				_defs[StringName(r["id"])] = r
	return _defs

## 拾う。初めてなら記録して true
static func pick(state: GameStateData, id: StringName) -> bool:
	if not defs().has(id) or id in state.relics_found:
		return false
	state.relics_found.append(id)
	state.relics = state.relics_found.size()
	state.changed.emit()
	return true
