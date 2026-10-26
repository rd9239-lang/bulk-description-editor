## テストランナー：res://tests 以下の test_*.gd を実行し、失敗があれば終了コード 1。
## 使い方: godot --headless --path game -s addons/minitest/run.gd [-- filter]
extends SceneTree

func _initialize() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]
	var files: Array[String] = []
	_collect("res://tests", files)
	files.sort()
	var total := 0
	var failed: Array[String] = []
	for path in files:
		if filter != "" and not path.contains(filter):
			continue
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			failed.append("%s: failed to load" % path)
			continue
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			var t: GutTest = script.new()
			root.add_child(t)
			t._current = "%s::%s" % [path.get_file(), name]
			t.before_each()
			var r = t.call(name)
			if r is Object and r.get_class() == "GDScriptFunctionState":
				await r.completed
			elif typeof(r) == TYPE_SIGNAL:
				pass
			t.after_each()
			total += 1
			failed.append_array(t._failures)
			t.queue_free()
			await process_frame
	for f in failed:
		print("FAIL ", f)
	print("%d tests, %d failures" % [total, failed.size()])
	quit(1 if failed.size() > 0 else 0)

func _collect(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		_collect(dir.path_join(sub), out)
