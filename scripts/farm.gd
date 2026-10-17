extends Node2D

signal return_to_title
signal enter_location(location_id: String)

const PlayerScript = preload("res://scripts/player.gd")
const PlotScript = preload("res://scripts/plot.gd")
const ActorScript = preload("res://scripts/world_actor.gd")
const AmbientScript = preload("res://scripts/ambient.gd")
const EffectsScript = preload("res://scripts/effects.gd")
const DoorScript = preload("res://scripts/door.gd")
const WaterFlowScript = preload("res://scripts/water_flow.gd")
const RoadNetworkScript = preload("res://scripts/road_network.gd")
const PortalMarkerScript = preload("res://scripts/portal_marker.gd")

var player: CharacterBody2D
var lucia: Node2D
var plot_nodes: Array[Node2D] = []
var locations := {
	"lucia": Vector2(225, 346), "well": Vector2(145, 342), "home": Vector2(194, 166),
	"workshop": Vector2(525, 174), "market": Vector2(912, 215), "aqueduct": Vector2(955, 336)
}
var plot_positions := [Vector2(410,320),Vector2(505,300),Vector2(600,322),Vector2(695,302),Vector2(447,378),Vector2(545,365),Vector2(646,382),Vector2(743,358),Vector2(482,438),Vector2(580,426),Vector2(678,440),Vector2(772,416)]
var busy := false
var dialog_open := false
var journal_open := false
var clock_accum := 0.0
var hud: Dictionary = {}
var prompt: Label
var dialog_panel: PanelContainer
var journal_panel: PanelContainer
var completion_panel: PanelContainer
var effects: Node2D
var ambient: Node2D
var home_door: Node2D
var water_flow: Node2D
var portal_nodes: Dictionary = {}

func _ready() -> void:
	var background_path := "res://assets/art/farm_map.png"
	if ResourceLoader.exists(background_path):
		$Background/Map.texture = load(background_path)
	else:
		push_warning("Карта фермы не найдена: " + background_path)
	create_world()
	create_ui()
	GameState.changed.connect(refresh)
	GameState.quest_advanced.connect(on_quest_advanced)
	refresh()

func create_world() -> void:
	var roads := Node2D.new(); roads.set_script(RoadNetworkScript); $World.add_child(roads)
	water_flow = Node2D.new(); water_flow.set_script(WaterFlowScript); $World.add_child(water_flow)
	ambient = Node2D.new(); ambient.set_script(AmbientScript); $World.add_child(ambient)
	effects = Node2D.new(); effects.set_script(EffectsScript); $World.add_child(effects)
	home_door = Node2D.new(); home_door.set_script(DoorScript); home_door.position = Vector2(179, 142); $World.add_child(home_door)
	player = CharacterBody2D.new(); player.set_script(PlayerScript); player.position = Vector2(565, 555); $World.add_child(player)
	player.footstep.connect(func(at:Vector2): effects.burst("soil",at,.22))
	create_world_collisions()
	create_portals()
	lucia = Node2D.new(); lucia.set_script(ActorScript); lucia.position = locations.lucia; $World.add_child(lucia)
	for i in plot_positions.size():
		var plot := Node2D.new(); plot.set_script(PlotScript); plot.index = i; plot.position = plot_positions[i]; plot.z_index = 4; $World.add_child(plot); plot_nodes.append(plot)

func create_portals() -> void:
	var names := {"workshop":"МАСТЕРСКАЯ","market":"РЫНОК","aqueduct":"АКВЕДУК"}
	for id in names:
		var marker := Node2D.new()
		marker.set_script(PortalMarkerScript)
		marker.portal_id = id
		marker.display_name = names[id]
		marker.position = locations[id]
		$World.add_child(marker)
		portal_nodes[id] = marker

func create_world_collisions() -> void:
	var scenery := StaticBody2D.new()
	scenery.name = "SceneryCollision"
	$World.add_child(scenery)
	var well_shape := CollisionShape2D.new()
	var well_circle := CircleShape2D.new()
	well_circle.radius = 27.0
	well_shape.shape = well_circle
	well_shape.position = Vector2(145, 342)
	scenery.add_child(well_shape)
	var water_shape := CollisionPolygon2D.new()
	water_shape.polygon = PackedVector2Array([
		Vector2(1004, 246), Vector2(1152, 184), Vector2(1152, 648),
		Vector2(948, 648), Vector2(948, 604), Vector2(965, 548),
		Vector2(1015, 421), Vector2(986, 367)
	])
	scenery.add_child(water_shape)

