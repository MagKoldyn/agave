extends Node2D

var index := 0
var hovered := false
var shimmer := 0.0

func _process(delta: float) -> void:
	shimmer += delta; queue_redraw()

func _draw() -> void:
	var data: Dictionary = GameState.plots[index]
	var soil := Color("6f432d") if data.watered else Color("8b5334")
	var patch := PackedVector2Array([Vector2(-39,-9),Vector2(-25,-22),Vector2(7,-26),Vector2(39,-12),Vector2(44,7),Vector2(25,22),Vector2(-11,25),Vector2(-42,11)])
	draw_colored_polygon(patch,soil)
	draw_polyline(PackedVector2Array([patch[0],patch[1],patch[2],patch[3],patch[4],patch[5],patch[6],patch[7],patch[0]]),Color("b77a4d"),2)
	if data.state in ["cleared","tilled","planted","sprout","mature"]:
		for y in [-12.0,0.0,12.0]: stroke_ellipse(Vector2(0,y),Vector2(30,6),Color("4f3528"))
	if data.state == "debris":
		stone(Vector2(-16,-5),11);stone(Vector2(13,7),9);stone(Vector2(24,-9),6)
	if data.state in ["planted","sprout","mature"]:
		var size := 8.0 if data.state=="planted" else 15.0 if data.state=="sprout" else 24.0
		agave(Vector2.ZERO,size,data.state=="mature")
	if hovered:
		draw_polyline(PackedVector2Array([patch[0],patch[1],patch[2],patch[3],patch[4],patch[5],patch[6],patch[7],patch[0]]),Color("f6c45f"),3)

func stone(at:Vector2,size:float)->void:
	var pts:=PackedVector2Array([at+Vector2(-size,-2),at+Vector2(-size*.5,-size*.7),at+Vector2(size*.4,-size*.6),at+Vector2(size,1),at+Vector2(size*.3,size*.6),at+Vector2(-size*.6,size*.5)])
	draw_colored_polygon(pts,Color("89735d"));draw_polyline(pts,Color("bda888"),1.5)

func agave(at:Vector2,size:float,glow:bool)->void:
	for i in 10:
		var a:=TAU*i/10.0;var side:=Vector2(cos(a),sin(a));var tip:=at+side*size
		var perp:=Vector2(-side.y,side.x)*size*.24
		var leaf:=PackedVector2Array([at-perp*.45,at+perp*.7,tip])
		draw_colored_polygon(leaf,Color("78a17e") if i%2 else Color("527d73"))
	if glow:
		var alpha:=0.55+sin(shimmer*4.0)*0.2;stroke_ellipse(at,Vector2(size+4,size*.52),Color(0.66,0.9,0.76,alpha))

func stroke_ellipse(center:Vector2,radius:Vector2,color:Color)->void:
	var pts:=PackedVector2Array()
	for i in 18:
		var a:=TAU*i/17.0;pts.append(center+Vector2(cos(a)*radius.x,sin(a)*radius.y))
	draw_polyline(pts,color,1.4)
