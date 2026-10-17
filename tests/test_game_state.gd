extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var state = load("res://scripts/game_state.gd").new()
	root.add_child(state)
	state.reset_state()
	check(state.quest_steps.size() == 12, "цепочка содержит 12 активных целей")
	check(state.current_step().id == "meet_lucia", "глава начинается со встречи с Лусией")
	state.add_progress()
	check(state.current_step().id == "clear_field", "цель меняется без ожидания")
	for i in 3: state.add_progress()
	check(state.current_step().id == "prepare_soil", "расчистка требует три действия")
	check(state.remove_item("seed_agave_sun", 3), "семена списываются атомарно")
	check(int(state.inventory.seed_agave_sun) == 3, "остаток семян корректен")
	for i in 3:
		state.plots[i].state = "planted"
		state.plots[i].watered = true
	state.end_day()
	check(state.day == 2, "смена дня обновляет календарь")
	check(state.plots[0].state == "mature", "учебная агава созревает к следующей цели")
	check(state.water == state.max_water, "лейка пополняется утром")
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures else 0)
