## 第2章で開く東地区：道路の延長、寮、炭鉱住宅の廃墟（長屋3棟）、発電所跡、工事柵、港のベンチ。
## 建物は質感つきの箱で組み、小物は east_props.glb の部品を置く。調べる物の当たりは Chapter2 が足す。
class_name EastDistrict
extends RefCounted

const PROPS := preload("res://assets/models/east_props.glb")
const STREETLIGHT := preload("res://assets/models/streetlight.glb")
const POLE := preload("res://assets/models/pole.glb")

## 街灯：位置 → 種類
const LAMPS := {
	Vector3(76, 0, -2.6): "steady", Vector3(88, 0, -2.6): "flicker",
	Vector3(100, 0, -2.6): "steady", Vector3(112, 0, -2.6): "flicker",
}
const PLANT_LAMP := Vector3(118, 0, -4.5)
const ROW_CENTERS := [91.5, 99.5, 107.5]

static var _meshes := {}

static func mesh(name: String) -> Mesh:
	if _meshes.is_empty():
		var root := PROPS.instantiate()
		for c in root.get_children():
			if c is MeshInstance3D:
				_meshes[String(c.name)] = (c as MeshInstance3D).mesh
		root.free()
	return _meshes.get(name)

## 部品を置く。col_size があれば底面から立つ箱の当たりをつける
static func prop(parent: Node3D, name: String, piece: String, pos: Vector3, rot_y_deg := 0.0, col_size := Vector3.ZERO) -> Node3D:
	var root: Node3D
	if col_size != Vector3.ZERO:
		var body := StaticBody3D.new()
		BuildUtil.col(body, col_size, Vector3(0, col_size.y / 2, 0))
		root = body
	else:
		root = Node3D.new()
	root.name = name
	var mi := MeshInstance3D.new()
	mi.mesh = mesh(piece)
	root.add_child(mi)
	parent.add_child(root)
	root.position = pos
	root.rotation_degrees.y = rot_y_deg
	return root

static func build(main: Node3D) -> Node3D:
	var east := Node3D.new()
	east.name = "East"
	main.add_child(east)
	BuildUtil.box_body(east, "Ground", Vector3(60, 1, 40), Vector3(105, -0.5, 0), "gravel").set_meta("surface", "gravel")
	BuildUtil.box_body(east, "Road", Vector3(57, 0.02, 4), Vector3(96.5, 0.01, 0), "asphalt").set_meta("surface", "asphalt")
	var bounds := StaticBody3D.new()
	bounds.name = "Bounds"
	east.add_child(bounds)
	BuildUtil.col(bounds, Vector3(67, 4, 0.4), Vector3(101.5, 2, 19.5))
	BuildUtil.col(bounds, Vector3(67, 4, 0.4), Vector3(101.5, 2, -19.5))
	BuildUtil.col(bounds, Vector3(0.4, 4, 40), Vector3(134.5, 2, 0))
	_barrier(east)
	_lamps(east)
	_dorm(east, main)
	for i in ROW_CENTERS.size():
		_row(east, main, i + 1, ROW_CENTERS[i])
	_plant(east, main)
	var harbor := Node3D.new()
	harbor.name = "Harbor"
	main.add_child(harbor)
	prop(harbor, "Bench", "Bench", Vector3(2, 0, -3.5), -90, Vector3(1.6, 0.47, 0.4))
	return east

## 第1章までの通行止め。見た目は道路の幅だけ、当たりは島の端から端まで
static func _barrier(east: Node3D) -> void:
	var b := StaticBody3D.new()
	b.name = "Barrier"
	b.position = Vector3(68.5, 0, 0)
	east.add_child(b)
	for z in [-3.0, -1.0, 1.0, 3.0]:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh("Barrier")
		mi.position = Vector3(0, 0, z)
		mi.rotation_degrees.y = 90
		b.add_child(mi)
	BuildUtil.col(b, Vector3(0.4, 3, 40), Vector3(0, 1.5, 0))

static func set_east_open(main: Node3D, open: bool) -> void:
	var b := main.get_node_or_null("East/Barrier") as StaticBody3D
	if b:
		b.visible = not open
		b.collision_layer = 0 if open else 1

static func _lamp(east: Node3D, name: String, pos: Vector3, kind: String) -> Streetlight:
	var lamp := Streetlight.new()
	lamp.name = name
	lamp.position = pos
	lamp.rotation_degrees.y = -90
	lamp.add_child(STREETLIGHT.instantiate())
	if kind == "flicker":
		var f := Flicker.new()
		f.seed = int(pos.x)
		lamp.add_child(f)
	BuildUtil.pole_collision(lamp, 0.15, 5.4)
	east.add_child(lamp)
	return lamp

