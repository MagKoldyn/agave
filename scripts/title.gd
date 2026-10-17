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
	$Content/ModelChoices/Sage.pressed.connect(select_model.bind("sage"))
	$Content/ModelChoices/Ochre.pressed.connect(select_model.bind("ochre"))
	$Content/ModelChoices/Desert.pressed.connect(select_model.bind("desert"))
	setup_model_icons()
	refresh_model_buttons()
	$Content/Continue.visible = GameState.has_save()
	$Content/NewGame.grab_focus()
	$Backdrop.pivot_offset = get_viewport_rect().size*.5
	$Backdrop.scale = Vector2(1.035,1.035)
	var drift:=create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift.tween_property($Backdrop,"scale",Vector2(1.075,1.075),9.0)
	drift.tween_property($Backdrop,"scale",Vector2(1.035,1.035),9.0)
	var tween := create_tween().set_parallel(true)
	$Content.modulate.a = 0.0
	$Content.position.x += 28.0
	tween.tween_property($Content, "modulate:a", 1.0, 0.65)
	tween.tween_property($Content, "position:x", $Content.position.x - 28.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func setup_model_icons() -> void:
	var paths := {
		$Content/ModelChoices/Sage: "res://assets/art/player_walk_sage.png",
		$Content/ModelChoices/Ochre: "res://assets/art/player_walk_ochre.png",
		$Content/ModelChoices/Desert: "res://assets/art/player_walk_desert.png"
	}
	for button: Button in paths:
		var icon := AtlasTexture.new()
		icon.atlas = load(paths[button])
		icon.region = Rect2(0, 0, 314, 314)
		button.icon = icon
		button.expand_icon = true

func select_model(model_id: String) -> void:
	GameState.character_model = model_id
	refresh_model_buttons()
	var button: Button = {
		"sage": $Content/ModelChoices/Sage,
		"ochre": $Content/ModelChoices/Ochre,
		"desert": $Content/ModelChoices/Desert
	}[model_id]
	button.pivot_offset = button.size * 0.5
	var pulse := create_tween()
	pulse.tween_property(button, "scale", Vector2(1.06, 0.94), 0.08)
	pulse.tween_property(button, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)

func refresh_model_buttons() -> void:
	var buttons := {
		"sage": $Content/ModelChoices/Sage,
		"ochre": $Content/ModelChoices/Ochre,
		"desert": $Content/ModelChoices/Desert
	}
	for id in buttons:
		var button: Button = buttons[id]
		button.disabled = id == GameState.character_model
		button.modulate = Color("fff0ad") if id == GameState.character_model else Color.WHITE
