## プレイヤーが見ている（聞いている）信号を数え、1周期の長さの95%以上見たら手帳に記録する。
## 見始めるのは周期のどこからでもよい。少し目をそらしても（1.5秒以内）続きから数える。
class_name SignalObserver
extends Node

## 1周期ぶん見終わるたびに出る（記録済みでも出る）
signal observed(signal_id: StringName)

const REQUIRED := 0.95
const LOOK_AWAY_MS := 1500

@export var max_distance := 40.0
@export var view_angle_deg := 25.0

var notebook: Notebook
var _cycle := {}
var _watched := {}
var _unseen := {}
var _visible: Array = []

func set_cycle(signal_id: StringName, cycle_ms: int) -> void:
	_cycle[signal_id] = cycle_ms

func tick(delta_ms: int, visible_ids: Array) -> void:
	_visible = visible_ids
	for id in _watched.keys():
		if id not in visible_ids:
			_unseen[id] = _unseen.get(id, 0) + delta_ms
			if _unseen[id] > LOOK_AWAY_MS:
				_watched[id] = 0
	for id in visible_ids:
		_unseen[id] = 0
		_watched[id] = _watched.get(id, 0) + delta_ms
		var cycle: int = _cycle.get(id, 0)
		if cycle > 0 and _watched[id] >= cycle * REQUIRED:
			_watched[id] = 0
			observed.emit(id)
			if notebook:
				notebook.record(id)

## 記録までの進み具合（0〜1）
func progress(signal_id: StringName) -> float:
	var cycle: int = _cycle.get(signal_id, 0)
	if cycle <= 0:
		return 0.0
	return clampf(float(_watched.get(signal_id, 0)) / (cycle * REQUIRED), 0.0, 1.0)

## いま見ている信号（複数なら一番進んでいるもの）。なければ空
func current_target() -> StringName:
	var best: StringName = &""
	for id in _visible:
		if best == &"" or progress(id) > progress(best):
			best = id
	return best

func _ready() -> void:
	# 発信元は後から作られることがあるので、1フレーム待ってから周期を登録する
	await get_tree().process_frame
	for src in get_tree().get_nodes_in_group("signal_sources"):
		var s := src as SignalSource
		if s.signal_id != &"":
			set_cycle(s.signal_id, s.cycle_length_ms())

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var ids: Array = []
	for src in get_tree().get_nodes_in_group("signal_sources"):
		if _perceives(cam, src as SignalSource):
			ids.append((src as SignalSource).signal_id)
	tick(int(delta * 1000.0), ids)

func _perceives(cam: Camera3D, src: SignalSource) -> bool:
	if src.signal_id == &"":
		return false
	var target := src.signal_point()
	if src is AudibleSource:
		return (src as AudibleSource).heard_from(cam.global_position)
	var to := target - cam.global_position
	if to.length() > max_distance:
		return false
	if rad_to_deg((-cam.global_basis.z).angle_to(to)) > view_angle_deg:
		return false
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, target, 1)
	var hit := cam.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or src.is_ancestor_of(hit.collider) or hit.collider == src
