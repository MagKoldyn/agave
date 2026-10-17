extends CharacterBody2D

var can_move := true
var facing := Vector2.DOWN
var step_time := 0.0
var sprite: Sprite2D

func _ready() -> void:
	z_index = 8
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/art/player_idle.png")
	sprite.scale = Vector2(0.084, 0.084)
	sprite.position = Vector2(0, -31)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO; return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * 185.0
	if direction.length() > 0.1:
		facing = direction; step_time += delta * 10.0
		sprite.flip_h = direction.x < -0.05
	else: step_time = lerpf(step_time, 0.0, delta * 4.0)
	sprite.position.y = -31.0 + sin(step_time) * 1.5 if velocity.length() > 0 else -31.0
	move_and_slide()
	position.x = clampf(position.x, 40.0, 1112.0)
	position.y = clampf(position.y, 195.0, 608.0)
	queue_redraw()

func _draw() -> void:
	# Soft painted shadow.
	fill_ellipse(Vector2(0, 18), Vector2(18, 7), Color(0.08,0.11,0.08,0.35))

func fill_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle)*radius.x, sin(angle)*radius.y))
	draw_colored_polygon(points, color)
