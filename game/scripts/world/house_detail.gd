## 家の作り込み：切妻のトタン屋根と軒、妻壁、天井、基礎、雨どい。
## 家のローカル座標で、正面（道路側）が z=0、幅 w は +x、奥行き d は +z。
class_name HouseDetail
extends RefCounted

const WALL_H := 2.6
const PITCH_DEG := 24.0
const EAVE := 0.45     # 軒の出（前後）
const VERGE := 0.3     # けらばの出（左右）

static func _mesh(parent: Node3D, name: String, mesh: Mesh, pos: Vector3, look: String, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.material_override = MaterialLibrary.material(look)
	parent.add_child(mi)
	return mi

static func _box(parent: Node3D, name: String, size: Vector3, pos: Vector3, look: String, rot := Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _mesh(parent, name, bm, pos, look, rot)

## front_pieces は正面の部品名の列（Door_Frame の前には基礎を置かない）
static func add(house: Node3D, w: float, d: float, front_pieces: Array) -> void:
	var t := tan(deg_to_rad(PITCH_DEG))
	var rise := d / 2.0 * t
	var ridge_y := WALL_H + 0.04 + rise
	var eave_y := WALL_H + 0.04 - EAVE * t
	var slope_len := (d / 2.0 + EAVE) / cos(deg_to_rad(PITCH_DEG))
	var roof_w := w + VERGE * 2
	# 屋根（前後の斜面）と棟
	_box(house, "RoofL", Vector3(roof_w, 0.04, slope_len), Vector3(w / 2, (ridge_y + eave_y) / 2, (d / 2 - EAVE) / 2), "tin_roof", Vector3(deg_to_rad(-PITCH_DEG), 0, 0))
	_box(house, "RoofR", Vector3(roof_w, 0.04, slope_len), Vector3(w / 2, (ridge_y + eave_y) / 2, (d / 2 + d + EAVE) / 2), "tin_roof", Vector3(deg_to_rad(PITCH_DEG), 0, 0))
	_box(house, "Ridge", Vector3(roof_w, 0.07, 0.2), Vector3(w / 2, ridge_y + 0.03, d / 2), "painted_metal")
	# 妻壁（左右の三角の壁）
	for side in [["GableL", 0.0], ["GableR", w]]:
		var pm := PrismMesh.new()
		pm.size = Vector3(d, rise, 0.12)
		_mesh(house, side[0], pm, Vector3(side[1], WALL_H + rise / 2, d / 2), "plank", Vector3(0, PI / 2, 0))
	# 鼻隠し（軒先の板）
	_box(house, "FasciaFront", Vector3(roof_w, 0.16, 0.03), Vector3(w / 2, eave_y - 0.05, -EAVE + 0.02), "plank_dark")
	_box(house, "FasciaBack", Vector3(roof_w, 0.16, 0.03), Vector3(w / 2, eave_y - 0.05, d + EAVE - 0.02), "plank_dark")
	# 天井
	_box(house, "Ceiling", Vector3(w, 0.03, d), Vector3(w / 2, WALL_H - 0.02, d / 2), "plank_dark")
	# 基礎（壁の外側の低いコンクリート）
	var found := Node3D.new()
	found.name = "Foundation"
	house.add_child(found)
	for i in front_pieces.size():
		if front_pieces[i] != "Door_Frame":
			_box(found, "F%d" % i, Vector3(2.0, 0.22, 0.06), Vector3(1 + i * 2, 0.11, -0.09), "concrete")
	_box(found, "Back", Vector3(w + 0.12, 0.22, 0.06), Vector3(w / 2, 0.11, d + 0.09), "concrete")
	_box(found, "Left", Vector3(0.06, 0.22, d + 0.12), Vector3(-0.09, 0.11, d / 2), "concrete")
	_box(found, "Right", Vector3(0.06, 0.22, d + 0.12), Vector3(w + 0.09, 0.11, d / 2), "concrete")
	# 雨どいと縦どい
	var gutter := Node3D.new()
	gutter.name = "Gutter"
	house.add_child(gutter)
	_box(gutter, "Trough", Vector3(roof_w, 0.08, 0.1), Vector3(w / 2, eave_y - 0.12, -EAVE - 0.03), "painted_metal")
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.035
	pipe.bottom_radius = 0.035
	pipe.height = eave_y - 0.12
	_mesh(gutter, "Downpipe", pipe, Vector3(-VERGE + 0.1, (eave_y - 0.12) / 2, -EAVE - 0.03), "painted_metal")
