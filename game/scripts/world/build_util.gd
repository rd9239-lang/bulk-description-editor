## 地形や建物を箱で組み立てるときの共通処理（島の通りと東地区で使う）。
class_name BuildUtil
extends RefCounted

## 当たり判定つきの箱。look は質感一覧の名前（data/materials.json）
static func box_body(parent: Node, name: String, size: Vector3, pos: Vector3, look: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = MaterialLibrary.material(look)
	mi.mesh = bm
	body.add_child(mi)
	col(body, size, Vector3.ZERO)
	parent.add_child(body)
	return body

static func col(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	body.add_child(cs)

## 電柱や街灯の柱の当たり判定
static func pole_collision(parent: Node3D, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	cs.position.y = height / 2
	body.add_child(cs)
	parent.add_child(body)

## 屋内の範囲：入ると main.set_player_indoor(true)、出ると false（外の音がこもる）
static func indoor_area(parent: Node3D, name: String, size: Vector3, pos: Vector3, main: Node) -> Area3D:
	var a := Area3D.new()
	a.name = name
	a.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	a.add_child(cs)
	a.body_entered.connect(func(b): if b is Player: main.set_player_indoor(true))
	a.body_exited.connect(func(b): if b is Player: main.set_player_indoor(false))
	parent.add_child(a)
	return a