static func _lamps(east: Node3D) -> void:
	for pos in LAMPS:
		_lamp(east, "Lamp%d" % int(pos.x), pos, LAMPS[pos])
	_lamp(east, "PlantLamp", PLANT_LAMP, "steady")
	# 電柱と電線（通りの最後の電柱 x=72 から続ける）
	var prev_pos := Vector3(72, 0, -4.4)
	var probe := POLE.instantiate() as Node3D
	var l := (probe.find_child("WireAnchor_L") as Node3D).position
	var r := (probe.find_child("WireAnchor_R") as Node3D).position
	probe.free()
	for x in [88.0, 104.0, 120.0]:
		var pole := POLE.instantiate() as Node3D
		pole.position = Vector3(x, 0, -4.4)
		east.add_child(pole)
		StreetDressing.wire(east, prev_pos + l, pole.position + l, 0.55)
		StreetDressing.wire(east, prev_pos + r, pole.position + r, 0.55)
		prev_pos = pole.position

## 寮：2階建てのコンクリート造。1階の食堂だけ入れる
static func _dorm(east: Node3D, main: Node3D) -> void:
	var d := Node3D.new()
	d.name = "Dorm"
	east.add_child(d)
	var c := "concrete"
	BuildUtil.box_body(d, "WallFrontL", Vector3(5.4, 6, 0.2), Vector3(74.7, 3, 5.1), c)
	BuildUtil.box_body(d, "WallFrontR", Vector3(5.4, 6, 0.2), Vector3(81.3, 3, 5.1), c)
	BuildUtil.box_body(d, "WallFrontTop", Vector3(1.2, 3.8, 0.2), Vector3(78, 4.1, 5.1), c)
	BuildUtil.box_body(d, "WallBack", Vector3(12, 6, 0.2), Vector3(78, 3, 12.9), c)
	BuildUtil.box_body(d, "WallLeft", Vector3(0.2, 6, 8), Vector3(72.1, 3, 9), c)
	BuildUtil.box_body(d, "WallRight", Vector3(0.2, 6, 8), Vector3(83.9, 3, 9), c)
	BuildUtil.box_body(d, "Ceiling", Vector3(12, 0.2, 8), Vector3(78, 3.0, 9), c)
	BuildUtil.box_body(d, "Roof", Vector3(12.4, 0.2, 8.4), Vector3(78, 6.1, 9), c)
	BuildUtil.box_body(d, "Floor", Vector3(11.6, 0.05, 7.6), Vector3(78, 0.025, 9), "wood_floor").set_meta("surface", "wood")
	BuildUtil.box_body(d, "Canopy", Vector3(2.4, 0.1, 1.2), Vector3(78, 2.6, 4.4), c)
	for x in [73.8, 76.2, 79.8, 82.2]:
		_glass(d, Vector3(1.2, 1.0, 0.04), Vector3(x, 4.4, 4.98))
	for x in [74.5, 81.5]:
		_glass(d, Vector3(1.4, 1.0, 0.04), Vector3(x, 1.6, 4.98))
	# 外階段（右側の壁沿いに2階へ）
	for i in 10:
		BuildUtil.box_body(d, "Step%d" % i, Vector3(1.0, 0.3, 0.6), Vector3(84.7, 0.15 + i * 0.3, 6.0 + i * 0.6), c)
	prop(d, "LongTable", "LongTable", Vector3(78, 0.05, 10), 0, Vector3(3, 0.75, 0.8))
	prop(d, "LongBench1", "LongBench", Vector3(78, 0.05, 9.2), 0, Vector3(3, 0.44, 0.3))
	prop(d, "LongBench2", "LongBench", Vector3(78, 0.05, 10.8), 0, Vector3(3, 0.44, 0.3))
	_room_light(d, Vector3(78, 2.7, 9), Color(1.0, 0.88, 0.7), 1.3, 8.0)
	BuildUtil.indoor_area(d, "Interior", Vector3(11.6, 2.8, 7.6), Vector3(78, 1.4, 9), main)

