## 画面確認用：ゲームを起動して決まった位置からスクリーンショットを撮る。
## xvfb-run godot --path . --rendering-driver opengl3 -s tools/capture.gd -- <出力ディレクトリ>
extends SceneTree

var out := "user://shots"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	if args.size() > 1:
		TranslationServer.set_locale(args[1])
	change_scene_to_file("res://scenes/island_slice.tscn")
	_run()

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))

func _place(main, pos: Vector3, yaw: float, pitch: float) -> void:
	main.player.global_position = pos
	main.player.rotation_degrees.y = yaw
	main.player.get_node("Head").rotation_degrees.x = pitch

func _run() -> void:
	await _wait(1.0)
	var main = current_scene
	await _shot("00_title")
	main._start(false)
	await _wait(3.5)
	await _shot("01_pier")
	_place(main, Vector3(30, 0.1, 1.0), -90, 8)
	await _wait(1.0)
	await _shot("02_street")
	main.player.global_position = Vector3(55.2, 0.1, 5.0)
	await _wait(0.3)
	var lamp: Vector3 = main.get_node("Street/LampSOS").signal_point()
	var eye: Vector3 = main.player.get_node("Head").global_position
	main.player.look_at(Vector3(lamp.x, main.player.global_position.y, lamp.z))
	main.player.get_node("Head").rotation.x = atan2(lamp.y - eye.y, Vector2(lamp.x - eye.x, lamp.z - eye.z).length())
	await _wait(1.5)
	await _shot("03_home_window")
	_place(main, Vector3(23.5, 0.1, 5.2), -55, 8)
	await _wait(1.0)
	await _shot("04_museum")
	_place(main, Vector3(57.4, 0.1, 5.0), 200, -2)
	await _wait(0.5)
	main.dialogue.open("res://data/dialogue/ch1.json", "wife_ask")
	await _wait(0.5)
	await _shot("05_dialogue")
	main.dialogue._close()
	main.notebook.record(&"museum_hi")
	main.notebook.record(&"sos_a")
	main.notebook.record(&"oldman_nigero")
	main.notebook.visible = true
	await _wait(0.5)
	await _shot("06_notebook")
	main.notebook.visible = false
	_place(main, Vector3(57.3, 0.1, 4.6), 180, -14)
	await _wait(1.0)
	await _shot("07_home_props")
	_place(main, Vector3(56.2, 0.1, 5.3), 160, -32)
	await _wait(0.8)
	await _shot("08_table_closeup")
	quit()
