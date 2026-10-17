extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("run")

func check_scene(path: String) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		failures += 1
		push_error("FAIL: не загружается " + path)
		return
	var scene := packed.instantiate()
	if scene == null:
		failures += 1
		push_error("FAIL: не создаётся " + path)
		return
	root.add_child(scene)
	await process_frame
	print("PASS: загружена сцена " + path)
	scene.queue_free()
	await process_frame

func run() -> void:
	await check_scene("res://scenes/title.tscn")
	await check_scene("res://scenes/farm.tscn")
	print("RESULT: %d scene failure(s)" % failures)
	quit(1 if failures else 0)
