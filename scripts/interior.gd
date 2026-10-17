extends Node2D

signal leave_location(location_id: String)
signal return_to_title

const PlayerScript = preload("res://scripts/player.gd")
const EffectsScript = preload("res://scripts/effects.gd")
const AmbientScript = preload("res://scripts/interior_ambient.gd")

@export_enum("home", "workshop", "market", "aqueduct") var location_id := "home"

var player: CharacterBody2D
var effects: Node2D
var ambient: Node2D
var prompt: Label
var dialog_panel: PanelContainer
var dialog_text: Label
var busy := false
var dialog_open := false
var targets: Array = []
var config: Dictionary = {}
var hud: Dictionary = {}

func _ready() -> void:
	config = location_config(location_id)
	var background_path := str(config.background)
	if ResourceLoader.exists(background_path):
		$Background/Map.texture = load(background_path)
	else:
		push_warning("Фон локации не найден: " + background_path)
	targets = config.targets
	create_world()
	create_ui()
	GameState.changed.connect(refresh_hud)
	refresh_hud()

func create_world() -> void:
	ambient = Node2D.new()
	ambient.set_script(AmbientScript)
	ambient.location_id = location_id
	$World.add_child(ambient)
	effects = Node2D.new()
	effects.set_script(EffectsScript)
	$World.add_child(effects)
	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	player.position = Vector2(576, 520)
	player.movement_bounds = Rect2(44, 112, 1064, 458)
	$World.add_child(player)
	player.footstep.connect(func(at: Vector2): effects.burst("soil", at, 0.14))
	create_collisions()

func create_collisions() -> void:
	var scenery := StaticBody2D.new()
	scenery.name = "InteriorCollision"
	$World.add_child(scenery)
	for rect: Rect2 in config.obstacles:
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.position = rect.position + rect.size * 0.5
		scenery.add_child(collision)

