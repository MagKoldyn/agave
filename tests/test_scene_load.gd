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
	if scene.get_script() == null:
		failures += 1
		push_error("FAIL: корневой скрипт сцены не скомпилирован: " + path)
	if path.ends_with("title.tscn"):
		var title_map: TextureRect = scene.get_node("Backdrop")
		if title_map.texture == null:
			failures += 1
			push_error("FAIL: пиксельный фон меню не импортирован")
		else:
			print("PASS: пиксельный фон меню импортирован")
	if path.ends_with("farm.tscn"):
		var map: TextureRect = scene.get_node("Background/Map")
		if map.texture == null or map.texture.get_size().x < 1000:
			failures += 1
			push_error("FAIL: фон фермы не импортирован")
		else:
			print("PASS: фон фермы импортирован ", map.texture.get_size())
		var sprite_count := 0
		for actor in scene.get_node("World").get_children():
			sprite_count += actor.find_children("*", "Sprite2D", true, false).size()
		if sprite_count < 2:
			failures += 1
			push_error("FAIL: пиксельные персонажи не созданы")
		else:
			print("PASS: созданы пиксельные персонажи: ", sprite_count)
	print("PASS: загружена сцена " + path)
	scene.queue_free()
	await process_frame

func run() -> void:
	await check_scene("res://scenes/title.tscn")
	await check_scene("res://scenes/farm.tscn")
	print("RESULT: %d scene failure(s)" % failures)
	quit(1 if failures else 0)
