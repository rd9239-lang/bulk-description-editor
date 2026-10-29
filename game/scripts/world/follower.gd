## 帰ってきた男のつきまとい。屋外で少し離れてついてきて、見られている間は立ち止まってこちらを向く。
## 道路の上（|z| <= BAND_Z）しか歩かないので家や塀にめり込まず、建物の中にも入らない。
## 体はプレイヤーとぶつからない（調べるレイ用のレイヤー4だけ）。
class_name Follower
extends Node3D

const KEEP := 9.0
const SPEED := 1.2
const LOOK_DEG := 35.0
const NOTICE_DIST := 40.0
const TELEPORT_DIST := 35.0
const BEHIND := 12.0
const BAND_Z := 3.2
const MIN_X := -0.5
const MAX_X := 125.0

var active := true
var body: Interactable

func _init() -> void:
	body = Interactable.new()
	body.name = "Body"
	body.collision_layer = 4
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = StreetDressing.mesh("Mannequin_F")
	if mi.mesh:
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			if src and src.resource_name == "npc_cloth":
				var m := StandardMaterial3D.new()
				m.albedo_color = Color(0.3, 0.3, 0.33)
				m.roughness = 0.9
				mi.set_surface_override_material(i, m)
	body.add_child(mi)
	add_child(body)

func activate(at: Vector3) -> void:
	active = true
	visible = true
	body.collision_layer = 4
	global_position = at

func deactivate() -> void:
	active = false
	visible = false
	body.collision_layer = 0

## 演出用にその場へ置く（そこから道路へ歩いて戻る）
func place(pos: Vector3) -> void:
	global_position = pos

## カメラが男の方を向いているか（水平の角度と距離だけで見る）
static func is_looked_at(cam_pos: Vector3, cam_forward: Vector3, npc_pos: Vector3) -> bool:
	var to := Vector3(npc_pos.x - cam_pos.x, 0, npc_pos.z - cam_pos.z)
	var fwd := Vector3(cam_forward.x, 0, cam_forward.z)
	if to.length() > NOTICE_DIST or to.length() < 0.01 or fwd.length() < 0.01:
		return to.length() < 0.01
	return rad_to_deg(fwd.angle_to(to)) <= LOOK_DEG

static func next_position(npc: Vector3, player: Vector3, player_forward: Vector3, looked_at: bool, player_indoor: bool, delta: float) -> Vector3:
	if looked_at or player_indoor:
		return npc
	var to := Vector3(player.x - npc.x, 0, player.z - npc.z)
	var dist := to.length()
	var p := npc
	if dist > TELEPORT_DIST:
		var back := Vector3(-player_forward.x, 0, -player_forward.z)
		back = back.normalized() if back.length() > 0.01 else Vector3(-1, 0, 0)
		p = Vector3(player.x, npc.y, player.z) + back * BEHIND
		return Vector3(clampf(p.x, MIN_X, MAX_X), p.y, clampf(p.z, -BAND_Z, BAND_Z))
	if dist > KEEP:
		p = npc + to / dist * minf(SPEED * delta, dist - KEEP)
	p.x = clampf(p.x, MIN_X, MAX_X)
	if absf(npc.z) > BAND_Z:
		p.z = move_toward(npc.z, clampf(npc.z, -BAND_Z, BAND_Z), SPEED * delta)
	else:
		p.z = clampf(p.z, -BAND_Z, BAND_Z)
	return p

func _physics_process(delta: float) -> void:
	if not active:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var main := get_parent()
	var indoor: bool = main != null and int(main.get("_indoor_count") if "_indoor_count" in main else 0) > 0
	var fwd := -cam.global_basis.z
	var looked := is_looked_at(cam.global_position, fwd, global_position + Vector3(0, 1.2, 0))
	global_position = next_position(global_position, cam.global_position, fwd, looked, indoor, delta)
	var d := cam.global_position - global_position
	rotation.y = atan2(d.x, d.z)
