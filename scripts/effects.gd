extends Node2D

var particles: Array[Dictionary] = []
var rings: Array[Dictionary] = []

func _ready() -> void:
	z_index = 20

func burst(kind: String, at: Vector2, strength := 1.0) -> void:
	var count:int=int({"soil":14,"water":18,"seed":12,"harvest":24,"repair":20,"craft":22,"sell":18,"magic":30}.get(kind,12))
	var palette: Array[Color] = [Color.WHITE]
	match kind:
		"soil":palette=[Color("8f5637"),Color("d08a49"),Color("e8b968")]
		"water":palette=[Color("77d8d1"),Color("d3fff0"),Color("4a9b9a")]
		"seed":palette=[Color("d89a43"),Color("f3d277"),Color("7d9b68")]
		"harvest":palette=[Color("7d9b68"),Color("a8e6c1"),Color("d89a43")]
		"repair":palette=[Color("f2bc54"),Color("e36d3e"),Color("8ed7ce")]
		"craft":palette=[Color("f4d48a"),Color("d87b3b"),Color("fff2ca")]
		"sell":palette=[Color("ffd56b"),Color("fff0a8"),Color("d89a43")]
		"magic":palette=[Color("a8e6c1"),Color("d7fff0"),Color("4a9b9a")]
	for i in count:
		var angle := randf_range(-PI*.95,-PI*.05)
		var speed := randf_range(35.0,105.0)*strength
		particles.append({"kind":kind,"p":at+Vector2(randf_range(-8,8),randf_range(-3,4)),"v":Vector2(cos(angle),sin(angle))*speed,"age":0.0,"life":randf_range(.45,.9),"size":randf_range(2.0,4.5),"color":palette.pick_random(),"spin":randf_range(-5.0,5.0),"rot":randf_range(0.0,TAU)})
	rings.append({"p":at,"age":0.0,"life":.55,"color":palette[0],"radius":8.0})

func _process(delta: float) -> void:
	for i in range(particles.size()-1,-1,-1):
		var p:Dictionary=particles[i];p.age=float(p.age)+delta;p.p=Vector2(p.p)+Vector2(p.v)*delta;p.v=Vector2(p.v)+Vector2(0,120)*delta;p.rot=float(p.rot)+float(p.spin)*delta
		if float(p.age)>=float(p.life):particles.remove_at(i)
	for i in range(rings.size()-1,-1,-1):
		var r:Dictionary=rings[i];r.age=float(r.age)+delta;r.radius=float(r.radius)+delta*52.0
		if float(r.age)>=float(r.life):rings.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for p in particles:
		var fade:float=1.0-float(p.age)/float(p.life);var color:Color=p.color;color.a*=fade
		var at:Vector2=p.p;var size:float=p.size
		match str(p.kind):
			"water":
				draw_colored_polygon(PackedVector2Array([at+Vector2(0,-size*1.7),at+Vector2(size,size*.5),at+Vector2(0,size),at+Vector2(-size,size*.5)]),color)
			"harvest","seed":
				var axis:Vector2=Vector2(cos(float(p.rot)),sin(float(p.rot)))*size;var side:Vector2=Vector2(-axis.y,axis.x)*.45;draw_colored_polygon(PackedVector2Array([at-axis,at+side,at+axis,at-side]),color)
			"repair","sell","magic":
				draw_line(at-Vector2(size,0).rotated(float(p.rot)),at+Vector2(size,0).rotated(float(p.rot)),color,2.0)
			_:
				draw_circle(at,size,color)
	for r in rings:
		var fade:float=1.0-float(r.age)/float(r.life);var color:Color=r.color;color.a*=fade
		draw_arc(Vector2(r.p),float(r.radius),0,TAU,28,color,2.0)
