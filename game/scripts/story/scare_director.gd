## 決められたタイミングの驚かせる演出。各演出は1回だけ再生する。
## 街灯の下の人影は、少し間をおいてから「灯りが点いていて、こちらから見えている」瞬間に初めて姿を見せ、
## そのとき音が鳴る（見ていないところで鳴らない）。一度見られたあと目をそらすか、決まった周期が過ぎると消える。
class_name ScareDirector
extends Node

signal scare_played(scare_id: String)

## 記録してから人影が立つまでの秒数
@export var appear_delay := 1.5

const LOOK_AWAY_S := 0.4
const SEEN_DISTANCE := 35.0
const CHEST := Vector3(0, 1.2, 0)

var _scares: Array = []
var _played := {}
var _figures: Array = []

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
	if not is_inside_tree():
		return
	var sound: String = s.get("sound", "")
	if s["kind"] == "figure_under_lamp":
		var scene := get_parent() if get_parent() else get_tree().current_scene
		var lamp := scene.get_node_or_null(s.get("lamp_path", "")) as SignalSource
		if lamp:
			_figure_under(lamp, int(s.get("cycles", 3)), sound)
			return
	# 人影を立てる場所がなければ、音だけすぐ鳴らす
	_stinger(sound)

func _stinger(sound: String) -> void:
	if sound == "":
		return
	var st := get_node_or_null("Stinger") as AudioStreamPlayer
	if st == null:
		st = AudioStreamPlayer.new()
		st.name = "Stinger"
		st.bus = AudioMixer.SFX
		add_child(st)
	st.stream = load("res://assets/audio/%s.ogg" % sound)
	st.play()

## 街灯の光が落ちる地面に、黒い人型を隠して立てておく
func _figure_under(lamp: SignalSource, cycles: int, sound: String) -> void:
	var fig := MeshInstance3D.new()
	fig.name = "Figure"
	fig.mesh = StreetDressing.mesh("Mannequin_F")
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.01, 0.01, 0.012)
	m.roughness = 1.0
	fig.material_override = m
	fig.visible = false
	lamp.add_child(fig)
	var sp := lamp.signal_point()
	fig.global_position = Vector3(sp.x, lamp.global_position.y, sp.z)
	var f := {"fig": fig, "lamp": lamp, "wait": appear_delay, "revealed": false, "away": 0.0, "cycles_left": cycles, "sound": sound}
	lamp.cycle_completed.connect(func(_id):
		if f["revealed"]:
			f["cycles_left"] -= 1)
	_figures.append(f)

func _process(delta: float) -> void:
	for f in _figures.duplicate():
		var fig: MeshInstance3D = f["fig"]
		if not is_instance_valid(fig):
			_figures.erase(f)
			continue
		var lamp: SignalSource = f["lamp"]
		var seen := lamp.is_on and _in_view(fig)
		if not f["revealed"]:
			f["wait"] -= delta
			if f["wait"] <= 0.0 and seen:
				f["revealed"] = true
				_face_camera(fig)
				_stinger(f["sound"])
		else:
			f["away"] = 0.0 if seen or not lamp.is_on else f["away"] + delta
			if f["away"] > LOOK_AWAY_S or f["cycles_left"] <= 0:
				fig.queue_free()
				_figures.erase(f)
				continue
		fig.visible = f["revealed"] and lamp.is_on

## 画面に入っていて、壁などにさえぎられていない（窓ガラスは通す）
func _in_view(fig: Node3D) -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var target := fig.global_position + CHEST
	if cam.global_position.distance_to(target) > SEEN_DISTANCE or not cam.is_position_in_frustum(target):
		return false
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, target, 1)
	return cam.get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func _face_camera(fig: Node3D) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var d := cam.global_position - fig.global_position
	fig.global_rotation = Vector3(0, atan2(d.x, d.z), 0)
