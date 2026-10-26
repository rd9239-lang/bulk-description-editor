## 決められたタイミングの驚かせる演出。各演出は1回だけ再生する。
class_name ScareDirector
extends Node

signal scare_played(scare_id: String)

var _scares: Array = []
var _played := {}

func _ready() -> void:
	if _scares.is_empty():
		load_scares("res://data/scares.json")

func load_scares(path: String) -> void:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(path))
	_scares = raw if typeof(raw) == TYPE_ARRAY else []

func on_goal_completed(goal_id: StringName) -> void:
	for s in _scares:
		if s["trigger"] == "goal_completed:%s" % goal_id and not _played.has(s["id"]):
			_played[s["id"]] = true
			_play(s)
			scare_played.emit(s["id"])

func _play(s: Dictionary) -> void:
	if s["kind"] == "figure_under_lamp" and is_inside_tree():
		var scene := get_parent() if get_parent() else get_tree().current_scene
		var lamp := scene.get_node_or_null(s.get("lamp_path", "")) as SignalSource
		if lamp:
			_figure_under(lamp, int(s.get("cycles", 3)))

## 街灯の下に人影を立たせ、点灯中だけ見えるようにする。指定周期で消える。
func _figure_under(lamp: SignalSource, cycles: int) -> void:
	var fig := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.25
	cap.height = 1.7
	fig.mesh = cap
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.02, 0.02, 0.02)
	m.roughness = 1.0
	fig.material_override = m
	lamp.add_child(fig)
	fig.position = Vector3(0.8, 0.85, 0.6)
	fig.visible = lamp.is_on
	var left := [cycles]
	lamp.toggled.connect(func(on): if is_instance_valid(fig): fig.visible = on)
	lamp.cycle_completed.connect(func(_id):
		left[0] -= 1
		if left[0] <= 0 and is_instance_valid(fig):
			fig.queue_free())
