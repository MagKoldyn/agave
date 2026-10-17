extends CharacterBody2D

signal footstep(at: Vector2)

var can_move := true
var facing := Vector2.DOWN
var step_time := 0.0
var sprite: Sprite2D
var action_lock := false
var footstep_clock := 0.0
const BASE_SCALE := 0.084

func _ready() -> void:
	z_index = 8
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/art/player_idle.png")
	sprite.scale = Vector2(BASE_SCALE, BASE_SCALE)
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
		footstep_clock += delta
		if footstep_clock >= .24:
			footstep_clock = 0.0; footstep.emit(position + Vector2(0,18))
	else: step_time = lerpf(step_time, 0.0, delta * 4.0)
	if not action_lock:
		if velocity.length() > 0:
			sprite.position.y = -31.0 + sin(step_time) * 2.2
			sprite.rotation = sin(step_time*.5)*.018
			sprite.scale = Vector2(BASE_SCALE*(1.0+abs(sin(step_time))*.025),BASE_SCALE*(1.0-abs(sin(step_time))*.018))
		else:
			var breath:=sin(Time.get_ticks_msec()*.0024)
			sprite.position.y=-31.0+breath*.65;sprite.rotation=breath*.004;sprite.scale=Vector2(BASE_SCALE*(1.0-breath*.006),BASE_SCALE*(1.0+breath*.009))
	move_and_slide()
	position.x = clampf(position.x, 40.0, 1112.0)
	position.y = clampf(position.y, 195.0, 608.0)
	queue_redraw()

func play_action(kind: String) -> void:
	action_lock=true;can_move=false
	var start_position:=Vector2(0,-31);var windup:=create_tween().set_parallel(true)
	var lean := -.11 if not sprite.flip_h else .11
	windup.tween_property(sprite,"rotation",lean,.16).set_trans(Tween.TRANS_BACK)
	windup.tween_property(sprite,"position",start_position+Vector2(-4 if not sprite.flip_h else 4,-4),.16)
	windup.tween_property(sprite,"scale",Vector2(BASE_SCALE*.96,BASE_SCALE*1.06),.16)
	await windup.finished
	var strike:=create_tween().set_parallel(true)
	strike.tween_property(sprite,"rotation",-lean*.55,.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	strike.tween_property(sprite,"position",start_position+Vector2(3 if not sprite.flip_h else -3,3),.13)
	strike.tween_property(sprite,"scale",Vector2(BASE_SCALE*1.06,BASE_SCALE*.94),.13)
	await strike.finished
	var settle:=create_tween().set_parallel(true)
	settle.tween_property(sprite,"rotation",0.0,.22).set_trans(Tween.TRANS_ELASTIC)
	settle.tween_property(sprite,"position",start_position,.22)
	settle.tween_property(sprite,"scale",Vector2(BASE_SCALE,BASE_SCALE),.22)
	await settle.finished
	action_lock=false;can_move=true

func celebrate() -> void:
	action_lock=true
	var tween:=create_tween();tween.tween_property(sprite,"position:y",-45.0,.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(sprite,"position:y",-31.0,.28).set_trans(Tween.TRANS_BOUNCE);await tween.finished
	action_lock=false

func _draw() -> void:
	# Soft painted shadow.
	fill_ellipse(Vector2(0, 18), Vector2(18, 7), Color(0.08,0.11,0.08,0.35))

func fill_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle)*radius.x, sin(angle)*radius.y))
	draw_colored_polygon(points, color)
