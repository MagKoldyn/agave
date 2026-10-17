extends CharacterBody2D

var can_move := true
var facing := Vector2.DOWN
var step_time := 0.0

func _ready() -> void:
	z_index = 8
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO; return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * 185.0
	if direction.length() > 0.1:
		facing = direction; step_time += delta * 10.0
	else: step_time = lerpf(step_time, 0.0, delta * 4.0)
	move_and_slide()
	position.x = clampf(position.x, 40.0, 1112.0)
	position.y = clampf(position.y, 195.0, 608.0)
	queue_redraw()

func _draw() -> void:
	var bob := sin(step_time) * 2.0 if velocity.length() > 0 else sin(Time.get_ticks_msec() * 0.002) * 0.7
	# Soft painted shadow.
	draw_ellipse(Vector2(0, 18), Vector2(18, 7), Color(0.08,0.11,0.08,0.35))
	# Satchel, boots, body and scarf use irregular silhouettes rather than blocks.
	draw_colored_polygon(PackedVector2Array([Vector2(-10,7+bob),Vector2(-8,26),Vector2(-1,27),Vector2(1,8+bob)]),Color("5a3428"))
	draw_colored_polygon(PackedVector2Array([Vector2(1,8+bob),Vector2(3,27),Vector2(10,26),Vector2(10,6+bob)]),Color("6b3a28"))
	draw_colored_polygon(PackedVector2Array([Vector2(-15,-13+bob),Vector2(-19,3+bob),Vector2(-12,15+bob),Vector2(0,19+bob),Vector2(14,14+bob),Vector2(18,1+bob),Vector2(12,-14+bob),Vector2(0,-19+bob)]),Color("31584c"))
	draw_colored_polygon(PackedVector2Array([Vector2(-17,-11+bob),Vector2(-5,-17+bob),Vector2(15,-11+bob),Vector2(11,-5+bob),Vector2(-9,-7+bob)]),Color("d89a43"))
	draw_circle(Vector2(0,-28+bob),11,Color("d9aa76"))
	draw_arc(Vector2(0,-30+bob),12,PI,TAU,14,Color("202d28"),6)
	draw_colored_polygon(PackedVector2Array([Vector2(10,-10+bob),Vector2(21,-4+bob),Vector2(18,15+bob),Vector2(8,10+bob)]),Color("9b5a37"))

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle)*radius.x, sin(angle)*radius.y))
	draw_colored_polygon(points, color)