func create_ui() -> void:
	var layer := $UI
	var header := PanelContainer.new()
	header.position = Vector2(20, 18)
	header.size = Vector2(1112, 55)
	header.add_theme_stylebox_override("panel", box(Color(0.03, 0.10, 0.085, 0.91), Color("b8783f"), 1, 12))
	layer.add_child(header)
	var row := HBoxContainer.new()
	header.add_child(row)
	var location_label := make_label("ФЕРМА  ›  " + str(config.title), 20, Color("fff0c7"))
	location_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(location_label)
	hud.time = make_label("", 14, Color("e8d8b1"))
	row.add_child(hud.time)
	var exit_hint := make_label("ESC — на ферму", 12, Color("c8b992"))
	exit_hint.custom_minimum_size = Vector2(150, 0)
	exit_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(exit_hint)
	prompt = make_label("", 14, Color("fff5d5"))
	prompt.position = Vector2(366, 584)
	prompt.size = Vector2(420, 42)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.add_theme_stylebox_override("normal", box(Color(0.025, 0.09, 0.075, 0.94), Color("e0ad54"), 1, 18))
	layer.add_child(prompt)
	create_dialog(layer)
	var fade := ColorRect.new()
	fade.color = Color(0.015, 0.035, 0.03, 1)
	fade.position = Vector2.ZERO
	fade.size = Vector2(1152, 648)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	layer.move_child(fade, 0)
	var reveal := create_tween()
	reveal.tween_property(fade, "modulate:a", 0.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.finished.connect(fade.queue_free)

func create_dialog(layer: CanvasLayer) -> void:
	dialog_panel = PanelContainer.new()
	dialog_panel.position = Vector2(176, 420)
	dialog_panel.size = Vector2(800, 136)
	dialog_panel.visible = false
	dialog_panel.add_theme_stylebox_override("panel", box(Color("f1dfba"), Color("a95b35"), 2, 10))
	layer.add_child(dialog_panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	dialog_panel.add_child(body)
	var title := make_label(str(config.title).to_upper(), 12, Color("a95b35"))
	body.add_child(title)
	dialog_text = make_label("", 17, Color("263b32"))
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(dialog_text)
	var close := Button.new()
	close.text = "ПРОДОЛЖИТЬ"
	close.custom_minimum_size = Vector2(0, 35)
	close.pressed.connect(close_dialog)
	body.add_child(close)

func _process(_delta: float) -> void:
	if dialog_open:
		return
	update_proximity()
	if prompt.visible:
		prompt.position.y = 584.0 + sin(Time.get_ticks_msec() * 0.006) * 2.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		interact_from_mouse(event.position)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not busy and not dialog_open:
		interact_nearest()
	elif event.is_action_pressed("pause"):
		if dialog_open:
			close_dialog()
		else:
			request_exit()

func interact_from_mouse(mouse_position: Vector2) -> void:
	if busy or dialog_open:
		return
	var clicked := target_near_point(mouse_position, 64.0)
	if clicked.is_empty():
		clicked = nearest_target()
	if clicked.is_empty():
		return
	var target_position: Vector2 = clicked.position
	if player.position.distance_to(target_position) > 94.0:
		toast("Подойдите ближе к объекту")
		return
	interact_target(clicked)

func update_proximity() -> void:
	var near := nearest_target()
	prompt.visible = not near.is_empty()
	if not near.is_empty():
		prompt.text = "ЛКМ / E / SPACE  ·  " + str(near.label)

func nearest_target() -> Dictionary:
	var best: Dictionary = {}
	var best_distance := 78.0
	for target: Dictionary in targets:
		var distance := player.position.distance_to(target.position)
		if distance < best_distance:
			best = target
			best_distance = distance
	return best

func target_near_point(point: Vector2, radius: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius
	for target: Dictionary in targets:
		var distance := point.distance_to(target.position)
		if distance < best_distance:
			best = target
			best_distance = distance
	return best

func interact_nearest() -> void:
	var target := nearest_target()
	if not target.is_empty():
		interact_target(target)

func interact_target(target: Dictionary) -> void:
	player.face_toward(target.position)
	var id := str(target.id)
	if id == "exit":
		request_exit()
		return
	match location_id:
		"home":
			interact_home(id)
		"workshop":
			interact_workshop(id)
		"market":
			interact_market(id)
		"aqueduct":
			interact_aqueduct(id)

func interact_home(id: String) -> void:
	var step := str(GameState.current_step().id)
	if id == "journal" and step == "find_journal":
		GameState.flags.journal_found = true
		GameState.add_item("quest_grandfather_journal")
		GameState.add_progress()
		effects.burst("magic", Vector2(185, 160), 0.8)
		show_dialog("Между страницами лежит схема старого канала. На полях выведено: «Вода помнит путь, даже когда камень забыл его».")
	elif id == "bed" and step == "end_day":
		finish_day()
	elif id == "chest":
		show_dialog("В сундуке: %d семян агавы, %d доски и %d камня." % [int(GameState.inventory.get("seed_agave_sun", 0)), int(GameState.inventory.get("material_wood", 0)), int(GameState.inventory.get("material_stone", 0))])
	elif id == "fireplace":
		show_dialog("На камине вырезан тот же знак агавы, что и на схеме акведука.")
	else:
		show_dialog("Дом хранит запах сухих трав и старой бумаги. Здесь можно отдохнуть и перечитать записи деда.")

func interact_workshop(id: String) -> void:
	var step := str(GameState.current_step().id)
	if id == "bench" and step == "repair_channel":
		if int(GameState.inventory.get("material_wood", 0)) >= 2 and int(GameState.inventory.get("material_stone", 0)) >= 1:
			GameState.remove_item("material_wood", 2)
			GameState.remove_item("material_stone", 1)
			GameState.flags.channel_repaired = true
			GameState.add_progress()
			run_station_action("repair", Vector2(566, 190), "Заслонка и крепления готовы. Осталось вернуть их в старый канал.")
		else:
			toast("Нужно: 2 доски и 1 камень")
	elif id == "still" and step == "craft_syrup":
		if int(GameState.inventory.get("crop_agave_sun", 0)) >= 2:
			GameState.remove_item("crop_agave_sun", 2)
			GameState.add_item("product_agave_syrup")
			GameState.add_progress()
			run_station_action("craft", Vector2(910, 205), "Сироп агавы готов · обычное качество")
		else:
			toast("Для рецепта нужны 2 солнечные агавы")
	elif id == "press":
		show_dialog("Каменный пресс отделяет сок агавы от волокон. Его жернова ещё помнят руки дона Рамиро.")
	else:
		show_dialog("Верстак собран для ремонта каналов, а медный перегонный куб — для сиропов и настоек.")

func interact_market(id: String) -> void:
	var step := str(GameState.current_step().id)
	if id == "counter" and step == "sell_syrup":
		if GameState.remove_item("product_agave_syrup"):
			GameState.money += 58
			GameState.add_progress()
			run_station_action("sell", Vector2(575, 185), "Продано: 58 песо · цена подтверждена")
		else:
			toast("Сначала приготовьте сироп")
	elif id == "herbs":
		show_dialog("Сушёные травы пахнут мятой, чили и полынью. Некоторые пригодятся для будущих зелий.")
	else:
		show_dialog("Сегодня торговцы дают 58 песо за бутылку чистого сиропа агавы.")

func interact_aqueduct(id: String) -> void:
	if id == "valve":
		if bool(GameState.flags.get("channel_repaired", false)):
			effects.burst("water", Vector2(905, 180), 1.0)
			show_dialog("Новая заслонка держится крепко. Поток снова распределяется между фермой и Сан‑Педро.")
		else:
			show_dialog("Механизм заклинило. Сначала нужно изготовить крепления в мастерской.")
	elif id == "heart":
		effects.burst("magic", Vector2(577, 132), 1.0)
		show_dialog("Минерал пульсирует в такт воде. На мгновение кажется, будто под камнем бьётся огромное сердце.")
	else:
		show_dialog("В глубине акведука вода звучит как далёкий голос.")

func run_station_action(kind: String, at: Vector2, message: String) -> void:
	busy = true
	player.can_move = false
	effects.burst(kind, at, 1.2)
	await player.play_action(kind)
	player.can_move = true
	busy = false
	toast(message)

func finish_day() -> void:
	busy = true
	player.can_move = false
	var tint := ColorRect.new()
	tint.color = Color(0.08, 0.09, 0.24, 0.0)
	tint.position = Vector2.ZERO
	tint.size = Vector2(1152, 648)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(tint)
	var dusk := create_tween()
	dusk.tween_property(tint, "color:a", 0.82, 0.72).set_trans(Tween.TRANS_SINE)
	await dusk.finished
	GameState.end_day()
	GameState.add_progress()
	var dawn := create_tween()
	dawn.tween_property(tint, "color", Color(1.0, 0.65, 0.3, 0.25), 0.5)
	dawn.tween_property(tint, "color:a", 0.0, 0.7)
	await dawn.finished
	tint.queue_free()
	player.can_move = true
	busy = false
	toast("День 2 · агава созрела")

func request_exit() -> void:
	if busy:
		return
	busy = true
	player.can_move = false
	leave_location.emit(location_id)

func show_dialog(text: String) -> void:
	dialog_open = true
	player.can_move = false
	dialog_text.text = text
	dialog_panel.visible = true
	dialog_panel.modulate.a = 0.0
	dialog_panel.position.y = 436.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(dialog_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(dialog_panel, "position:y", 420.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_dialog() -> void:
	dialog_open = false
	player.can_move = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(dialog_panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(dialog_panel, "position:y", 432.0, 0.15)
	tween.finished.connect(func(): dialog_panel.visible = false)

func toast(text: String) -> void:
	var label := make_label(text, 14, Color("fff5d5"))
	label.position = Vector2(1160, 92)
	label.size = Vector2(360, 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_stylebox_override("normal", box(Color(0.03, 0.1, 0.08, 0.95), Color("d89a43"), 1, 9))
	$UI.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:x", 772.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.35)
	tween.tween_property(label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(label.queue_free)

func refresh_hud() -> void:
	if hud.is_empty():
		return
	hud.time.text = "ДЕНЬ %d  ·  %02d:%02d  ·  ◉ %d" % [GameState.day, GameState.minutes / 60, GameState.minutes % 60, GameState.money]

func location_config(id: String) -> Dictionary:
	var configs := {
		"home": {
			"title": "ДОМ РАМИРО",
			"background": "res://assets/art/interior_home.png",
			"targets": [
				{"id":"journal","position":Vector2(180,158),"label":"Изучить письменный стол"},
				{"id":"fireplace","position":Vector2(575,166),"label":"Осмотреть камин"},
				{"id":"bed","position":Vector2(875,292),"label":"Отдохнуть до утра"},
				{"id":"chest","position":Vector2(868,455),"label":"Открыть сундук"},
				{"id":"exit","position":Vector2(576,555),"label":"Выйти на ферму"}
			],
			"obstacles": [Rect2(70,80,245,125),Rect2(325,70,105,145),Rect2(492,70,165,105),Rect2(760,70,305,210),Rect2(42,325,170,190),Rect2(890,405,190,100)]
		},
		"workshop": {
			"title": "МАСТЕРСКАЯ",
			"background": "res://assets/art/interior_workshop.png",
			"targets": [
				{"id":"press","position":Vector2(215,185),"label":"Осмотреть пресс"},
				{"id":"bench","position":Vector2(565,185),"label":"Работать за верстаком"},
				{"id":"still","position":Vector2(905,195),"label":"Запустить перегонный куб"},
				{"id":"exit","position":Vector2(576,555),"label":"Выйти на ферму"}
			],
			"obstacles": [Rect2(45,85,300,160),Rect2(410,65,325,135),Rect2(785,55,320,205),Rect2(0,330,190,160),Rect2(810,360,300,135)]
		},
		"market": {
			"title": "РЫНОК САН‑ПЕДРО",
			"background": "res://assets/art/interior_market.png",
			"targets": [
				{"id":"counter","position":Vector2(575,185),"label":"Торговать"},
				{"id":"herbs","position":Vector2(770,285),"label":"Осмотреть травы"},
				{"id":"produce","position":Vector2(312,290),"label":"Узнать цены"},
				{"id":"exit","position":Vector2(576,555),"label":"Выйти на ферму"}
			],
			"obstacles": [Rect2(330,60,500,165),Rect2(0,130,290,300),Rect2(790,180,315,270),Rect2(190,330,250,125),Rect2(715,330,255,125)]
		},
		"aqueduct": {
			"title": "СЕРДЦЕ АКВЕДУКА",
			"background": "res://assets/art/interior_aqueduct.png",
			"targets": [
				{"id":"heart","position":Vector2(577,130),"label":"Коснуться Сердца"},
				{"id":"valve","position":Vector2(905,165),"label":"Проверить заслонку"},
				{"id":"water","position":Vector2(320,300),"label":"Прислушаться к воде"},
				{"id":"exit","position":Vector2(576,566),"label":"Подняться на ферму"}
			],
			"obstacles": [Rect2(0,105,290,420),Rect2(870,230,282,330),Rect2(350,65,145,110),Rect2(655,65,135,105)]
		}
	}
	return configs.get(id, configs.home)

func make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

