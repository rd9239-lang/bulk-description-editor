extends GutTest

func test_capture_returns_image_of_size_and_cleans_up():
	var scene := Node3D.new()
	add_child(scene)
	var before := scene.get_child_count()
	var img: Image = await PhotoCapture.capture(scene, Vector3(0, 1.6, -8), Vector3(0, 1.4, 4), Vector3(0, 0, 5))
	assert_true(img != null)
	assert_eq(img.get_size(), PhotoCapture.SIZE)
	await get_tree().process_frame
	var left := 0
	for c in scene.get_children():
		if not c.is_queued_for_deletion():
			left += 1
	assert_eq(left, before, "viewport and stand-in removed")
	scene.queue_free()
