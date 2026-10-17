extends Node

const INTERIOR_SCENES := {
	"home": "res://scenes/home_interior.tscn",
	"workshop": "res://scenes/workshop_interior.tscn",
	"market": "res://scenes/market_interior.tscn",
	"aqueduct": "res://scenes/aqueduct_interior.tscn"
}

var current_scene: Node
var transition_layer: CanvasLayer
var transition_rect: ColorRect
var transitioning := false

func _ready() -> void:
	create_transition_overlay()
	show_title()

func create_transition_overlay() -> void:
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 100
	add_child(transition_layer)
	transition_rect = ColorRect.new()
	transition_rect.color = Color(0.012, 0.035, 0.03, 1)
	transition_rect.size = Vector2(1152, 648)
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_rect.visible = false
	transition_layer.add_child(transition_rect)

func swap_scene(packed: PackedScene) -> Node:
	if current_scene:
		current_scene.queue_free()
	current_scene = packed.instantiate()
	add_child(current_scene)
	return current_scene

func transition_to(packed: PackedScene) -> Node:
	if transitioning:
		return current_scene
	transitioning = true
	transition_rect.visible = true
	transition_rect.modulate.a = 0.0
	var fade_out := create_tween()
	fade_out.tween_property(transition_rect, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fade_out.finished
	var scene := swap_scene(packed)
	var fade_in := create_tween()
	fade_in.tween_property(transition_rect, "modulate:a", 0.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	transition_rect.visible = false
	transitioning = false
	return scene

func show_title() -> void:
	var screen := swap_scene(load("res://scenes/title.tscn"))
	screen.new_game.connect(start_new_game)
	screen.continue_game.connect(continue_game)

func start_new_game() -> void:
	GameState.start_new_game()
	await show_farm()

func continue_game() -> void:
	if GameState.load_game():
		await show_farm()

func show_farm(spawn_from := "") -> void:
	var farm := await transition_to(load("res://scenes/farm.tscn"))
	farm.return_to_title.connect(show_title_transitioned)
	farm.enter_location.connect(enter_interior)
	if not spawn_from.is_empty():
		farm.place_at_entrance(spawn_from)

func enter_interior(location_id: String) -> void:
	if not INTERIOR_SCENES.has(location_id):
		return
	var interior := await transition_to(load(INTERIOR_SCENES[location_id]))
	interior.leave_location.connect(show_farm)
	interior.return_to_title.connect(show_title_transitioned)

func show_title_transitioned() -> void:
	var screen := await transition_to(load("res://scenes/title.tscn"))
	screen.new_game.connect(start_new_game)
	screen.continue_game.connect(continue_game)
