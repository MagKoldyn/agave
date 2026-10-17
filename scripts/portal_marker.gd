extends Node2D

var portal_id := ""
var display_name := ""
var active := false:
	set(value):
		active = value
		queue_redraw()
var elapsed := 0.0

func _ready() -> void:
	z_index = 6
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if active:
		queue_redraw()

func _draw() -> void:
	var alpha := 0.22 + (0.12 * sin(elapsed * 4.0) if active else 0.0)
	draw_arc(Vector2(0, 9), 18.0, 0.0, PI, 20, Color(1.0,0.72,0.3,alpha), 2.0)
	draw_line(Vector2(-18,9),Vector2(18,9),Color(1.0,0.72,0.3,alpha),2.0)
	if active:
		var arrow_y := -18.0 + sin(elapsed * 5.0) * 2.0
		var arrow := PackedVector2Array([Vector2(-5,arrow_y-4),Vector2(5,arrow_y-4),Vector2(0,arrow_y+3)])
		draw_colored_polygon(arrow,Color("ffd06a"))
		draw_string(ThemeDB.fallback_font,Vector2(-70,-29),display_name,HORIZONTAL_ALIGNMENT_CENTER,140,12,Color("fff0c7"))

