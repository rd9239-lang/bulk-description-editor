## 通りの作り込み：ブロック塀、側溝のふた、白線、路地の舗装と「止まれ」、カーブミラー、電線。
class_name StreetDressing
extends RefCounted

const PROPS := preload("res://assets/models/street_props.glb")
const STOP_TEX := preload("res://assets/textures/stop_marking.png")

## 道路側の塀を置く区間（家と家のすき間）。x の [始め, 終わり] と z
const FRONT_WALLS := [[0, 8], [14, 20], [28, 32], [38, 54], [60, 66]]
const BACK_WALLS := [[0, 8], [14, 34], [40, 52], [58, 66]]
const FRONT_Z := 4.0
const BACK_Z := -6.0
## 自宅の窓の正面にのびる行き止まりの路地
const ALLEY_X := 55.0
const ALLEY_END_Z := -12.0

static var _meshes := {}

static func mesh(name: String) -> Mesh:
	if _meshes.is_empty():
		var root := PROPS.instantiate()
		for c in root.get_children():
			if c is MeshInstance3D:
				_meshes[String(c.name)] = (c as MeshInstance3D).mesh
		root.free()
	return _meshes.get(name)

static func place(parent: Node3D, name: String, piece: String, pos: Vector3, rot_y_deg: float, col_size := Vector3.ZERO) -> Node3D:
	var root: Node3D
	if col_size != Vector3.ZERO:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = col_size
		cs.shape = shape
		cs.position.y = col_size.y / 2
		body.add_child(cs)
		root = body
	else:
		root = Node3D.new()
	root.name = name
	root.position = pos
	root.rotation_degrees.y = rot_y_deg
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh(piece)
	root.add_child(mi)
	parent.add_child(root)
	return root

static func build(parent: Node3D) -> void:
	_walls(parent)
	_alley(parent)
	_road(parent)

static func _wall_run(parent: Node3D, x0: float, x1: float, z: float, rot: float) -> void:
	var n := int(round((x1 - x0) / 2.0))
	for i in n:
		var c := x0 + 1.0 + i * 2.0
		var pos := Vector3(c, 0, z) if rot == 0.0 else Vector3(z, 0, c)
		var w := place(parent, "BlockWall_%d_%d" % [int(pos.x * 10), int(pos.z * 10)], "BlockWall_2m", pos, rot, Vector3(2.0, 1.26, 0.19))
		w.add_to_group("block_walls")

static func _walls(parent: Node3D) -> void:
	for r in FRONT_WALLS:
		_wall_run(parent, r[0], r[1], FRONT_Z, 0.0)
	for r in BACK_WALLS:
		_wall_run(parent, r[0], r[1], BACK_Z, 0.0)
	# 路地の両側と突き当たり
	_wall_run(parent, ALLEY_END_Z, BACK_Z, ALLEY_X - 2.1, 90.0)
	_wall_run(parent, ALLEY_END_Z, BACK_Z, ALLEY_X + 2.1, 90.0)
	_wall_run(parent, ALLEY_X - 2.0, ALLEY_X + 2.0, ALLEY_END_Z, 0.0)

static func _flat(parent: Node3D, name: String, size: Vector3, pos: Vector3, look: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = MaterialLibrary.material(look)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _alley(parent: Node3D) -> void:
	_flat(parent, "AlleyPave", Vector3(4.0, 0.02, 10.0), Vector3(ALLEY_X, 0.012, -7.0), "asphalt")
	_flat(parent, "StopLine", Vector3(3.6, 0.006, 0.3), Vector3(ALLEY_X, 0.025, -2.75), "road_paint")
	var mark := MeshInstance3D.new()
	mark.name = "StopMarking"
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.4, 1.8)
	mark.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_texture = STOP_TEX
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.7
	mark.material_override = m
	# 路地から道路へ向かう人が読める向き
	mark.rotation_degrees.y = 180
	mark.position = Vector3(ALLEY_X, 0.026, -4.2)
	parent.add_child(mark)
	var mirror := place(parent, "CurveMirror", "CurveMirror", Vector3(ALLEY_X - 2.6, 0, -2.6), 135.0, Vector3(0.12, 3.0, 0.12))
	mirror.add_to_group("street_props")

static func _road(parent: Node3D) -> void:
	_flat(parent, "EdgeLineN", Vector3(69, 0.006, 0.12), Vector3(33.5, 0.024, 1.8), "road_paint")
	_flat(parent, "EdgeLineS", Vector3(69, 0.006, 0.12), Vector3(33.5, 0.024, -1.8), "road_paint")
	# 側溝のふた（道路の両脇、見た目だけ）
	for side in [-1, 1]:
		for i in 34:
			var x := 0.0 + i * 2.0
			if side < 0 and absf(x - ALLEY_X) < 2.5:
				continue
			place(parent, "Lid_%d_%d" % [side, i], "GutterLid_2m", Vector3(x, 0.0, side * 2.25), 0.0)

## 電柱どうし・電柱から家へ、たるんだ電線を張る
static func wire(parent: Node3D, a: Vector3, b: Vector3, sag: float) -> void:
	var w := Wires.make_wire(a, b, sag)
	w.add_to_group("wires")
	parent.add_child(w)
