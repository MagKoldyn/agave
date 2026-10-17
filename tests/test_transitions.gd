extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	check(main.current_scene.name == "Title", "игра начинается с главного меню")
	await main.start_new_game()
	check(main.current_scene.name == "Farm", "из меню загружается ферма-хаб")
	await main.enter_interior("workshop")
	check(main.current_scene.name == "WorkshopInterior", "мастерская загружается отдельной сценой")
	check(main.current_scene.location_id == "workshop", "сцена сохраняет идентификатор локации")
	await main.show_farm("workshop")
	check(main.current_scene.name == "Farm", "из интерьера можно вернуться на ферму")
	var player: CharacterBody2D = main.current_scene.player
	check(player.position.distance_to(Vector2(525, 220)) < 2.0, "возврат ставит героя у нужного входа")
	print("RESULT: %d transition failure(s)" % failures)
	quit(1 if failures else 0)
