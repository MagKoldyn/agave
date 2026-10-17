extends Node

signal changed
signal quest_advanced(step_id: String)

const SAVE_PATH := "user://heart_of_agave_save.json"
const VERSION := 2

var day := 1
var minutes := 6 * 60
var money := 120
var water := 8
var max_water := 8
var selected_tool := "hoe"
var character_model := "sage"
var quest_index := 0
var quest_progress := 0
var inventory: Dictionary = {}
var flags: Dictionary = {}
var plots: Array = []
var quest_steps: Array = []

func _ready() -> void:
	load_quest_data()
	if plots.is_empty(): reset_state()

func load_quest_data() -> void:
	var raw := FileAccess.get_file_as_string("res://data/vertical_slice.json")
	var parsed = JSON.parse_string(raw)
	quest_steps = parsed.get("steps", []) if parsed is Dictionary else []

func reset_state() -> void:
	var preserved_model := character_model
	day = 1; minutes = 6 * 60; money = 120; water = 8; max_water = 8
	selected_tool = "hoe"; quest_index = 0; quest_progress = 0
	character_model = preserved_model
	inventory = {"seed_agave_sun": 6, "material_wood": 3, "material_stone": 2}
	flags = {"met_lucia": false, "journal_found": false, "channel_repaired": false, "slice_complete": false}
	plots.clear()
	for i in 12:
		plots.append({"id": i, "state": "debris" if i < 3 else "wild", "watered": false, "growth": 0})

func start_new_game() -> void:
	reset_state(); save_game(); changed.emit()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func current_step() -> Dictionary:
	if quest_index >= 0 and quest_index < quest_steps.size(): return quest_steps[quest_index]
	return {"id":"complete", "text":"Вертикальный срез завершён.", "target":1, "title":"Корни"}

func add_progress(amount := 1) -> void:
	var step := current_step()
	quest_progress += amount
	if quest_progress >= int(step.get("target", 1)):
		quest_index += 1; quest_progress = 0
		quest_advanced.emit(str(current_step().get("id", "complete")))
	advance_time(15)
	save_game(); changed.emit()

func advance_time(amount: int) -> void:
	minutes = mini(minutes + amount, 23 * 60 + 50)

func add_item(id: String, amount := 1) -> void:
	inventory[id] = int(inventory.get(id, 0)) + amount

func remove_item(id: String, amount := 1) -> bool:
	if int(inventory.get(id, 0)) < amount: return false
	inventory[id] = int(inventory[id]) - amount
	return true

func end_day() -> void:
	day += 1; minutes = 6 * 60; water = max_water
	for plot in plots:
		if plot.state == "planted" and plot.watered:
			plot.growth = int(plot.growth) + 1
			plot.state = "mature" if plot.growth >= 1 else "sprout"
		plot.watered = false
	save_game(); changed.emit()

func save_game() -> void:
	var data := {"version":VERSION,"day":day,"minutes":minutes,"money":money,"water":water,"max_water":max_water,"selected_tool":selected_tool,"character_model":character_model,"quest_index":quest_index,"quest_progress":quest_progress,"inventory":inventory,"flags":flags,"plots":plots}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data))

func load_game() -> bool:
	if not has_save(): return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary or int(parsed.get("version", 0)) != VERSION: return false
	day=int(parsed.day);minutes=int(parsed.minutes);money=int(parsed.money);water=int(parsed.water);max_water=int(parsed.max_water);selected_tool=str(parsed.selected_tool);character_model=str(parsed.get("character_model","sage"));quest_index=int(parsed.quest_index);quest_progress=int(parsed.quest_progress);inventory=parsed.inventory;flags=parsed.flags;plots=parsed.plots
	changed.emit(); return true
