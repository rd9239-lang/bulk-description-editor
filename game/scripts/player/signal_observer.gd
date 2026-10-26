## プレイヤーが見ている（聞いている）信号を数え、1周期の95%以上なら手帳に記録する。
class_name SignalObserver
extends Node

const REQUIRED := 0.95
const RADIO_MIN_RECEPTION := 0.8
const RADIO_HEARING_M := 6.0

@export var max_distance := 40.0
@export var view_angle_deg := 25.0

var notebook: Notebook
var _watched := {}

func tick(delta_ms: int, visible_ids: Array) -> void:
	for id in visible_ids:
		_watched[id] = _watched.get(id, 0) + delta_ms

func on_cycle_completed(signal_id: StringName, cycle_ms: int) -> bool:
	var seen: int = _watched.get(signal_id, 0)
	_watched[signal_id] = 0
	if cycle_ms <= 0 or seen < cycle_ms * REQUIRED:
		return false
	return notebook != null and notebook.record(signal_id)

func _ready() -> void:
	# 発信元は後から作られることがあるので、1フレーム待ってから接続する
	await get_tree().process_frame
	for src in get_tree().get_nodes_in_group("signal_sources"):
		var s := src as SignalSource
		s.cycle_completed.connect(func(id): on_cycle_completed(id, s.cycle_length_ms()))

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
	if src is Radio:
		return (src as Radio).reception() >= RADIO_MIN_RECEPTION and cam.global_position.distance_to(src.global_position) <= RADIO_HEARING_M
	var to := target - cam.global_position
	if to.length() > max_distance:
		return false
	if rad_to_deg((-cam.global_basis.z).angle_to(to)) > view_angle_deg:
		return false
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, target, 1)
	var hit := cam.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or src.is_ancestor_of(hit.collider) or hit.collider == src
