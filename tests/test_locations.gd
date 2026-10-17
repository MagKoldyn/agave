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

func open_location(path: String) -> Node:
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	await process_frame
	return scene

func close_location(scene: Node) -> void:
	scene.queue_free()
	await process_frame

func run() -> void:
	var state := root.get_node("GameState")
	state.reset_state()
	state.quest_index = 5
	var home := await open_location("res://scenes/home_interior.tscn")
	home.interact_home("journal")
	check(state.quest_index == 6 and state.flags.journal_found, "дневник находится внутри дома")
	check(int(state.inventory.get("quest_grandfather_journal", 0)) == 1, "дневник добавляется в инвентарь")
	home.close_dialog()
	await create_timer(0.25).timeout
	await close_location(home)

	var workshop := await open_location("res://scenes/workshop_interior.tscn")
	workshop.interact_workshop("bench")
	check(state.quest_index == 7 and state.flags.channel_repaired, "ремонт выполняется у верстака мастерской")
	await create_timer(0.65).timeout
	state.quest_index = 9
	state.inventory["crop_agave_sun"] = 2
	workshop.interact_workshop("still")
	check(state.quest_index == 10 and int(state.inventory.get("product_agave_syrup", 0)) == 1, "сироп варится внутри мастерской")
	await create_timer(0.65).timeout
	await close_location(workshop)

	var market := await open_location("res://scenes/market_interior.tscn")
	var money_before: int = state.money
	market.interact_market("counter")
	check(state.quest_index == 11 and state.money == money_before + 58, "сироп продаётся за прилавком рынка")
	await create_timer(0.65).timeout
	await close_location(market)

	print("RESULT: %d location failure(s)" % failures)
	quit(1 if failures else 0)