func create_ui() -> void:
	var layer := $UI
	# Header and resource capsules.
	var top := HBoxContainer.new(); top.position=Vector2(20,18); top.size=Vector2(1112,58); top.add_theme_constant_override("separation",14); layer.add_child(top)
	var brand:=make_label("✦  СЕРДЦЕ АГАВЫ",22,Color("fff0c7"));brand.custom_minimum_size=Vector2(310,50);top.add_child(brand)
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(spacer)
	for key in ["day","time","money","water"]:
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(112,46);card.add_theme_stylebox_override("panel",box(Color(0.04,0.12,0.1,.9),Color("d89a43"),1,18));var label:=make_label("",14,Color("fff0c7"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;card.add_child(label);top.add_child(card);hud[key]=label
	# Quest card.
	var quest:=PanelContainer.new();quest.position=Vector2(20,90);quest.size=Vector2(312,119);quest.add_theme_stylebox_override("panel",box(Color("f1dfba"),Color("a95b35"),2,8));layer.add_child(quest)
	hud.quest_panel=quest
	var qbox:=VBoxContainer.new();qbox.add_theme_constant_override("separation",4);quest.add_child(qbox)
	var kicker:=make_label("ТЕКУЩАЯ ЦЕЛЬ",10,Color("a95b35"));qbox.add_child(kicker)
	hud.quest_title=make_label("КОРНИ",18,Color("243c32"));qbox.add_child(hud.quest_title)
	hud.quest_text=make_label("",13,Color("31453c"));hud.quest_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;qbox.add_child(hud.quest_text)
	hud.quest_progress=ProgressBar.new();hud.quest_progress.custom_minimum_size=Vector2(0,7);hud.quest_progress.show_percentage=false;qbox.add_child(hud.quest_progress)
	# Tool belt.
	var tools:=HBoxContainer.new();tools.position=Vector2(374,565);tools.size=Vector2(404,66);tools.add_theme_constant_override("separation",8);layer.add_child(tools)
	var tool_data=[{"id":"hoe","text":"1  МОТЫГА","icon":"⌁"},{"id":"seeds","text":"2  СЕМЕНА","icon":"◈"},{"id":"water","text":"3  ЛЕЙКА","icon":"◒"},{"id":"journal","text":"J  ЖУРНАЛ","icon":"≡"}]
	for data in tool_data:
		var b:=Button.new();b.custom_minimum_size=Vector2(95,58);b.pivot_offset=Vector2(47.5,29);b.text=str(data.icon)+"\n"+str(data.text);b.add_theme_font_size_override("font_size",12);b.add_theme_stylebox_override("normal",box(Color(0.035,0.11,0.09,.94),Color("8b7c55"),1,9));b.add_theme_stylebox_override("hover",box(Color(0.12,0.24,0.18,.97),Color("efbd60"),2,9));b.pressed.connect(tool_pressed.bind(str(data.id)));tools.add_child(b);hud["tool_"+str(data.id)]=b
	# Interaction prompt.
	prompt=make_label("",14,Color("fff5d5"));prompt.position=Vector2(426,520);prompt.size=Vector2(300,36);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;prompt.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;prompt.add_theme_stylebox_override("normal",box(Color(0.03,0.1,0.08,.92),Color("e0ad54"),1,17));layer.add_child(prompt)
	create_dialog(layer);create_journal(layer);create_completion(layer)
	var fade:=ColorRect.new();fade.color=Color(0.025,0.07,0.06,1);fade.position=Vector2.ZERO;fade.size=Vector2(1152,648);fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(fade);layer.move_child(fade,0)
	var intro_tween:=create_tween();intro_tween.tween_property(fade,"modulate:a",0.0,.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);intro_tween.finished.connect(fade.queue_free)

func create_dialog(layer: CanvasLayer) -> void:
	dialog_panel=PanelContainer.new();dialog_panel.position=Vector2(150,402);dialog_panel.size=Vector2(852,150);dialog_panel.visible=false;dialog_panel.add_theme_stylebox_override("panel",box(Color("f1dfba"),Color("b46a3b"),2,8));layer.add_child(dialog_panel)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",18);dialog_panel.add_child(row)
	var portrait:=TextureRect.new();portrait.custom_minimum_size=Vector2(106,112);portrait.expand_mode=TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists("res://assets/art/lucia_idle.png"):portrait.texture=load("res://assets/art/lucia_idle.png")
	row.add_child(portrait)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(body)
	hud.speaker=make_label("ЛУСИЯ МОРЕНО",12,Color("ad582d"));body.add_child(hud.speaker)
	hud.dialog_text=make_label("",17,Color("24382f"));hud.dialog_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hud.dialog_text.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(hud.dialog_text)
	hud.dialog_choices=HBoxContainer.new();body.add_child(hud.dialog_choices)

func create_journal(layer: CanvasLayer) -> void:
	journal_panel=PanelContainer.new();journal_panel.position=Vector2(702,20);journal_panel.size=Vector2(430,520);journal_panel.visible=false;journal_panel.add_theme_stylebox_override("panel",box(Color("f0dfb8"),Color("a95b35"),2,8));layer.add_child(journal_panel)
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",12);journal_panel.add_child(body)
	var head:=HBoxContainer.new();body.add_child(head);head.add_child(make_label("ПОЛЕВОЙ ЖУРНАЛ",12,Color("a95b35")));var fill:=Control.new();fill.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(fill);var close:=Button.new();close.text="×";close.pressed.connect(toggle_journal);head.add_child(close)
	body.add_child(make_label("Корни Сан-Педро",30,Color("20382e")))
	hud.journal_text=make_label("",16,Color("31453c"));hud.journal_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(hud.journal_text)
	var rule:=HSeparator.new();body.add_child(rule)
	body.add_child(make_label("ЗАПИСИ",11,Color("a95b35")))
	hud.facts=make_label("• Дед оставил ферму и незаконченный долг.\n• Старый колодец связан с акведуком.\n• Земля реагирует на заботу, а не на спешку.",14,Color("31453c"));hud.facts.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(hud.facts)
	var quote:=make_label("«Земля помнит не слова. Она помнит, кто принёс воду.»\n\n— запись дона Рамиро",16,Color("68452f"));quote.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;quote.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(quote)

func create_completion(layer: CanvasLayer) -> void:
	completion_panel=PanelContainer.new();completion_panel.position=Vector2(286,120);completion_panel.size=Vector2(580,408);completion_panel.visible=false;completion_panel.add_theme_stylebox_override("panel",box(Color(0.045,0.13,0.105,.98),Color("a8e6c1"),2,12));layer.add_child(completion_panel)
	var body:=VBoxContainer.new();body.alignment=BoxContainer.ALIGNMENT_CENTER;body.add_theme_constant_override("separation",14);completion_panel.add_child(body)
	var small:=make_label("КОНЕЦ ПЕРВОЙ ГЛАВЫ",12,Color("d89a43"));small.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;body.add_child(small)
	var title:=make_label("Земля ответила",38,Color("fff0c7"));title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;body.add_child(title)
	var copy:=make_label("Вода снова идёт по старому каналу. Но вместе с ней\nпроснулось то, что дед скрывал от Сан-Педро.\nВаши следующие решения изменят ферму, город и людей.",17,Color("d9dfc9"));copy.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;body.add_child(copy)
	for choice in ["Сохранить Сердце — путь Хранителя","Вернуть его городу — путь Бунтаря","Изучить его силу — путь Магната"]:
		var button:=Button.new();button.text=choice;button.custom_minimum_size=Vector2(0,44);button.pressed.connect(select_future.bind(choice));body.add_child(button)
	var exit:=Button.new();exit.text="ВЕРНУТЬСЯ В МЕНЮ";exit.pressed.connect(func():return_to_title.emit());body.add_child(exit)

func _process(delta: float) -> void:
	if dialog_open or journal_open or completion_panel.visible: return
	clock_accum += delta
	if clock_accum >= 6.0:
		clock_accum=0.0;GameState.minutes=min(GameState.minutes+1,1430);refresh_hud()
	update_proximity()
	if prompt.visible:prompt.position.y=520.0+sin(Time.get_ticks_msec()*.006)*2.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		interact_from_mouse(event.position)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("tool_1"): select_tool("hoe")
	elif event.is_action_pressed("tool_2"): select_tool("seeds")
	elif event.is_action_pressed("tool_3"): select_tool("water")
	elif event.is_action_pressed("journal"): toggle_journal()
	elif event.is_action_pressed("interact") and not busy and not dialog_open and not journal_open: interact()
	elif event.is_action_pressed("pause"):
		if dialog_open: close_dialog()
		elif journal_open: toggle_journal()
		else: return_to_title.emit()

func update_proximity() -> void:
	var near:=nearest_target();prompt.visible=not near.is_empty()
	if not near.is_empty():prompt.text="ЛКМ / E / SPACE  ·  "+interaction_label(near)
	for i in plot_nodes.size():plot_nodes[i].hovered=near.get("type","")=="plot" and int(near.get("index",-1))==i
	for id in portal_nodes:
		portal_nodes[id].active=near.get("type","")=="location" and str(near.get("id",""))==id

func nearest_target() -> Dictionary:
	var best:={};var best_dist:=74.0
	for id in locations:
		var d:=player.position.distance_to(locations[id]);if d<best_dist:best={"type":"location","id":id};best_dist=d
	for i in plot_positions.size():
		var d:=player.position.distance_to(plot_positions[i]);if d<best_dist:best={"type":"plot","index":i};best_dist=d
	return best

func interaction_label(target:Dictionary)->String:
	if target.type=="location":return {"lucia":"Поговорить с Лусией","well":"Наполнить лейку","home":"Войти в дом","workshop":"Войти в мастерскую","market":"Войти на рынок","aqueduct":"Спуститься в акведук"}.get(target.id,"Осмотреть")
	var state:=str(GameState.plots[int(target.index)].state)
	return {"debris":"Убрать камни","cleared":"Подготовить землю","tilled":"Посадить агаву","planted":"Полить агаву","mature":"Собрать агаву"}.get(state,"Осмотреть грядку")

func interact() -> void:
	var target:=nearest_target();if target.is_empty():return
	if target.type=="plot":
		player.face_toward(plot_positions[int(target.index)])
		interact_plot(int(target.index))
	else:
		player.face_toward(locations[str(target.id)])
		interact_location(str(target.id))

func interact_from_mouse(mouse_position: Vector2) -> void:
	if busy or dialog_open or journal_open:
		return
	var clicked: Dictionary = {}
	var click_distance := 64.0
	for id in locations:
		var distance := mouse_position.distance_to(locations[id])
		if distance < click_distance:
			clicked = {"type":"location","id":id}
			click_distance = distance
	for i in plot_positions.size():
		var distance := mouse_position.distance_to(plot_positions[i])
		if distance < click_distance:
			clicked = {"type":"plot","index":i}
			click_distance = distance
	if clicked.is_empty():
		clicked = nearest_target()
	if clicked.is_empty():
		return
	var target_position: Vector2 = locations[str(clicked.id)] if clicked.type=="location" else plot_positions[int(clicked.index)]
	if player.position.distance_to(target_position) > 94.0:
		toast("Подойдите ближе")
		return
	if clicked.type=="plot":
		player.face_toward(target_position)
		interact_plot(int(clicked.index))
	else:
		player.face_toward(target_position)
		interact_location(str(clicked.id))

func interact_plot(index:int)->void:
	var step:=str(GameState.current_step().id);var data:Dictionary=GameState.plots[index]
	if step=="clear_field" and data.state=="debris":await action(index,"cleared","Камни убраны",0.55)
	elif step=="prepare_soil" and data.state=="cleared" and GameState.selected_tool=="hoe":await action(index,"tilled","Почва подготовлена",0.65)
	elif step=="plant_agave" and data.state=="tilled" and GameState.selected_tool=="seeds" and GameState.remove_item("seed_agave_sun"):
		await action(index,"planted","Солнечная агава посажена",0.5)
	elif step=="water_agave" and data.state=="planted" and not data.watered and GameState.selected_tool=="water" and GameState.water>0:
		GameState.water-=1;data.watered=true;await action(index,"planted","Земля впитала воду",0.55)
	elif step=="harvest" and data.state=="mature":
		GameState.add_item("crop_agave_sun");await action(index,"cleared","Собрана солнечная агава",0.7)
	else:toast("Для этого действия нужен другой инструмент или текущая цель.")

func action(index:int,new_state:String,message:String,duration:float)->void:
	busy=true;player.can_move=false
	var step:=str(GameState.current_step().id)
	var effect_kind:String=str({"clear_field":"soil","prepare_soil":"soil","plant_agave":"seed","water_agave":"water","harvest":"harvest"}.get(step,"soil"))
	var node:=plot_nodes[index];var tween:=create_tween();tween.tween_property(node,"scale",Vector2(.92,.88),duration*.35);tween.tween_property(node,"scale",Vector2.ONE,duration*.65).set_trans(Tween.TRANS_ELASTIC)
	effects.burst(effect_kind,plot_positions[index]+Vector2(0,-8))
	await player.play_action(effect_kind)
	GameState.plots[index].state=new_state;GameState.add_progress();plot_nodes[index].queue_redraw();player.can_move=true;busy=false;toast(message)

func interact_location(id:String)->void:
	var step:=str(GameState.current_step().id)
	if id in ["home","workshop","market","aqueduct"]:
		busy=true;player.can_move=false
		if id=="home":
			await home_door.open_and_hold()
		else:
			effects.burst("magic" if id=="aqueduct" else "soil",locations[id]+Vector2(0,-10),.45)
			await get_tree().create_timer(.18).timeout
		enter_location.emit(id)
		return
	if id=="well":
		GameState.water=GameState.max_water;GameState.changed.emit();effects.burst("water",locations.well+Vector2(0,-10),.8);toast("Лейка наполнена чистой водой");return
	if id=="lucia" and step=="meet_lucia":
		show_dialog("ЛУСИЯ МОРЕНО","Ты всё-таки приехал. Твой дед говорил: когда колодец замолчит, земля выбирает нового слушателя. Начни с трёх старых грядок. Не ради урожая — ради ответа.",[{"text":"Я приведу ферму в порядок.","call":func():GameState.flags.met_lucia=true;GameState.add_progress();close_dialog()}]);return
	if id=="lucia" and step=="return_lucia":
		show_dialog("ЛУСИЯ МОРЕНО","Канал запел ещё до рассвета. Значит, Сердце знает, что ты вернулся. Теперь об этом узнает и «Пыль». Что ты сделаешь с наследием деда?",[{"text":"Я отвечу, когда узнаю всю правду.","call":complete_slice}]);return
	toast("Здесь пока нечего делать по текущей задаче.")

func place_at_entrance(id: String) -> void:
	var spawn_points := {
		"home": Vector2(194, 214),
		"workshop": Vector2(525, 220),
		"market": Vector2(902, 268),
		"aqueduct": Vector2(920, 350)
	}
	player.position = spawn_points.get(id, Vector2(565, 555))
	player.facing = Vector2.DOWN

func show_dialog(speaker:String,text:String,choices:Array)->void:
	dialog_open=true;player.can_move=false;dialog_panel.visible=true;hud.speaker.text=speaker;hud.dialog_text.text=text
	if speaker.contains("ЛУСИЯ"):lucia.react()
	dialog_panel.modulate.a=0.0;dialog_panel.position.y=418.0
	var entrance:=create_tween().set_parallel(true);entrance.tween_property(dialog_panel,"modulate:a",1.0,.22);entrance.tween_property(dialog_panel,"position:y",402.0,.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for child in hud.dialog_choices.get_children():child.queue_free()
	for data in choices:
		var button:=Button.new();button.text=str(data.text);button.modulate.a=0.0;button.pressed.connect(data.call);hud.dialog_choices.add_child(button);create_tween().tween_property(button,"modulate:a",1.0,.3).set_delay(.12)

func close_dialog()->void:
	dialog_open=false;player.can_move=true
	var exit:=create_tween().set_parallel(true);exit.tween_property(dialog_panel,"modulate:a",0.0,.16);exit.tween_property(dialog_panel,"position:y",414.0,.16);exit.finished.connect(func():dialog_panel.visible=false)

func toggle_journal()->void:
	journal_open=not journal_open;player.can_move=not journal_open
	if journal_open:
		journal_panel.visible=true;journal_panel.position.x=1152.0;journal_panel.modulate.a=0.0
		var show:=create_tween().set_parallel(true);show.tween_property(journal_panel,"position:x",702.0,.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);show.tween_property(journal_panel,"modulate:a",1.0,.2)
	else:
		var hide:=create_tween().set_parallel(true);hide.tween_property(journal_panel,"position:x",1152.0,.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN);hide.tween_property(journal_panel,"modulate:a",0.0,.18);hide.finished.connect(func():journal_panel.visible=false)

func complete_slice()->void:
	GameState.flags.slice_complete=true;GameState.add_progress();close_dialog();completion_panel.visible=true;player.can_move=false;effects.burst("magic",player.position,1.5);player.celebrate()
	completion_panel.modulate.a=0.0;completion_panel.scale=Vector2(.92,.92);completion_panel.pivot_offset=completion_panel.size*.5
	var reveal:=create_tween().set_parallel(true);reveal.tween_property(completion_panel,"modulate:a",1.0,.45);reveal.tween_property(completion_panel,"scale",Vector2.ONE,.55).set_trans(Tween.TRANS_BACK)

func select_future(choice:String)->void:
	GameState.flags.future_choice=choice;GameState.save_game();toast("Выбор записан в журнал")

func tool_pressed(id:String)->void:
	if id=="journal":toggle_journal()
	else:select_tool(id)

func select_tool(id:String)->void:
	GameState.selected_tool=id;GameState.changed.emit();var button:Button=hud["tool_"+id];var tween:=create_tween();tween.tween_property(button,"scale",Vector2(1.08,.94),.08);tween.tween_property(button,"scale",Vector2.ONE,.16).set_trans(Tween.TRANS_BACK)

func refresh()->void:
	refresh_hud();for plot in plot_nodes:plot.queue_redraw()

func refresh_hud()->void:
	if hud.is_empty():return
	hud.day.text="ДЕНЬ %d"%GameState.day;hud.time.text="%02d:%02d"%[GameState.minutes/60,GameState.minutes%60];hud.money.text="◉  %d"%GameState.money;hud.water.text="◒  %d/%d"%[GameState.water,GameState.max_water]
	var step:=GameState.current_step();hud.quest_title.text="КОРНИ";hud.quest_text.text=str(step.text);hud.quest_progress.max_value=int(step.get("target",1));hud.quest_progress.value=GameState.quest_progress;hud.journal_text.text=str(step.text)
	for id in ["hoe","seeds","water"]:hud["tool_"+id].modulate=Color("fff0b0") if GameState.selected_tool==id else Color.WHITE

func on_quest_advanced(_id:String)->void:
	refresh();var panel:PanelContainer=hud.quest_panel;panel.pivot_offset=panel.size*.5;var tween:=create_tween().set_parallel(true);hud.quest_title.modulate=Color("a8e6c1");tween.tween_property(hud.quest_title,"modulate",Color("243c32"),.7);tween.tween_property(panel,"scale",Vector2(1.035,1.035),.16);tween.chain().tween_property(panel,"scale",Vector2.ONE,.26).set_trans(Tween.TRANS_BACK)

func toast(text:String)->void:
	var label:=make_label(text,14,Color("fff5d5"));label.position=Vector2(1160,90);label.size=Vector2(326,48);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_stylebox_override("normal",box(Color(0.03,0.1,0.08,.94),Color("d89a43"),1,8));$UI.add_child(label);var tween:=create_tween();tween.tween_property(label,"position:x",802.0,.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);tween.tween_interval(1.35);tween.tween_property(label,"modulate:a",0.0,.26);tween.parallel().tween_property(label,"position:x",1160.0,.26);tween.tween_callback(label.queue_free)

func play_location_animation(kind:String,id:String)->void:
	effects.burst(kind,locations[id]+Vector2(0,-14),1.15)
	await player.play_action(kind)

func finish_day()->void:
	close_dialog();player.can_move=false
	var tint:ColorRect=$Lighting/DayTint
	var dusk:=create_tween();dusk.tween_property(tint,"color",Color(.10,.12,.28,.62),.8).set_trans(Tween.TRANS_SINE);await dusk.finished
	GameState.end_day();GameState.add_progress();effects.burst("magic",Vector2(600,330),1.6)
	var dawn:=create_tween();dawn.tween_property(tint,"color",Color(1.0,.62,.28,.22),.55);dawn.tween_property(tint,"color",Color(.145,.18,.35,0),.75).set_trans(Tween.TRANS_SINE);await dawn.finished
	home_door.close();player.can_move=true;toast("День 2 · агава созрела")

func make_label(text:String,size:int,color:Color)->Label:
	var label:=Label.new();label.text=text;label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color);return label

func box(fill:Color,border:Color,width:int,radius:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=fill;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);style.content_margin_left=14;style.content_margin_right=14;style.content_margin_top=9;style.content_margin_bottom=9;return style
