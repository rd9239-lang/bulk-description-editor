## 電線。2点のあいだを、真ん中が sag メートル垂れ下がる曲線でつなぐ。
class_name Wires
extends RefCounted

const RADIUS := 0.009
const SIDES := 6

static func sag_points(a: Vector3, b: Vector3, sag: float, segments: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in segments + 1:
		var t := float(i) / segments
		pts.append(a.lerp(b, t) - Vector3.UP * sag * 4.0 * t * (1.0 - t))
	return pts

## 細い管のメッシュとして電線を作る（座標はそのまま世界座標として置く）
static func make_wire(a: Vector3, b: Vector3, sag: float, segments: int = 12) -> MeshInstance3D:
	var pts := sag_points(a, b, sag, segments)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i in pts.size():
		var dir := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var side := dir.cross(Vector3.UP).normalized()
		var up := side.cross(dir).normalized()
		var ring := PackedVector3Array()
		for k in SIDES:
			var ang := TAU * k / SIDES
			ring.append(pts[i] + (side * cos(ang) + up * sin(ang)) * RADIUS)
		rings.append(ring)
	for i in pts.size() - 1:
		for k in SIDES:
			var k2 := (k + 1) % SIDES
			for v in [rings[i][k], rings[i + 1][k], rings[i + 1][k2], rings[i][k], rings[i + 1][k2], rings[i][k2]]:
				st.add_vertex(v)
	st.generate_normals()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.02, 0.02, 0.02)
	m.roughness = 0.6
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
