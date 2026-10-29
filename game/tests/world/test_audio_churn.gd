extends GutTest
## 不具合の再現：場面を作ってすぐ消すのをくり返すと、ラジオの音の生成（AudioStreamGenerator）が
## 音声スレッドを止めてしまい、ゲーム全体が固まることがあった。

func test_scene_churn_does_not_deadlock_audio():
	for i in 30:
		var s = load("res://scenes/island_slice.tscn").instantiate()
		add_child(s)
		await get_tree().process_frame
		s.queue_free()
	var k := Knock.new()
	add_child(k)
	k.play_rhythm("island")
	assert_true(k.playing, "audio still responds after scene churn")
	k.queue_free()
