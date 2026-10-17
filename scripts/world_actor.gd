extends Node2D

@export var actor_kind := "lucia"
@export var display_name := "ЛУСИЯ"
var pulse := 0.0
var sprite: Sprite2D

func _process(delta: float) -> void:
	pulse += delta
	if sprite:
		sprite.position.y = -29.0 + sin(pulse * 2.0) * 0.8
		sprite.rotation = sin(pulse*.8)*.006
		sprite.scale = Vector2(.082*(1.0-sin(pulse*2.0)*.004),.082*(1.0+sin(pulse*2.0)*.007))
	queue_redraw()

func _ready() -> void:
	if actor_kind == "lucia":
		sprite = Sprite2D.new()
		sprite.texture = load("res://assets/art/lucia_idle.png")
		sprite.scale = Vector2(0.082, 0.082)
		sprite.position = Vector2(0, -29)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)

func react() -> void:
	if not sprite:return
	var tween:=create_tween();tween.tween_property(sprite,"position:y",-36.0,.16).set_trans(Tween.TRANS_QUAD);tween.tween_property(sprite,"position:y",-29.0,.3).set_trans(Tween.TRANS_BOUNCE)

func _draw() -> void:
	if actor_kind == "lucia":
		fill_ellipse(Vector2(0,20),Vector2(17,6),Color(0.05,0.08,0.06,0.3))
		draw_string(ThemeDB.fallback_font,Vector2(-32,38),display_name,HORIZONTAL_ALIGNMENT_CENTER,64,11,Color("fff0c7"))

func fill_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 20:
		var a:=TAU*i/20.0;points.append(center+Vector2(cos(a)*radius.x,sin(a)*radius.y))
	draw_colored_polygon(points,color)
