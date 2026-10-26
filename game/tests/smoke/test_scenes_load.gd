extends GutTest

func test_player_scene_instantiates():
	var p = load("res://scenes/parts/player.tscn").instantiate()
	assert_true(p is Player)
	assert_true(p.get_node("Head/Camera3D/Interactor") is Interactor)
	assert_true(p.get_node("SignalObserver") is SignalObserver)
	p.free()

func test_dialogue_box_builds():
	var b := DialogueBox.new()
	add_child(b)
	assert_false(b.visible)
	b.queue_free()
