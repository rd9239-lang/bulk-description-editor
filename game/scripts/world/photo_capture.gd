## 「自分の窓の写真」：路地のカメラから家の窓を1枚撮る。撮る間だけ、プレイヤーの位置に人影を立てる。
## 画像が取れないとき（ヘッドレスなど）は暗い灰色の画像を返す。
class_name PhotoCapture
extends RefCounted

const SIZE := Vector2i(640, 400)

static func capture(scene: Node3D, cam_pos: Vector3, target: Vector3, stand_in_pos: Vector3) -> Image:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var cam := Camera3D.new()
	cam.fov = 50.0
	vp.add_child(cam)
	scene.add_child(vp)
	cam.global_position = cam_pos
	cam.look_at(target)
	cam.current = true
	var stand_in := MeshInstance3D.new()
	stand_in.mesh = StreetDressing.mesh("Mannequin_F")
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.06, 0.06, 0.07)
	dark.roughness = 1.0
	stand_in.material_override = dark
	scene.add_child(stand_in)
	stand_in.global_position = stand_in_pos
	stand_in.rotation.y = atan2(cam_pos.x - stand_in_pos.x, cam_pos.z - stand_in_pos.z)
	for i in 3:
		await scene.get_tree().process_frame
	var img := vp.get_texture().get_image() if vp.get_texture() else null
	stand_in.queue_free()
	vp.queue_free()
	if img == null or img.is_empty():
		img = Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
		img.fill(Color(0.12, 0.12, 0.13))
	elif img.get_size() != SIZE:
		img.resize(SIZE.x, SIZE.y)
	return img
