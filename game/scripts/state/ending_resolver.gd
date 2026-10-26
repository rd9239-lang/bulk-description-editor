## エンディング判定。順序：打ち明け話 → 次の点滅 → ひとりの帰還 → 真相 → 名前のない人。
class_name EndingResolver

const RELICS_TOTAL := 5

static func resolve(s: GameStateData) -> StringName:
	if s.told_wife:
		return &"confession"
	if s.followed_signal == &"trap":
		return &"next_blink"
	if not s.found_daughter:
		return &"alone"
	if s.relics == RELICS_TOTAL and s.old_man_alive:
		return &"truth"
	return &"nameless"
