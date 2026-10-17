extends Node2D

@export var actor_kind := "lucia"
@export var display_name := "ЛУСИЯ"
var pulse := 0.0

func _process(delta: float) -> void:
	pulse += delta; queue_redraw()

func _draw() -> void:
	var bob := sin(pulse * 2.0) * 1.2
	if actor_kind == "lucia":
		draw_circle(Vector2(0,20),Vector2(17,6),Color(0.05,0.08,0.06,0.3))
		draw_colored_polygon(PackedVector2Array([Vector2(-16,-10+bob),Vector2(-20,14),Vector2(-8,29),Vector2(8,29),Vector2(19,12),Vector2(13,-11+bob),Vector2(0,-17+bob)]),Color("3e6256"))
		draw_colored_polygon(PackedVector2Array([Vector2(-13,-8+bob),Vector2(0,-15+bob),Vector2(14,-7+bob),Vector2(9,2),Vector2(-9,1)]),Color("c56a3e"))
		draw_circle(Vector2(0,-27+bob),10,Color("c99068"))
		draw_arc(Vector2(0,-29+bob),11,PI,TAU,12,Color("2a2824"),6)
		draw_colored_polygon(PackedVector2Array([Vector2(12,0),Vector2(24,5),Vector2(18,23),Vector2(8,14)]),Color("d7c89b"))
		draw_string(ThemeDB.fallback_font,Vector2(-28,47),display_name,HORIZONTAL_ALIGNMENT_CENTER,56,11,Color("fff0c7"))

func draw_circle(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 20:
		var a:=TAU*i/20.0;points.append(center+Vector2(cos(a)*radius.x,sin(a)*radius.y))
	draw_colored_polygon(points,color)
