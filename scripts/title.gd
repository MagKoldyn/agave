extends Control

signal new_game
signal continue_game

func _ready() -> void:
	var background_path := "res://assets/art/farm_map.png"
	if ResourceLoader.exists(background_path):
		$Backdrop.texture = load(background_path)
	else:
		push_warning("Фон меню не найден: " + background_path)
	$Content/NewGame.pressed.connect(func(): new_game.emit())
	$Content/Continue.pressed.connect(func(): continue_game.emit())
	$Content/Continue.visible = GameState.has_save()
	$Content/NewGame.grab_focus()
	var tween := create_tween().set_parallel(true)
	$Content.modulate.a = 0.0
	$Content.position.x += 28.0
	tween.tween_property($Content, "modulate:a", 1.0, 0.65)
	tween.tween_property($Content, "position:x", $Content.position.x - 28.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
