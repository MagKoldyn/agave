extends Node2D

var elapsed := 0.0
var motes: Array[Vector2] = []
var fireflies: Array[Vector2] = []

func _ready() -> void:
	z_index = 3
	var rng:=RandomNumberGenerator.new();rng.seed=81427
	for i in 34:motes.append(Vector2(rng.randf_range(25,1125),rng.randf_range(170,610)))
	for i in 10:fireflies.append(Vector2(rng.randf_range(340,830),rng.randf_range(230,505)))

func _process(delta: float) -> void:
	elapsed+=delta
	queue_redraw()

func _draw() -> void:
	# Fine desert dust creates depth without hiding the hand-pixelled map.
	for i in motes.size():
		var base:Vector2=motes[i];var p:Vector2=base+Vector2(fmod(elapsed*(4.0+i%4)+i*13.0,90.0)-45.0,sin(elapsed*.45+i)*4.0)
		var alpha:float=.10+.08*sin(elapsed+i*.7);draw_circle(p,1.2+float(i%3)*.45,Color(1.0,.84,.56,alpha))
	# Copper workshop chimney smoke.
	for i in 7:
		var phase:float=fmod(elapsed*.22+i/7.0,1.0);var p:Vector2=Vector2(616,126)+Vector2(sin(phase*8.0+i)*8.0,-phase*78.0)
		draw_circle(p,5.0+phase*12.0,Color(.72,.74,.64,(1.0-phase)*.14))
	# Animated glints follow the aqueduct and waterfall on the right.
	for i in 11:
		var phase:float=fmod(elapsed*.35+i/11.0,1.0);var y:float=185.0+phase*355.0;var x:float=1063.0+sin(phase*16.0+i)*18.0
		draw_line(Vector2(x-5,y),Vector2(x+5,y-2),Color(.68,1.0,.94,.28*(1.0-phase)),1.5)
	# Small butterflies around marigolds.
	for i in 5:
		var center:Vector2=Vector2(340+i*110,465-i%2*35);var p:Vector2=center+Vector2(sin(elapsed*1.7+i)*18.0,cos(elapsed*2.1+i*.4)*9.0)
		var wing:float=2.0+abs(sin(elapsed*9.0+i))*2.5;draw_circle(p+Vector2(-wing,0),2.0,Color("f2b84f"));draw_circle(p+Vector2(wing,0),2.0,Color("ef7a46"))
	# Magical motes appear only after the first harvest.
	if int(GameState.inventory.get("crop_agave_sun",0))>0 or bool(GameState.flags.get("slice_complete",false)):
		for i in fireflies.size():
			var p:Vector2=fireflies[i]+Vector2(sin(elapsed*.9+i)*10.0,cos(elapsed*.7+i)*7.0);var a:float=.2+.55*abs(sin(elapsed*1.8+i));draw_circle(p,2.0,Color(0.66,.9,.76,a))