## 炭鉱住宅の長屋（道路の南側）。2棟目だけ中に入れる
static func _row(east: Node3D, main: Node3D, index: int, cx: float) -> void:
	var r := Node3D.new()
	r.name = "Row%d" % index
	east.add_child(r)
	var front := -7.0
	var back := -12.0
	var mid := (front + back) / 2
	var open := index == 2
	if open:
		BuildUtil.box_body(r, "WallFrontL", Vector3(2.9, 2.6, 0.15), Vector3(cx - 2.05, 1.3, front), "plank_dark")
		BuildUtil.box_body(r, "WallFrontR", Vector3(3.1, 2.6, 0.15), Vector3(cx + 1.95, 1.3, front), "plank_dark")
		BuildUtil.box_body(r, "WallFrontTop", Vector3(1.0, 0.5, 0.15), Vector3(cx, 2.35, front), "plank_dark")
	else:
		BuildUtil.box_body(r, "WallFront", Vector3(7, 2.6, 0.15), Vector3(cx, 1.3, front), "plank_dark")
		prop(r, "DoorBoards", "BoardedWindow", Vector3(cx, 0.0, front + 0.1), 0)
	BuildUtil.box_body(r, "WallBack", Vector3(7, 2.6, 0.15), Vector3(cx, 1.3, back), "plank_dark")
	BuildUtil.box_body(r, "WallLeft", Vector3(0.15, 2.6, 5), Vector3(cx - 3.5, 1.3, mid), "plaster")
	BuildUtil.box_body(r, "WallRight", Vector3(0.15, 2.6, 5), Vector3(cx + 3.5, 1.3, mid), "plaster")
	BuildUtil.box_body(r, "Floor", Vector3(6.8, 0.05, 4.8), Vector3(cx, 0.025, mid), "wood_floor").set_meta("surface", "wood")
	for dx in [-2.3, 2.3]:
		prop(r, "Window%d" % int(dx), "BoardedWindow", Vector3(cx + dx, 0.8, front + 0.1), 0)
	# 屋根：左半分は残り、右半分は崩れかけ（2棟目は穴から空が見える）
	var roof := BuildUtil.box_body(r, "Roof", Vector3(3.6, 0.06, 5.4), Vector3(cx - 1.75, 2.75, mid), "tin_roof")
	roof.rotation_degrees.x = 6
	for k in 2:
		prop(r, "RoofBroken%d" % k, "RoofBroken", Vector3(cx + 0.9 + k * 2.0, 2.75, mid + (1.2 if open else 0.0)), 90 if k == 0 else 0)
	if open:
		prop(r, "Desk", "LongTable", Vector3(cx + 1.0, 0.05, back + 1.0), 0, Vector3(3, 0.75, 0.8))
		BuildUtil.indoor_area(r, "Interior", Vector3(6.6, 2.4, 4.6), Vector3(cx, 1.2, mid), main)
		prop(r, "NoticeBoard", "NoticeBoard", Vector3(95, 0, -5.5), 0, Vector3(1.4, 1.9, 0.2))

## 発電所跡：煙突つきの建屋。中に配電盤、古い線、ロッカー
static func _plant(east: Node3D, main: Node3D) -> void:
	var p := Node3D.new()
	p.name = "Plant"
	east.add_child(p)
	var c := "concrete"
	BuildUtil.box_body(p, "WallFrontL", Vector3(3.3, 7, 0.3), Vector3(115.65, 3.5, -6), c)
	BuildUtil.box_body(p, "WallFrontR", Vector3(9.3, 7, 0.3), Vector3(123.35, 3.5, -6), c)
	BuildUtil.box_body(p, "WallFrontTop", Vector3(1.4, 4.4, 0.3), Vector3(118, 4.8, -6), c)
	BuildUtil.box_body(p, "WallBack", Vector3(14, 7, 0.3), Vector3(121, 3.5, -18), c)
	BuildUtil.box_body(p, "WallLeft", Vector3(0.3, 7, 12), Vector3(114, 3.5, -12), c)
	BuildUtil.box_body(p, "WallRight", Vector3(0.3, 7, 12), Vector3(128, 3.5, -12), c)
	BuildUtil.box_body(p, "Floor", Vector3(13.6, 0.05, 11.6), Vector3(121, 0.025, -12), c)
	var roof := BuildUtil.box_body(p, "Roof", Vector3(14.6, 0.1, 12.6), Vector3(121, 7.05, -12), "tin_roof")
	roof.rotation_degrees.z = 3
	for x in [116.5, 120.5, 124.5]:
		_glass(p, Vector3(2.4, 0.8, 0.04), Vector3(x + 0.5, 5.6, -5.83))
	prop(p, "Switchboard", "Switchboard", Vector3(121, 0.05, -17.6), 0, Vector3(2.4, 2.0, 0.3))
	prop(p, "OldWire", "OldWire", Vector3(124, 0.05, -17.7), 0)
	prop(p, "Locker", "Locker", Vector3(114.5, 0.05, -12), 90, Vector3(0.9, 1.8, 0.5))
	prop(p, "Chimney", "Chimney", Vector3(131, 0, -14), 0, Vector3(2.2, 18, 2.2))
	_room_light(p, Vector3(121, 5.0, -12), Color(0.85, 0.92, 1.0), 1.2, 12.0)
	BuildUtil.indoor_area(p, "Interior", Vector3(13.6, 6, 11.6), Vector3(121, 3, -12), main)

static func _glass(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = MaterialLibrary.material("glass")
	mi.mesh = bm
	mi.position = pos
	parent.add_child(mi)

static func _room_light(parent: Node3D, pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.add_to_group("room_lights")
	GraphicsSettings.configure_lamp(lamp, GraphicsSettings.quality)
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = light_range
	lamp.position = pos
	parent.add_child(lamp)
