## 第2章の画面確認用：場面ごとに決まった位置からスクリーンショットを撮る。
## xvfb-run godot --path . --resolution 1280x720 -s tools/capture_ch2.gd -- <出力ディレクトリ> [ja|en]
extends SceneTree

var out := "user://shots_ch2"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	if args.size() > 1:
		TranslationServer.set_locale(args[1])
	var f := FileAccess.open("user://save_0.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "state": {"chapter": 2, "flags": {"goal_index": 12, "time_of_day": "dusk"}, "notebook": [], "relics_found": ["watch"], "relics": 1, "phone": ["bank_address"]}}))
	f.close()
	change_scene_to_file("res://scenes/island_slice.tscn")
	_run()

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))

## 足もとの位置 pos から target を見る
func _look(main, pos: Vector3, target: Vector3) -> void:
	main.player.global_position = pos
	main.player.velocity = Vector3.ZERO
	main.player.look_at(Vector3(target.x, pos.y, target.z))
	var head: Node3D = main.player.get_node("Head")
	var eye := head.global_position
	head.rotation.x = atan2(target.y - eye.y, Vector2(target.x - eye.x, target.z - eye.z).length())

func _run() -> void:
	await _wait(1.0)
	var main = current_scene
	main._start(true)
	await _wait(3.0)
	_look(main, Vector3(30, 0.1, 1.0), Vector3(50, 2.0, -1.0))
	await _wait(1.0)
	await _shot("20_dusk_street")
	_look(main, Vector3(4.2, 0.1, -0.8), Vector3(1.4, 1.2, -3.5))
	await _wait(1.0)
	await _shot("21_old_man")
	main.ch2.open_east()
	_look(main, Vector3(64, 0.1, 0.5), Vector3(100, 2.5, -2.0))
	await _wait(1.0)
	await _shot("22_east_road")
	_look(main, Vector3(78, 0.15, 6.0), Vector3(78.6, 1.3, 8.6))
	main.get_node("Ch2/Returnee").visible = true
	await _wait(1.0)
	await _shot("23_dorm_dining")
	_look(main, Vector3(94, 0.1, -0.5), Vector3(97, 1.3, -8))
	await _wait(1.0)
	await _shot("24_ruins")
	_look(main, Vector3(98.5, 0.15, -7.6), Vector3(100.6, 0.8, -11))
	await _wait(1.0)
	await _shot("25_row2_inside")
	TimeOfDay.apply(main, &"night")
	_look(main, Vector3(116, 0.1, 3.0), Vector3(119, 2.5, -6))
	await _wait(1.0)
	await _shot("26_plant_night")
	_look(main, Vector3(121, 0.15, -11), Vector3(121.5, 1.3, -17.5))
	await _wait(1.0)
	await _shot("27_switchboard")
	main.ch2.grid.cut()
	main.player.get_node("Head/HandLight").visible = true
	_look(main, Vector3(116, 0.1, 3.0), Vector3(119, 2.0, -6))
	await _wait(1.0)
	await _shot("28_blackout")
	main.player.get_node("Head/HandLight").visible = false
	await main.ch2.grid.restore(main.player.global_position, main.get_node("East/PlantLamp"), 0.02, 0.1)
	main.ch2.start_following(Chapter2.UNDER_PLANT_LAMP)
	await _wait(1.0)
	await _shot("29_returnee_back")
	_look(main, Vector3(55, 0.1, 5.0), Vector3(55, 1.4, -9))
	await _wait(1.0)
	var img: Image = await PhotoCapture.capture(main, Chapter2.PHOTO_CAM, Chapter2.PHOTO_TARGET, Vector3(55, 0.05, 5.0))
	main.ch2.popup.show_note(main.ch2.feed.note(&"sns_like"), ImageTexture.create_from_image(img))
	await _wait(0.5)
	await _shot("30_photo_post")
	main.ch2.popup._post.visible = false
	main.notebook.visible = true
	main.notebook._rebuild()
	await _wait(0.5)
	await _shot("31_notebook")
	DirAccess.remove_absolute("user://save_0.json")
	quit()
