extends Node

var current_scene: Node

func _ready() -> void:
	show_title()

func swap_scene(packed: PackedScene) -> Node:
	if current_scene:
		current_scene.queue_free()
	current_scene = packed.instantiate()
	add_child(current_scene)
	return current_scene

func show_title() -> void:
	var screen := swap_scene(load("res://scenes/title.tscn"))
	screen.new_game.connect(start_new_game)
	screen.continue_game.connect(continue_game)

func start_new_game() -> void:
	GameState.start_new_game()
	show_farm()

func continue_game() -> void:
	if GameState.load_game():
		show_farm()

func show_farm() -> void:
	var farm := swap_scene(load("res://scenes/farm.tscn"))
	farm.return_to_title.connect(show_title)
