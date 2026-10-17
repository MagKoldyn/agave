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
		var player: CharacterBody2D = scene.get("player")
		var player_sprite: Sprite2D = player.get("sprite")
		if player_sprite.hframes != 4 or player_sprite.vframes != 4:
			failures += 1
			push_error("FAIL: атлас ходьбы героя не разбит на 4 × 4 кадра")
		else:
			print("PASS: атлас ходьбы содержит 16 направленных кадров")
		for model_path in [
			"res://assets/art/player_walk_sage.png",
			"res://assets/art/player_walk_ochre.png",
			"res://assets/art/player_walk_desert.png"
		]:
			if not ResourceLoader.exists(model_path):
				failures += 1
				push_error("FAIL: отсутствует вариант героя " + model_path)
		Input.action_press("move_right")
		Input.action_press("run")
		for i in 18:
			await physics_frame
		if player.velocity.x < 180.0:
			failures += 1
			push_error("FAIL: бег не набирает ожидаемую скорость")
		else:
			print("PASS: ходьба, бег и плавное ускорение активны")
		Input.action_release("move_right")
		Input.action_release("run")
		Input.action_press("move_right")
		Input.action_press("move_down")
		Input.action_press("run")
		for i in 18:
			await physics_frame
		var diagonal_speed := player.velocity.length()
		if player.velocity.x < 100.0 or player.velocity.y < 100.0 or absf(diagonal_speed - 225.0) > 8.0:
			failures += 1
			push_error("FAIL: диагональный бег не нормализован")
		else:
			print("PASS: диагональный бег работает без ускорения по сумме осей")
		Input.action_release("move_right")
		Input.action_release("move_down")
		Input.action_release("run")
		var state := root.get_node("GameState")
		state.water = 0
		player.position = Vector2(145, 400)
		var mouse_click := InputEventMouseButton.new()
		mouse_click.button_index = MOUSE_BUTTON_LEFT
		mouse_click.pressed = true
		mouse_click.position = Vector2(145, 342)
		scene._unhandled_input(mouse_click)
		if state.water != state.max_water:
			failures += 1
			push_error("FAIL: клик мышью не активирует объект мира")
		else:
			print("PASS: клик мышью активирует объект мира")
		var door: Node2D = scene.get("home_door")
		var water: Node2D = scene.get("water_flow")
		if door == null or water == null:
			failures += 1
			push_error("FAIL: дверь или слой течения воды не созданы")
		else:
			print("PASS: интерактивная дверь и течение воды созданы")
	if path.contains("_interior.tscn"):
		var interior_map: TextureRect = scene.get_node("Background/Map")
		var interior_player: CharacterBody2D = scene.get("player")
		var targets: Array = scene.get("targets")
		if interior_map.texture == null or interior_map.texture.get_size().x < 1000:
			failures += 1
			push_error("FAIL: фон отдельной локации не импортирован: " + path)
		elif interior_player == null or targets.size() < 4:
			failures += 1
			push_error("FAIL: в локации нет героя или интерактивных объектов: " + path)
		else:
			print("PASS: отдельная локация готова: ", path, " · объектов: ", targets.size())
	print("PASS: загружена сцена " + path)
	scene.queue_free()
	await process_frame

func run() -> void:
	var mouse_interaction := false
	for input_event in InputMap.action_get_events("interact"):
		if input_event is InputEventMouseButton and input_event.button_index == MOUSE_BUTTON_LEFT:
			mouse_interaction = true
	if not mouse_interaction:
		failures += 1
		push_error("FAIL: взаимодействие не назначено на левую кнопку мыши")
	else:
		print("PASS: взаимодействие назначено на левую кнопку мыши")
	await check_scene("res://scenes/title.tscn")
	await check_scene("res://scenes/farm.tscn")
	await check_scene("res://scenes/home_interior.tscn")
	await check_scene("res://scenes/workshop_interior.tscn")
	await check_scene("res://scenes/market_interior.tscn")
	await check_scene("res://scenes/aqueduct_interior.tscn")
	print("RESULT: %d scene failure(s)" % failures)
	quit(1 if failures else 0)
